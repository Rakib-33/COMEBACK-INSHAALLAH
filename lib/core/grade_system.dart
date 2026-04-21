import 'dart:math' as math;

/// Bangladesh public-university style letter grades (percent thresholds) + GPA points.
class GradeInfo {
  const GradeInfo({required this.percentage, required this.gpa});

  final double percentage;
  final double gpa;
}

const Map<String, GradeInfo> kGradeSystem = {
  'A+': GradeInfo(percentage: 80, gpa: 4.0),
  'A': GradeInfo(percentage: 75, gpa: 3.75),
  'A-': GradeInfo(percentage: 70, gpa: 3.5),
  'B+': GradeInfo(percentage: 65, gpa: 3.25),
  'B': GradeInfo(percentage: 60, gpa: 3.0),
  'B-': GradeInfo(percentage: 55, gpa: 2.75),
  'C+': GradeInfo(percentage: 50, gpa: 2.5),
  'C': GradeInfo(percentage: 45, gpa: 2.25),
  'D': GradeInfo(percentage: 40, gpa: 2.0),
};

const Map<String, double> kGradeToGpa = {
  'A+': 4.0,
  'A': 3.75,
  'A-': 3.5,
  'B+': 3.25,
  'B': 3.0,
  'B-': 2.75,
  'C+': 2.5,
  'C': 2.25,
  'D': 2.0,
  'F': 0.0,
};

double gpaForGrade(String? grade) => kGradeToGpa[grade] ?? 3.5;

bool isTheoryCourseCode(String code) {
  final digits = RegExp(r'(\d{3})\b').firstMatch(code);
  if (digits == null) return true;
  final n = int.tryParse(digits.group(1)!);
  if (n == null) return true;
  return n % 2 == 1;
}

double totalMarksForCredits(double credits) => credits * 100;

double maxIncourseMarks(double credits) => totalMarksForCredits(credits) * 0.4;

double maxFinalMarks(double credits) => totalMarksForCredits(credits) * 0.6;

/// Required marks on the final (60% component), capped at [maxFinal].
double requiredFinalMarks({
  required double credits,
  required double incourseMarks,
  required String targetGrade,
}) {
  final total = totalMarksForCredits(credits);
  final maxFinal = maxFinalMarks(credits);
  final pct = kGradeSystem[targetGrade]?.percentage ?? 75;
  final requiredTotal = (pct / 100) * total;
  final requiredInFinal = math.max(0.0, requiredTotal - incourseMarks);
  return math.min(requiredInFinal, maxFinal);
}
