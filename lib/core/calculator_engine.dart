import 'dart:convert';

/// A single scraped assessment row from the Uniplex portal.
class AssessmentRow {
  const AssessmentRow({required this.name, required this.score});

  final String name;
  final double score;

  Map<String, dynamic> toJson() => {'name': name, 'score': score};

  static AssessmentRow fromJson(Map<String, dynamic> j) => AssessmentRow(
    name: j['name']?.toString() ?? '',
    score: _safeDouble(j['score']),
  );

  static double _safeDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return (v.isNaN || v.isInfinite) ? 0.0 : v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static List<AssessmentRow> listFromJson(String jsonStr) {
    try {
      final list = jsonDecode(jsonStr) as List;
      return list
          .map(
            (e) => AssessmentRow.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String listToJson(List<AssessmentRow> rows) =>
      jsonEncode(rows.map((r) => r.toJson()).toList());
}

/// Phase-3 calculation engine.
///
/// Theory rules:
/// - 3-credit theory: `(best_CT_1 + best_CT_2) * 1.5 + MID + PERFORMANCE + ATTENDANCE`
/// - 2-credit theory: `best_CT_1 + best_CT_2 + MID + PERFORMANCE + ATTENDANCE`
///
/// Sessional rule:
/// - Sum every scraped assessment row directly.
class IncourseCalculator {
  IncourseCalculator._();

  static double calcTheory(List<AssessmentRow> rows, {double credits = 3.0}) {
    final ctBase = _ctBase(rows, credits: credits);
    final mid = _findScore(rows, 'MID TERM');
    final perf = _findScore(rows, 'CLASS PERFORMANCE');
    final att = _findScore(rows, 'ATTENDANCE');
    return ctBase + mid + perf + att;
  }

  static double calcSessional(List<AssessmentRow> rows) =>
      rows.fold(0.0, (sum, row) => sum + _safe(row.score));

  static Map<String, double> getBreakdown(
    List<AssessmentRow> rows, {
    required bool isTheory,
    double credits = 3.0,
  }) {
    if (!isTheory) {
      final total = calcSessional(rows);
      return {'Total': total};
    }

    final ctBase = _ctBase(rows, credits: credits);
    final mid = _findScore(rows, 'MID TERM');
    final perf = _findScore(rows, 'CLASS PERFORMANCE');
    final att = _findScore(rows, 'ATTENDANCE');

    return {
      ctBreakdownLabel(credits): ctBase,
      'Mid Term': mid,
      'Class Performance': perf,
      'Attendance': att,
      'Total': ctBase + mid + perf + att,
    };
  }

  static List<AssessmentRow> topCTs(List<AssessmentRow> rows) {
    final cts =
        rows.where((r) => r.name.trim().toUpperCase().startsWith('CT')).toList()
          ..sort((a, b) => b.score.compareTo(a.score));
    return cts.take(2).toList();
  }

  static String ctBreakdownLabel(double credits) =>
      credits <= 2.0 ? 'CT Base (best-2)' : 'CT Base (x1.5)';

  static String ctFormulaHint(double credits) => credits <= 2.0
      ? 'Formula: CT1 + CT2 + Mid + Performance + Attendance'
      : 'Formula: (CT1 + CT2) x 1.5 + Mid + Performance + Attendance';

  static double _ctBase(List<AssessmentRow> rows, {double credits = 3.0}) {
    final cts =
        rows.where((r) => r.name.trim().toUpperCase().startsWith('CT')).toList()
          ..sort((a, b) => b.score.compareTo(a.score));
    final top2sum = cts.take(2).fold(0.0, (sum, row) => sum + _safe(row.score));
    if (credits <= 2.0) return top2sum;
    return top2sum * 1.5;
  }

  static double _findScore(List<AssessmentRow> rows, String keyword) {
    final normalized = _normalizeAssessmentToken(keyword);
    for (final row in rows) {
      final rowName = _normalizeAssessmentToken(row.name);
      if (rowName.contains(normalized)) {
        return _safe(row.score);
      }
    }
    return 0.0;
  }

  static String _normalizeAssessmentToken(String value) {
    return value
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static double _safe(double value) =>
      (value.isNaN || value.isInfinite) ? 0.0 : value;
}
