import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '../core/calculator_engine.dart';
import '../core/course_model.dart';
import '../core/grade_system.dart';
import '../data/course_database.dart';

class AppController extends GetxController {
  final courses = <CourseModel>[].obs;
  final semesterLabel = 'Running Semester'.obs;
  final isLoadingDb = true.obs;

  int get totalImportedCourses => courses.length;
  int get syncedCourseCount => courses
      .where((course) => !course.isTheory || course.hasAssessmentData)
      .length;
  bool get allMarksSynced =>
      totalImportedCourses > 0 && syncedCourseCount >= totalImportedCourses;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    isLoadingDb.value = true;
    final list = await CourseDatabase.instance.allCourses();
    courses.assignAll(list);
    if (list.isNotEmpty) {
      semesterLabel.value = list.first.semesterLabel.isNotEmpty
          ? list.first.semesterLabel
          : semesterLabel.value;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (Get.currentRoute == '/') {
          Get.offNamed('/dashboard');
        }
      });
    }
    isLoadingDb.value = false;
  }

  Future<void> applySyncResult({
    required List<CourseModel> synced,
    String semester = 'Running Semester',
  }) async {
    semesterLabel.value = semester;
    final previousByCode = {
      for (final course in courses) course.code.toUpperCase(): course,
    };

    final merged = synced.map((course) {
      final previous = previousByCode[course.code.toUpperCase()];
      if (previous == null) return course;
      return course.copyWith(
        targetGrade: previous.targetGrade,
        predictedGrade: previous.predictedGrade,
      );
    }).toList();

    await CourseDatabase.instance.replaceAll(merged);
    courses.assignAll(merged);
  }

  /// Update incourse marks for a single course from scraped [AssessmentRow] list.
  ///
  /// Phase 3 calculation:
  /// - Theory  → CT-top-2 × 1.5 + Mid Term + Class Performance + Attendance
  /// - Sessional → simple sum of all rows
  Future<void> syncCourseMarks(
    String courseId,
    List<AssessmentRow> rows,
  ) async {
    final idx = courses.indexWhere((c) => c.id == courseId);
    if (idx < 0) return;

    final course = courses[idx];
    final calculatedMarks = course.isTheory
        ? IncourseCalculator.calcTheory(rows, credits: course.credits)
        : IncourseCalculator.calcSessional(rows);

    final rowsJson = AssessmentRow.listToJson(rows);
    final updated = course.copyWith(
      incourseMarks: calculatedMarks,
      assessmentRowsJson: rowsJson,
      syncedAt: DateTime.now().millisecondsSinceEpoch,
    );

    courses[idx] = updated;
    await CourseDatabase.instance.upsert(updated);
  }

  Future<void> updatePredictedGrade(String id, String grade) async {
    final idx = courses.indexWhere((c) => c.id == id);
    if (idx < 0) return;
    final next = courses[idx].copyWith(predictedGrade: grade);
    courses[idx] = next;
    await CourseDatabase.instance.upsert(next);
  }

  Future<void> updateTargetGrade(String id, String grade) async {
    final idx = courses.indexWhere((c) => c.id == id);
    if (idx < 0) return;
    final next = courses[idx].copyWith(targetGrade: grade);
    courses[idx] = next;
    await CourseDatabase.instance.upsert(next);
  }

  double predictedTermCgpa() {
    if (courses.isEmpty) return 0;
    var points = 0.0;
    var cred = 0.0;
    for (final c in courses) {
      final g = c.isTheory ? (c.targetGrade ?? 'A') : (c.predictedGrade ?? 'A');
      points += gpaForGrade(g) * c.credits;
      cred += c.credits;
    }
    if (cred == 0) return 0;
    return points / cred;
  }

  Future<void> logout() async {
    await CourseDatabase.instance.deleteAll();
    courses.clear();
    semesterLabel.value = 'Running Semester';
    Get.offAllNamed('/');
  }
}
