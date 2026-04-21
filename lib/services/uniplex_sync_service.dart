import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/calculator_engine.dart';
import '../core/course_model.dart';
import '../core/grade_system.dart';
import 'http_client_factory.dart';

class UniplexSyncException implements Exception {
  const UniplexSyncException(this.message);

  final String message;

  @override
  String toString() => message;
}

class UniplexSyncPayload {
  const UniplexSyncPayload({
    required this.semesterLabel,
    required this.courses,
    required this.fullMarksSynced,
    required this.unsyncedTheoryCodes,
  });

  final String semesterLabel;
  final List<CourseModel> courses;
  final bool fullMarksSynced;
  final List<String> unsyncedTheoryCodes;
}

class _AuthSession {
  const _AuthSession({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}

class _SemesterInfo {
  const _SemesterInfo({
    required this.id,
    required this.label,
    this.isCurrent = false,
  });

  final String id;
  final String label;
  final bool isCurrent;
}

class _CourseSeed {
  const _CourseSeed({
    required this.code,
    required this.name,
    required this.credits,
    required this.runningCourseId,
    required this.semesterLabel,
  });

  final String code;
  final String name;
  final double credits;
  final String runningCourseId;
  final String semesterLabel;
}

class UniplexSyncService {
  static const String _apiBase = 'https://api-uniplex.mist.ac.bd';
  static const String _loginPath = 'authenticate/student-portal/student';
  static const String _semesterListPath =
      'student-portal/student-semester-list';
  static const String _currentSemesterCoursesPath =
      'student-portal/student-semester-course-details';
  static const String _runningCoursesPath =
      'student-portal/registered-course-list-by-running-semester';
  static const String _assessmentPath =
      'student-portal/class-assessment-by-running-course-id';
  static const String _resultHistoryPath =
      'student-portal/student/result-history';
  static const String _allCourseDetailsPath =
      'student-portal/student-all-course-details';

  final http.Client _client;

  UniplexSyncService({http.Client? client})
    : _client = client ?? createPlatformHttpClient();

  Future<UniplexSyncPayload> sync({
    required String studentId,
    required String password,
  }) async {
    final trimmedId = studentId.trim();
    if (trimmedId.isEmpty || password.isEmpty) {
      throw const UniplexSyncException(
        'Student ID and password are both required.',
      );
    }

    final session = await _login(trimmedId, password);
    final semesters = await _fetchSemesters(session.accessToken);
    final seeds = await _fetchCourseSeeds(
      accessToken: session.accessToken,
      semesters: semesters,
    );

    if (seeds.isEmpty) {
      throw const UniplexSyncException(
        'No courses were returned from Uniplex for this account.',
      );
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final unsyncedTheoryCodes = <String>[];
    final courses = <CourseModel>[];

    for (final seed in seeds) {
      final rows = seed.runningCourseId.isEmpty
          ? const <AssessmentRow>[]
          : await _fetchAssessmentRows(
              accessToken: session.accessToken,
              runningCourseId: seed.runningCourseId,
            );

      final hasTheoryMarks = !isTheoryCourseCode(seed.code) || rows.isNotEmpty;
      if (!hasTheoryMarks && isTheoryCourseCode(seed.code)) {
        unsyncedTheoryCodes.add(seed.code);
      }

      final incourseMarks = isTheoryCourseCode(seed.code)
          ? IncourseCalculator.calcTheory(rows, credits: seed.credits)
          : IncourseCalculator.calcSessional(rows);

      courses.add(
        CourseModel(
          id: seed.runningCourseId.isNotEmpty
              ? seed.runningCourseId
              : '${seed.code}_${seed.semesterLabel}',
          code: seed.code,
          name: seed.name,
          credits: seed.credits,
          incourseMarks: incourseMarks,
          semesterLabel: seed.semesterLabel,
          syncedAt: now,
          assessmentRowsJson: rows.isEmpty
              ? null
              : AssessmentRow.listToJson(rows),
        ),
      );
    }

    final semesterLabel = seeds.first.semesterLabel.isNotEmpty
        ? seeds.first.semesterLabel
        : _bestSemesterLabel(semesters);

    return UniplexSyncPayload(
      semesterLabel: semesterLabel,
      courses: courses,
      fullMarksSynced: unsyncedTheoryCodes.isEmpty,
      unsyncedTheoryCodes: unsyncedTheoryCodes,
    );
  }

  Future<_AuthSession> _login(String studentId, String password) async {
    final response = await _client.post(
      _uri(_loginPath),
      headers: _jsonHeaders(),
      body: jsonEncode({'username': studentId, 'password': password}),
    );

    final body = _decodeJson(response);
    final data = _extractDataMap(body);

    final accessToken = data['accessToken']?.toString() ?? '';
    final refreshToken = data['refreshToken']?.toString() ?? '';

    if (response.statusCode >= 400 || accessToken.isEmpty) {
      final message =
          _extractMessage(body) ??
          'Uniplex login failed. Check the student ID and password.';
      throw UniplexSyncException(message);
    }

    return _AuthSession(accessToken: accessToken, refreshToken: refreshToken);
  }

  Future<List<_SemesterInfo>> _fetchSemesters(String accessToken) async {
    final response = await _client.get(
      _uri(_semesterListPath),
      headers: _authHeaders(accessToken),
    );

    if (response.statusCode >= 400) {
      return const <_SemesterInfo>[];
    }

    final body = _decodeJson(response);
    final maps = _extractMapList(body);
    final semesters = <_SemesterInfo>[];

    for (final item in maps) {
      final id = _firstString(item, const [
        'semesterId',
        'runningSemesterId',
        'id',
        'value',
      ]);
      final label = _firstString(item, const [
        'semesterName',
        'semesterLabel',
        'name',
        'label',
        'title',
      ]);
      if (id.isEmpty && label.isEmpty) continue;

      final isCurrent = _firstBool(item, const [
        'isCurrent',
        'current',
        'isRunning',
        'running',
        'selected',
      ]);

      semesters.add(
        _SemesterInfo(
          id: id,
          label: label.isNotEmpty ? label : 'Running Semester',
          isCurrent: isCurrent,
        ),
      );
    }

    return semesters;
  }

  Future<List<_CourseSeed>> _fetchCourseSeeds({
    required String accessToken,
    required List<_SemesterInfo> semesters,
  }) async {
    final currentResponse = await _client.get(
      _uri(_currentSemesterCoursesPath),
      headers: _authHeaders(accessToken),
    );

    final currentSeeds = _parseCourseSeedsFromBody(
      currentResponse.statusCode < 400 ? _decodeJson(currentResponse) : null,
      fallbackSemesterLabel: _bestSemesterLabel(semesters),
    );
    if (currentSeeds.isNotEmpty) {
      return currentSeeds;
    }

    for (final semester in _rankSemesters(semesters)) {
      if (semester.id.isEmpty) continue;
      final response = await _client.get(
        _uri(
          _runningCoursesPath,
          queryParameters: {
            'semesterId': semester.id,
            'runningSemesterId': semester.id,
          },
        ),
        headers: _authHeaders(accessToken),
      );

      final seeds = _parseCourseSeedsFromBody(
        response.statusCode < 400 ? _decodeJson(response) : null,
        fallbackSemesterLabel: semester.label,
      );
      if (seeds.isNotEmpty) {
        return seeds;
      }
    }

    final allCourseResponse = await _client.get(
      _uri(_allCourseDetailsPath),
      headers: _authHeaders(accessToken),
    );
    final fromAllCourses = _parseCourseSeedsFromBody(
      allCourseResponse.statusCode < 400
          ? _decodeJson(allCourseResponse)
          : null,
      fallbackSemesterLabel: _bestSemesterLabel(semesters),
    );
    if (fromAllCourses.isNotEmpty) {
      return fromAllCourses;
    }

    final resultHistoryResponse = await _client.get(
      _uri(_resultHistoryPath, queryParameters: const {'semesterId': 'all'}),
      headers: _authHeaders(accessToken),
    );
    return _parseCourseSeedsFromBody(
      resultHistoryResponse.statusCode < 400
          ? _decodeJson(resultHistoryResponse)
          : null,
      fallbackSemesterLabel: _bestSemesterLabel(semesters),
    );
  }

  Future<List<AssessmentRow>> _fetchAssessmentRows({
    required String accessToken,
    required String runningCourseId,
  }) async {
    final response = await _client.get(
      _uri(
        _assessmentPath,
        queryParameters: {'runningCourseId': runningCourseId},
      ),
      headers: _authHeaders(accessToken),
    );

    if (response.statusCode >= 400) {
      return const <AssessmentRow>[];
    }

    final body = _decodeJson(response);
    final maps = _extractMapList(body);
    final rows = <AssessmentRow>[];

    for (final item in maps) {
      final name = _firstString(item, const [
        'assessmentName',
        'name',
        'title',
        'obeName',
      ]);
      if (name.isEmpty) continue;

      final score = _firstDouble(item, const [
        'earnedMarks',
        'obtainedMarks',
        'score',
        'marks',
      ]);

      if (_looksLikeAssessmentRow(name)) {
        rows.add(
          AssessmentRow(name: _normalizeAssessmentName(name), score: score),
        );
      }
    }

    final deduped = <String, AssessmentRow>{};
    for (final row in rows) {
      deduped[row.name.toUpperCase()] = row;
    }
    return deduped.values.toList();
  }

  List<_CourseSeed> _parseCourseSeedsFromBody(
    dynamic body, {
    required String fallbackSemesterLabel,
  }) {
    if (body == null) return const <_CourseSeed>[];
    final maps = _extractMapList(body);
    final byCode = <String, _CourseSeed>{};

    for (final item in maps) {
      final code = _normalizeCourseCode(
        _firstString(item, const [
          'courseCode',
          'code',
          'subjectCode',
          'course',
        ]),
      );
      if (code.isEmpty) continue;

      final name = _firstString(item, const [
        'courseTitle',
        'courseName',
        'name',
        'title',
        'subjectName',
      ]);
      final credits = _firstDouble(item, const [
        'courseCredit',
        'credit',
        'credits',
        'totalCredit',
      ]);
      final runningCourseId = _firstString(item, const [
        'runningCourseId',
        'courseId',
        'id',
      ]);
      final semesterLabel = _firstString(item, const [
        'semesterName',
        'semesterLabel',
        'runningSemesterName',
      ]);

      final resolvedCredits = credits > 0
          ? credits
          : (isTheoryCourseCode(code) ? 3.0 : 1.5);

      byCode[code] = _CourseSeed(
        code: code,
        name: name.isNotEmpty ? name : code,
        credits: resolvedCredits,
        runningCourseId: runningCourseId,
        semesterLabel: semesterLabel.isNotEmpty
            ? semesterLabel
            : fallbackSemesterLabel,
      );
    }

    final list = byCode.values.toList()
      ..sort((a, b) => a.code.compareTo(b.code));
    return list;
  }

  Uri _uri(String path, {Map<String, String>? queryParameters}) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse(
      '$_apiBase$normalizedPath',
    ).replace(queryParameters: queryParameters);
  }

  Map<String, String> _jsonHeaders() => const {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Origin': 'https://student.mist.ac.bd',
    'Referer': 'https://student.mist.ac.bd/',
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/123.0.0.0 Mobile Safari/537.36',
  };

  Map<String, String> _authHeaders(String accessToken) => {
    ..._jsonHeaders(),
    'Authorization': 'Bearer $accessToken',
  };

  dynamic _decodeJson(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _extractDataMap(dynamic body) {
    if (body is Map<String, dynamic>) {
      final data = body['data'];
      if (data is Map<String, dynamic>) return data;
      return body;
    }
    return const <String, dynamic>{};
  }

  String? _extractMessage(dynamic body) {
    if (body is Map<String, dynamic>) {
      final direct = body['message']?.toString();
      if (direct != null && direct.trim().isNotEmpty) {
        return direct.trim();
      }

      final data = body['data'];
      if (data is Map<String, dynamic>) {
        final nested = data['message']?.toString();
        if (nested != null && nested.trim().isNotEmpty) {
          return nested.trim();
        }
      }
    }
    return null;
  }

  List<Map<String, dynamic>> _extractMapList(dynamic root) {
    final results = <Map<String, dynamic>>[];
    final visited = <Object>{};

    void walk(dynamic value) {
      if (value == null) return;
      if (value is Map) {
        if (visited.contains(value)) return;
        visited.add(value);

        final map = Map<String, dynamic>.from(value);
        if (map.isNotEmpty) {
          results.add(map);
        }
        for (final nested in map.values) {
          walk(nested);
        }
      } else if (value is List) {
        for (final item in value) {
          walk(item);
        }
      }
    }

    walk(root);
    return results;
  }

  String _firstString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return '';
  }

  bool _firstBool(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
          return true;
        }
      }
    }
    return false;
  }

  double _firstDouble(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value.trim());
        if (parsed != null) return parsed;
      }
    }
    return 0.0;
  }

  String _normalizeCourseCode(String raw) {
    final cleaned = raw.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
    if (cleaned.isEmpty) return '';

    final match = RegExp(r'^([A-Z]{2,4})-?(\d{3})$').firstMatch(cleaned);
    if (match == null) return cleaned;
    return '${match.group(1)}-${match.group(2)}';
  }

  bool _looksLikeAssessmentRow(String name) {
    final normalized = name.toUpperCase();
    return normalized.startsWith('CT') ||
        normalized.contains('MID') ||
        normalized.contains('PERFORMANCE') ||
        normalized.contains('ATTENDANCE');
  }

  String _normalizeAssessmentName(String raw) {
    final normalized = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    final upper = normalized.toUpperCase();
    if (upper.startsWith('CT')) {
      return upper.replaceAll(' ', '');
    }
    return normalized;
  }

  Iterable<_SemesterInfo> _rankSemesters(List<_SemesterInfo> semesters) sync* {
    final current = semesters.where((semester) => semester.isCurrent);
    final others = semesters.where((semester) => !semester.isCurrent);
    yield* current;
    yield* others;
  }

  String _bestSemesterLabel(List<_SemesterInfo> semesters) {
    if (semesters.isEmpty) return 'Running Semester';
    final current = semesters.firstWhere(
      (semester) => semester.isCurrent,
      orElse: () => semesters.first,
    );
    return current.label.isNotEmpty ? current.label : 'Running Semester';
  }
}
