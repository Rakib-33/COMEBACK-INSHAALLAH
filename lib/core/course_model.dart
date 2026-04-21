import 'dart:convert';

import 'grade_system.dart';

class CourseModel {
  CourseModel({
    required this.id,
    required this.code,
    required this.name,
    required this.credits,
    required this.incourseMarks,
    this.targetGrade,
    this.predictedGrade,
    this.detailUrl,
    this.semesterLabel = '',
    required this.syncedAt,
    this.assessmentRowsJson,
  });

  final String id;
  final String code;
  final String name;
  final double credits;
  final double incourseMarks;
  final String? targetGrade;
  final String? predictedGrade;
  final String? detailUrl;
  final String semesterLabel;
  final int syncedAt;

  /// JSON-encoded list of [AssessmentRow] maps; null if marks never synced.
  final String? assessmentRowsJson;

  double get maxIncourse => maxIncourseMarks(credits);
  bool get isTheory => isTheoryCourseCode(code);

  /// True when we have scraped individual assessment rows.
  bool get hasAssessmentData => assessmentRowsJson != null && assessmentRowsJson!.isNotEmpty;

  /// Decoded rows; empty list if none.
  List<Map<String, dynamic>> get assessmentRows {
    if (!hasAssessmentData) return [];
    try {
      final list = jsonDecode(assessmentRowsJson!) as List;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  CourseModel copyWith({
    String? id,
    String? code,
    String? name,
    double? credits,
    double? incourseMarks,
    String? targetGrade,
    String? predictedGrade,
    String? detailUrl,
    String? semesterLabel,
    int? syncedAt,
    String? assessmentRowsJson,
    bool clearTargetGrade = false,
    bool clearPredictedGrade = false,
    bool clearDetailUrl = false,
    bool clearAssessmentRows = false,
  }) {
    return CourseModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      credits: credits ?? this.credits,
      incourseMarks: incourseMarks ?? this.incourseMarks,
      targetGrade: clearTargetGrade ? null : (targetGrade ?? this.targetGrade),
      predictedGrade: clearPredictedGrade ? null : (predictedGrade ?? this.predictedGrade),
      detailUrl: clearDetailUrl ? null : (detailUrl ?? this.detailUrl),
      semesterLabel: semesterLabel ?? this.semesterLabel,
      syncedAt: syncedAt ?? this.syncedAt,
      assessmentRowsJson:
          clearAssessmentRows ? null : (assessmentRowsJson ?? this.assessmentRowsJson),
    );
  }

  Map<String, Object?> toRow() => {
        'id': id,
        'code': code,
        'name': name,
        'credits': credits,
        'incourse_marks': incourseMarks,
        'target_grade': targetGrade,
        'predicted_grade': predictedGrade,
        'detail_url': detailUrl,
        'semester_label': semesterLabel,
        'synced_at': syncedAt,
        'assessment_rows': assessmentRowsJson,
      };

  static CourseModel fromRow(Map<String, Object?> m) {
    return CourseModel(
      id: m['id']! as String,
      code: m['code']! as String,
      name: m['name']! as String,
      credits: (m['credits'] as num).toDouble(),
      incourseMarks: (m['incourse_marks'] as num).toDouble(),
      targetGrade: m['target_grade'] as String?,
      predictedGrade: m['predicted_grade'] as String?,
      detailUrl: m['detail_url'] as String?,
      semesterLabel: (m['semester_label'] as String?) ?? '',
      syncedAt: (m['synced_at'] as int?) ?? 0,
      assessmentRowsJson: m['assessment_rows'] as String?,
    );
  }
}
