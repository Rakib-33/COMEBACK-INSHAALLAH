import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../app_theme.dart';
import '../controllers/app_controller.dart';
import '../services/uniplex_sync_service.dart';
import 'uniplex_webview_screen.dart';
import 'widgets/brand_logo.dart';
import 'widgets/glass_card.dart';
import 'widgets/neon_background.dart';

class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _loading = false.obs;
  final _obscurePassword = true.obs;
  final _statusMessage = RxnString();
  final _statusTitle = RxnString();
  final _statusIsWarning = false.obs;

  late final UniplexSyncService _syncService;
  final _portalFallbackReady = false.obs;

  @override
  void initState() {
    super.initState();
    _syncService = UniplexSyncService();
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _passwordController.dispose();
    _loading.close();
    _obscurePassword.close();
    _statusMessage.close();
    _statusTitle.close();
    _statusIsWarning.close();
    _portalFallbackReady.close();
    super.dispose();
  }

  Future<void> _secureSync() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ctl = Get.find<AppController>();
    _loading.value = true;
    _statusTitle.value = null;
    _statusMessage.value = null;
    _portalFallbackReady.value = false;

    try {
      final payload = await _syncService.sync(
        studentId: _studentIdController.text,
        password: _passwordController.text,
      );

      await ctl.applySyncResult(
        synced: payload.courses,
        semester: payload.semesterLabel,
      );

      final syncedCount =
          payload.courses.length - payload.unsyncedTheoryCodes.length;
      if (payload.fullMarksSynced) {
        _statusIsWarning.value = false;
        _statusTitle.value = 'Sync complete';
        _statusMessage.value =
            '${payload.courses.length} courses and available marks were imported successfully.';
      } else {
        _statusIsWarning.value = true;
        _statusTitle.value = 'Courses imported';
        _statusMessage.value =
            '${payload.courses.length} courses were imported. Marks synced for $syncedCount courses. Some theory courses still have no published assessment data in Uniplex.';
      }

      _passwordController.clear();
    } on UniplexSyncException catch (error) {
      _statusIsWarning.value = true;
      _statusTitle.value = 'Sync failed';
      _statusMessage.value = error.message;
      _portalFallbackReady.value = !kIsWeb;
    } catch (_) {
      _statusIsWarning.value = true;
      _statusTitle.value = 'Sync failed';
      _statusMessage.value =
          'Something went wrong while syncing from Uniplex. Please try again.';
      _portalFallbackReady.value = !kIsWeb;
    } finally {
      _loading.value = false;
    }
  }

  Future<void> _openPortalFallback() async {
    final studentId = _studentIdController.text.trim();
    final password = _passwordController.text;
    if (studentId.isEmpty || password.isEmpty) return;

    await Get.to<void>(
      () => UniplexWebViewScreen(studentId: studentId, password: password),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctl = Get.find<AppController>();

    return Scaffold(
      body: Container(
        decoration: AppTheme.pageBackground(),
        child: Stack(
          children: [
            const Positioned.fill(child: NeonBackgroundOrbs(durationSec: 10)),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      const BrandLogo(size: 136, radius: 28, padding: 6)
                          .animate()
                          .fadeIn(duration: 500.ms)
                          .scale(begin: const Offset(0.92, 0.92)),
                      const SizedBox(height: 20),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            AppColors.violet,
                            AppColors.cyan,
                            AppColors.violet,
                          ],
                        ).createShader(bounds),
                        blendMode: BlendMode.srcIn,
                        child: Text(
                          'COMEBACK INSHALLAH',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                        ),
                      ).animate().fadeIn(delay: 100.ms, duration: 500.ms),
                      const SizedBox(height: 8),
                      Text(
                        'Secure academic import from Uniplex',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.62),
                        ),
                      ).animate().fadeIn(delay: 180.ms, duration: 500.ms),
                      const SizedBox(height: 28),
                      GlassCard(
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.violet.withValues(
                                                alpha: 0.24,
                                              ),
                                              AppColors.cyan.withValues(
                                                alpha: 0.16,
                                              ),
                                            ],
                                          ),
                                          border: Border.all(
                                            color: AppColors.violet.withValues(
                                              alpha: 0.35,
                                            ),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.shield_outlined,
                                          color: AppColors.violet,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Uniplex Portal Sync',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Secure authentication required',
                                              style: TextStyle(
                                                color: Colors.white.withValues(
                                                  alpha: 0.56,
                                                ),
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 26),
                                  Text(
                                    'Student ID',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.86,
                                      ),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _studentIdController,
                                    textInputAction: TextInputAction.next,
                                    autofillHints: const [
                                      AutofillHints.username,
                                    ],
                                    decoration: const InputDecoration(
                                      hintText: 'Enter your student ID',
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Student ID is required';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Password',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.86,
                                      ),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Obx(
                                    () => TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword.value,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [
                                        AutofillHints.password,
                                      ],
                                      onFieldSubmitted: (_) => _secureSync(),
                                      decoration: InputDecoration(
                                        hintText: 'Enter your password',
                                        suffixIcon: IconButton(
                                          onPressed: () =>
                                              _obscurePassword.toggle(),
                                          icon: Icon(
                                            _obscurePassword.value
                                                ? Icons.lock_outline_rounded
                                                : Icons.lock_open_rounded,
                                            color: Colors.white.withValues(
                                              alpha: 0.50,
                                            ),
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Password is required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Obx(() {
                                    final busy = _loading.value;
                                    return _GradientCta(
                                      label: busy
                                          ? 'Syncing securely...'
                                          : 'Secure Sync',
                                      icon: busy ? null : Icons.shield_outlined,
                                      busy: busy,
                                      onTap: busy ? null : _secureSync,
                                    );
                                  }),
                                  const SizedBox(height: 14),
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.04,
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.08,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      'We send your credentials only to the official Uniplex login endpoint for this sync session. Your password is not stored in the app after import.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.66,
                                        ),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 280.ms, duration: 520.ms)
                          .moveY(begin: 10, end: 0),
                      const SizedBox(height: 14),
                      Obx(() {
                        final title = _statusTitle.value;
                        final message = _statusMessage.value;
                        if (title == null || message == null) {
                          return const SizedBox.shrink();
                        }

                        final warning = _statusIsWarning.value;
                        final accent = warning
                            ? const Color(0xFFF59E0B)
                            : const Color(0xFF22C55E);
                        return GlassCard(
                          padding: const EdgeInsets.all(18),
                          borderColor: accent.withValues(alpha: 0.28),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                warning
                                    ? Icons.info_outline_rounded
                                    : Icons.check_circle_outline_rounded,
                                color: accent,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.94,
                                        ),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      message,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.66,
                                        ),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      Obx(() {
                        if (!_portalFallbackReady.value) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _GradientCta(
                            label: 'Open portal sync',
                            icon: Icons.language_rounded,
                            onTap: _openPortalFallback,
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      Obx(() {
                        if (ctl.isLoadingDb.value) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: CircularProgressIndicator(
                              color: AppColors.cyan,
                            ),
                          );
                        }
                        if (ctl.courses.isNotEmpty) {
                          return TextButton(
                            onPressed: () => Get.offNamed('/dashboard'),
                            child: const Text(
                              'Continue to dashboard',
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),
                      const SizedBox(height: 10),
                      Text(
                        'Developed by Rakib Rony',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.38),
                          fontSize: 13,
                        ),
                      ).animate().fadeIn(delay: 520.ms),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientCta extends StatelessWidget {
  const _GradientCta({
    required this.label,
    required this.onTap,
    this.icon,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [AppColors.violet, AppColors.cyan],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(139, 92, 246, 0.34),
                blurRadius: 22,
                offset: Offset(0, 8),
              ),
              BoxShadow(
                color: Color.fromRGBO(6, 182, 212, 0.18),
                blurRadius: 28,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon ?? Icons.shield_outlined, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
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
