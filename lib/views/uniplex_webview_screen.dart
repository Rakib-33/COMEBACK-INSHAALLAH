import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';

import '../app_theme.dart';
import '../controllers/app_controller.dart';
import '../core/calculator_engine.dart';
import '../core/course_model.dart';
import '../core/grade_system.dart';
import '../core/uniplex_config.dart';
import '../core/uniplex_scripts.dart';
import '../routes/app_pages.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

enum _PageKind { login, runningCourses, assessments, other }

enum _BusyAction { none, importCourses, syncMarks, autoLogin }

/// Resolves the effective path segments from a URL, handling both normal paths
/// and Angular-style hash routing (e.g. https://host/#/running-course/43/4224/assessments).
List<String> _effectiveSegments(String? url) {
  if (url == null || url.isEmpty) return [];
  try {
    final uri = Uri.parse(url);
    // Prefer real path segments when non-trivial
    final pathSegs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (pathSegs.isNotEmpty && pathSegs[0] != '#') return pathSegs;

    // Fall back to fragment (hash routing): uri.fragment = "/running-course/43/4224/assessments"
    final frag = uri.fragment;
    return frag.split('/').where((s) => s.isNotEmpty).toList();
  } catch (_) {
    return [];
  }
}

_PageKind _detectPage(String? url) {
  final segs = _effectiveSegments(url);
  if (segs.isEmpty) return _PageKind.other;
  if (segs[0] == 'login') return _PageKind.login;
  if (segs[0] == 'running-course') {
    if (segs.last == 'assessments') return _PageKind.assessments;
    // e.g. /running-course or /running-course/43
    if (segs.length < 3) return _PageKind.runningCourses;
  }
  return _PageKind.other;
}

// Helpers removed, now using direct text parsing.

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class UniplexWebViewScreen extends StatefulWidget {
  const UniplexWebViewScreen({
    super.key,
    required this.studentId,
    required this.password,
  });

  final String studentId;
  final String password;

  @override
  State<UniplexWebViewScreen> createState() => _UniplexWebViewScreenState();
}

class _UniplexWebViewScreenState extends State<UniplexWebViewScreen> {
  InAppWebViewController? _web;
  final _busyAction = _BusyAction.none.obs;
  final _currentUrl = ''.obs;
  Timer? _assessmentTimer;
  Timer? _urlPoller;
  var _autoLoginAttempted = false;
  final Set<String> _processedSyncKeys = <String>{};
  String? _lastSnackSignature;

  bool get _hasSavedCredentials =>
      widget.studentId.trim().isNotEmpty && widget.password.isNotEmpty;

  bool get _isBusy => _busyAction.value != _BusyAction.none;

  // ── lifecycle ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _urlPoller?.cancel();
    _assessmentTimer?.cancel();
    super.dispose();
  }

  // ── URL helpers ────────────────────────────────────────────────────────────

  _PageKind get _pageKind => _detectPage(_currentUrl.value);

  // ── auto-login ─────────────────────────────────────────────────────────────

  Future<void> _runAutoLogin() async {
    final c = _web;
    if (c == null || !_hasSavedCredentials) return;
    _busyAction.value = _BusyAction.autoLogin;
    try {
      await c.evaluateJavascript(
        source: UniplexScripts.autoLogin(
          studentId: widget.studentId,
          password: widget.password,
        ),
      );
    } finally {
      _busyAction.value = _BusyAction.none;
    }
  }

  // ── JSON parse helper ──────────────────────────────────────────────────────

  Map<String, dynamic>? _parse(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    final s = raw.toString();
    if (s == 'null' || s.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(s) as Map);
    } catch (_) {
      return null;
    }
  }

  // ── Phase 1: Import Courses ────────────────────────────────────────────────

  Future<void> _importCourses() async {
    final c = _web;
    if (c == null) return;
    if (_pageKind != _PageKind.runningCourses) {
      _snack(
        'Open Running Courses',
        'Go to the Running Courses page first, then tap Import Courses.',
        duration: const Duration(seconds: 2),
      );
      return;
    }

    _busyAction.value = _BusyAction.importCourses;
    try {
      final raw = await c.evaluateJavascript(
        source: UniplexScripts.extractCourseStubs,
      );
      final m = _parse(raw);
      final list = (m?['courses'] as List?)?.cast<dynamic>() ?? const [];
      final stubs = list
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      if (stubs.isEmpty) {
        _snack(
          'Nothing detected',
          'Open Running Courses in the portal, then try again.',
          duration: const Duration(seconds: 2),
        );
        return;
      }

      final semester = await _semesterHint();
      final now = DateTime.now().millisecondsSinceEpoch;
      final models = <CourseModel>[];

      for (var i = 0; i < stubs.length; i++) {
        final s = stubs[i];
        final code = (s['code'] ?? '').toString();
        final name = (s['name'] ?? 'Course').toString();
        final href = (s['href'] ?? '').toString();
        final cred = (s['credits'] is num)
            ? (s['credits'] as num).toDouble()
            : double.tryParse('${s['credits']}') ?? 0;
        final credits = cred > 0
            ? cred
            : (isTheoryCourseCode(code) ? 3.0 : 1.5);

        models.add(
          CourseModel(
            id: '${code}_$i',
            code: code,
            name: name,
            credits: credits,
            incourseMarks: 0,
            detailUrl: href.isEmpty ? null : href,
            semesterLabel: semester,
            syncedAt: now,
          ),
        );
      }

      final ctl = Get.find<AppController>();
      await ctl.applySyncResult(synced: models, semester: semester);
      _processedSyncKeys.clear();

      _snack(
        'Courses imported',
        '${models.length} courses saved. Now open each course > Assessments and sync every mark.',
      );
    } catch (e) {
      _snack('Import failed', e.toString());
    } finally {
      _busyAction.value = _BusyAction.none;
    }
  }

  // ── Phase 2: Sync Marks ───────────────────────────────────────────────────

  void _scheduleAssessmentSync(String url) {
    _assessmentTimer?.cancel();
    _assessmentTimer = Timer(const Duration(seconds: 3), () async {
      if (!mounted) return;
      await _injectAssessmentScraper(url);
    });
  }

  Future<void> _injectAssessmentScraper(String url) async {
    final c = _web;
    if (c == null) return;
    try {
      final raw = await c.evaluateJavascript(
        source: UniplexScripts.extractAssessmentRows,
      );
      if (raw != null) {
        _handleSyncPayload(raw.toString(), url, fromFallback: true);
      }
    } catch (e) {
      debugPrint('[AssessmentSync] inject error: $e');
    }
  }

  /// Called by both the JS callHandler and the fallback evaluateJavascript return.
  void _handleSyncPayload(
    String payload,
    String assessmentUrl, {
    bool fromFallback = false,
  }) {
    try {
      final m = _parse(payload);
      if (m == null) return;
      final rowsRaw = (m['rows'] as List?)?.cast<dynamic>() ?? [];
      if (rowsRaw.isEmpty) return;

      final rows = rowsRaw
          .map(
            (e) => AssessmentRow.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();

      final courseCode = m['courseCode']?.toString();
      if (courseCode == null || courseCode.isEmpty) {
        debugPrint(
          '[AssessmentSync] Could not extract course code from page text.',
        );
        return;
      }

      final ctl = Get.find<AppController>();

      final idx = ctl.courses.indexWhere(
        (c) => c.code.toUpperCase() == courseCode.toUpperCase(),
      );
      if (idx < 0) {
        debugPrint(
          '[AssessmentSync] No imported course matched code: $courseCode',
        );
        return;
      }
      final course = ctl.courses[idx];
      final syncKey =
          '${course.code}|${rows.map((row) => '${row.name}:${row.score}').join(',')}';
      if (_processedSyncKeys.contains(syncKey)) {
        return;
      }

      _processedSyncKeys.add(syncKey);
      ctl
          .syncCourseMarks(course.id, rows)
          .then((_) {
            _snack(
              'Marks synced',
              '${course.name} synced successfully. Progress: ${ctl.syncedCourseCount}/${ctl.totalImportedCourses}.',
            );
          })
          .catchError((Object error) {
            _processedSyncKeys.remove(syncKey);
            _snack(
              'Sync failed',
              error.toString(),
              duration: const Duration(seconds: 2),
            );
          })
          .whenComplete(() {
            if (_busyAction.value == _BusyAction.syncMarks) {
              _busyAction.value = _BusyAction.none;
            }
          });
    } catch (e) {
      debugPrint('[AssessmentSync] parse error: $e');
    }
  }

  // ── Manual sync button on assessment page ──────────────────────────────────

  Future<void> _manualSyncMarks() async {
    final c = _web;
    if (c == null) return;
    if (_pageKind != _PageKind.assessments) {
      _snack(
        'Open Assessments',
        'Open the Assessment Page of any Theory Course, then tap Sync Marks.',
        duration: const Duration(seconds: 2),
      );
      return;
    }

    _busyAction.value = _BusyAction.syncMarks;
    try {
      final raw = await c.evaluateJavascript(
        source: UniplexScripts.extractAssessmentRows,
      );
      if (raw != null) {
        _handleSyncPayload(raw.toString(), _currentUrl.value);
      }
    } catch (e) {
      _snack('Sync failed', e.toString(), duration: const Duration(seconds: 2));
    } finally {
      if (_busyAction.value == _BusyAction.syncMarks) {
        _busyAction.value = _BusyAction.none;
      }
    }
  }

  // ── Semester hint ──────────────────────────────────────────────────────────

  Future<String> _semesterHint() async {
    final c = _web;
    if (c == null) return 'Running Semester';
    final raw = await c.evaluateJavascript(
      source: UniplexScripts.extractSemesterHint,
    );
    final m = _parse(raw);
    final label = m?['label']?.toString() ?? '';
    return label.isNotEmpty ? label : 'Running Semester';
  }

  // ── URL change handler (shared by onLoadStop + onUpdateVisitedHistory) ────

  void _onUrlChanged(String urlStr) {
    if (urlStr == _currentUrl.value) return;
    _currentUrl.value = urlStr;
    _assessmentTimer?.cancel();

    if (_detectPage(urlStr) == _PageKind.assessments) {
      _scheduleAssessmentSync(urlStr);
    }
  }

  // ── Snackbar helper ────────────────────────────────────────────────────────

  void _snack(
    String title,
    String msg, {
    Duration duration = const Duration(seconds: 4),
  }) {
    final signature = '$title|$msg';
    if (_lastSnackSignature == signature) {
      return;
    }
    _lastSnackSignature = signature;

    Get.snackbar(
      title,
      msg,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black87,
      colorText: Colors.white,
      duration: duration,
    );

    Timer(duration + const Duration(milliseconds: 250), () {
      if (_lastSnackSignature == signature) {
        _lastSnackSignature = null;
      }
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgTop,
      appBar: AppBar(
        title: Obx(() {
          final kind = _pageKind;
          final kindStr = kind == _PageKind.runningCourses
              ? 'Running Courses'
              : kind == _PageKind.assessments
              ? 'Assessments'
              : 'Uniplex Portal';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(kindStr, style: const TextStyle(fontSize: 16)),
              Text(
                _currentUrl.value,
                style: const TextStyle(fontSize: 10, color: Colors.white70),
              ),
            ],
          );
        }),
        backgroundColor: Colors.black.withValues(alpha: 0.35),
        foregroundColor: Colors.white,
        actions: [
          if (_hasSavedCredentials)
            Obx(
              () => TextButton(
                onPressed: _isBusy ? null : _runAutoLogin,
                child: const Text(
                  'Auto login',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(kUniplexBaseUrl)),
                  initialSettings: InAppWebViewSettings(
                    javaScriptEnabled: true,
                    domStorageEnabled: true,
                    useHybridComposition: true,
                    allowsInlineMediaPlayback: true,
                    mediaPlaybackRequiresUserGesture: false,
                    transparentBackground: true,
                  ),
                  onWebViewCreated: (controller) {
                    _web = controller;

                    // Start URL poller (crucial for Flutter Web SPA tracking)
                    _urlPoller?.cancel();
                    _urlPoller = Timer.periodic(const Duration(seconds: 1), (
                      _,
                    ) async {
                      if (!mounted) return;
                      try {
                        final rawUrl = await controller.evaluateJavascript(
                          source: 'window.location.href',
                        );
                        final String newUrl = (rawUrl ?? '')
                            .toString()
                            .replaceAll('"', '')
                            .trim();
                        if (newUrl.isNotEmpty &&
                            newUrl != _currentUrl.value &&
                            newUrl != 'null') {
                          _onUrlChanged(newUrl);
                        }
                      } catch (_) {}
                    });

                    // Register JS → Flutter bridge
                    controller.addJavaScriptHandler(
                      handlerName: 'syncMarks',
                      callback: (args) {
                        if (args.isEmpty) return;
                        final payload = args[0] is String
                            ? args[0] as String
                            : jsonEncode(args[0]);
                        _handleSyncPayload(payload, _currentUrl.value);
                      },
                    );
                  },
                  onLoadStop: (controller, url) async {
                    final urlStr = url?.toString() ?? '';
                    _onUrlChanged(urlStr);

                    if (!_autoLoginAttempted) {
                      _autoLoginAttempted = true;
                      if (_hasSavedCredentials) {
                        await Future<void>.delayed(
                          const Duration(milliseconds: 500),
                        );
                        await _runAutoLogin();
                      }
                    }
                  },
                  // ✅ KEY FIX: catches Angular/SPA pushState navigation
                  // (e.g. clicking "Assessments" tab inside a course)
                  onUpdateVisitedHistory: (controller, url, androidIsReload) {
                    final urlStr = url?.toString() ?? '';
                    _onUrlChanged(urlStr);
                  },
                  // ✅ KEY FIX: Handle SSL certificate errors (common on university portals)
                  onReceivedServerTrustAuthRequest:
                      (controller, challenge) async {
                        return ServerTrustAuthResponse(
                          action: ServerTrustAuthResponseAction.PROCEED,
                        );
                      },
                  onReceivedError: (controller, request, error) {
                    debugPrint('[WebView Error] ${error.description}');
                  },
                  onReceivedHttpError: (controller, request, errorResponse) {
                    debugPrint(
                      '[WebView HTTP Error] ${errorResponse.statusCode}',
                    );
                  },
                ),
                // Loading overlay
                Obx(() {
                  if (!_isBusy) return const SizedBox.shrink();
                  return const ColoredBox(
                    color: Color.fromRGBO(0, 0, 0, 0.22),
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.cyan),
                    ),
                  );
                }),
              ],
            ),
          ),
          // ── Bottom action panel ─────────────────────────────────────────────
          Obx(
            () => _BottomPanel(
              importBusy: _busyAction.value == _BusyAction.importCourses,
              syncBusy: _busyAction.value == _BusyAction.syncMarks,
              totalImported: Get.find<AppController>().totalImportedCourses,
              syncedCount: Get.find<AppController>().syncedCourseCount,
              canGoToApp: Get.find<AppController>().allMarksSynced,
              onImportCourses: _importCourses,
              onSyncMarks: _manualSyncMarks,
              onGoToApp: () {
                Get.offAllNamed(AppRoutes.dashboard);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.importBusy,
    required this.syncBusy,
    required this.totalImported,
    required this.syncedCount,
    required this.canGoToApp,
    required this.onImportCourses,
    required this.onSyncMarks,
    required this.onGoToApp,
  });

  final bool importBusy;
  final bool syncBusy;
  final int totalImported;
  final int syncedCount;
  final bool canGoToApp;
  final VoidCallback onImportCourses;
  final VoidCallback onSyncMarks;
  final VoidCallback onGoToApp;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      color: Colors.black.withValues(alpha: 0.88),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'Import Courses',
                      icon: Icons.download_rounded,
                      busy: importBusy,
                      onTap: onImportCourses,
                      color1: AppColors.violet,
                      color2: AppColors.cyan,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ActionButton(
                      label: 'Sync Marks $syncedCount/$totalImported',
                      icon: Icons.sync_rounded,
                      busy: syncBusy,
                      onTap: onSyncMarks,
                      color1: AppColors.cyan,
                      color2: AppColors.violet,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _GoToAppButton(onTap: onGoToApp, enabled: canGoToApp),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.busy,
    required this.onTap,
    required this.color1,
    required this.color2,
  });

  final String label;
  final IconData icon;
  final bool busy;
  final VoidCallback onTap;
  final Color color1;
  final Color color2;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: busy ? null : onTap,
        child: Ink(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: busy
                  ? [Colors.grey.shade800, Colors.grey.shade700]
                  : [color1, color2],
            ),
            boxShadow: busy
                ? []
                : [
                    BoxShadow(
                      color: color1.withValues(alpha: 0.35),
                      blurRadius: 12,
                    ),
                  ],
          ),
          child: Center(
            child: busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.white, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Go to App button ───────────────────────────────────────────────────────

class _GoToAppButton extends StatelessWidget {
  const _GoToAppButton({required this.onTap, required this.enabled});

  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: enabled ? onTap : null,
        child: Ink(
          height: 46,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: enabled
                ? const LinearGradient(
                    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                  )
                : null,
            color: enabled ? null : Colors.white.withValues(alpha: 0.08),
            border: Border.all(
              color: enabled
                  ? const Color(0xFF22C55E)
                  : Colors.white.withValues(alpha: 0.18),
              width: 1.4,
            ),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.45),
                      blurRadius: 18,
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                enabled
                    ? Icons.check_circle_outline
                    : Icons.lock_outline_rounded,
                color: enabled ? Colors.white : Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                enabled ? 'Go to App' : 'Sync all marks to continue',
                style: TextStyle(
                  color: enabled ? Colors.white : Colors.white70,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
