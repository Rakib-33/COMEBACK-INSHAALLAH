import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../app_theme.dart';
import '../controllers/app_controller.dart';
import '../core/calculator_engine.dart';
import '../core/course_model.dart';
import '../core/grade_system.dart';
import '../core/number_formatters.dart';
import 'uniplex_webview_screen.dart';
import 'widgets/glass_card.dart';
import 'widgets/brand_logo.dart';
import 'widgets/neon_background.dart';

class CourseTargetScreen extends StatelessWidget {
  const CourseTargetScreen({super.key, required this.courseId});

  final String courseId;

  CourseModel? _findCourse() {
    final ctl = Get.find<AppController>();
    for (final c in ctl.courses) {
      if (c.id == courseId) return c;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final course = _findCourse();
      if (course == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => Get.back());
        return const Scaffold(body: SizedBox.shrink());
      }
      if (!course.isTheory) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.back();
          Get.snackbar(
            'Sessional course',
            'Target engine applies to theory courses only.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.black87,
            colorText: Colors.white,
          );
        });
        return const Scaffold(body: SizedBox.shrink());
      }
      return _TargetBody(course: course);
    });
  }
}

class _TargetBody extends StatefulWidget {
  const _TargetBody({required this.course});

  final CourseModel course;

  @override
  State<_TargetBody> createState() => _TargetBodyState();
}

class _TargetBodyState extends State<_TargetBody> {
  late String _target = widget.course.targetGrade ?? 'A+';

  @override
  void didUpdateWidget(covariant _TargetBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.course.id != widget.course.id) {
      _target = widget.course.targetGrade ?? 'A+';
    }
  }

  Future<void> _setGrade(String g) async {
    setState(() => _target = g);
    await Get.find<AppController>().updateTargetGrade(widget.course.id, g);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.course;
    final total = totalMarksForCredits(c.credits);
    final maxFinal = maxFinalMarks(c.credits);
    final pct = c.maxIncourse == 0
        ? 0.0
        : (c.incourseMarks / c.maxIncourse) * 100.0;
    final req = requiredFinalMarks(
      credits: c.credits,
      incourseMarks: c.incourseMarks,
      targetGrade: _target,
    );
    final projected = c.incourseMarks + req;
    final projectedPct = total == 0 ? 0.0 : (projected / total) * 100.0;

    final gradesRow1 = kGradeSystem.keys.take(5).toList();
    final gradesRow2 = kGradeSystem.keys.skip(5).toList();

    return Scaffold(
      body: Container(
        decoration: AppTheme.pageBackground(),
        child: Stack(
          children: [
            const Positioned.fill(child: NeonBackgroundOrbs(durationSec: 10)),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                          children: [
                            IconButton(
                              onPressed: () => Get.back(),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.06,
                                ),
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.10),
                                ),
                              ),
                              icon: const Icon(Icons.arrow_back),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.code,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                  ),
                                  Text(
                                    c.name,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.60,
                                      ),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                        .animate()
                        .fadeIn(duration: 520.ms)
                        .moveY(begin: -10, end: 0),
                    const SizedBox(height: 14),
                    GlassCard(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.violet.withValues(
                                            alpha: 0.22,
                                          ),
                                          AppColors.cyan.withValues(
                                            alpha: 0.18,
                                          ),
                                        ],
                                      ),
                                      border: Border.all(
                                        color: AppColors.violet.withValues(
                                          alpha: 0.30,
                                        ),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.track_changes,
                                      color: AppColors.violet,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Incourse Performance',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Center(
                                child: _Ring(
                                  percent: pct,
                                  centerValue: c.incourseMarks,
                                  max: c.maxIncourse,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: _MiniStat(
                                      title: 'Course Credits',
                                      value: c.credits.formatPrecise(
                                        maxDecimals: 2,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _MiniStat(
                                      title: 'Max Final',
                                      value: maxFinal.formatPrecise(
                                        maxDecimals: 2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 120.ms, duration: 520.ms)
                        .scale(begin: const Offset(0.98, 0.98)),
                    const SizedBox(height: 12),
                    // ── Assessment Breakdown (shown after marks sync) ──────
                    if (c.hasAssessmentData)
                      _AssessmentBreakdownCard(course: c)
                          .animate()
                          .fadeIn(delay: 380.ms, duration: 500.ms)
                          .moveY(begin: 12, end: 0),
                    if (c.hasAssessmentData) const SizedBox(height: 12),
                    if (!c.hasAssessmentData &&
                        c.isTheory &&
                        c.detailUrl != null)
                      _SyncNudge(course: c)
                          .animate()
                          .fadeIn(delay: 380.ms)
                          .moveY(begin: 10, end: 0),
                    if (!c.hasAssessmentData && c.isTheory)
                      const SizedBox(height: 12),
                    GlassCard(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.cyan.withValues(
                                            alpha: 0.20,
                                          ),
                                          AppColors.violet.withValues(
                                            alpha: 0.18,
                                          ),
                                        ],
                                      ),
                                      border: Border.all(
                                        color: AppColors.cyan.withValues(
                                          alpha: 0.30,
                                        ),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.emoji_events_outlined,
                                      color: AppColors.cyan,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Select Target Grade',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _gradeRow(gradesRow1),
                              const SizedBox(height: 8),
                              _gradeRow(gradesRow2),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 220.ms, duration: 520.ms)
                        .moveY(begin: 12, end: 0),
                    const SizedBox(height: 12),
                    Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: LinearGradient(
                              colors: [
                                AppColors.violet.withValues(alpha: 0.22),
                                AppColors.cyan.withValues(alpha: 0.18),
                              ],
                            ),
                            border: Border.all(
                              color: AppColors.violet.withValues(alpha: 0.30),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.violet.withValues(alpha: 0.22),
                                blurRadius: 26,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const BrandLogo(
                                    size: 28,
                                    radius: 10,
                                    glow: false,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Target Engine Result',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _kv(
                                'Target Grade:',
                                Text(
                                  _target,
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              _kv(
                                'GPA Points:',
                                Text(
                                  '${kGradeSystem[_target]?.gpa ?? ''}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.cyan,
                                  ),
                                ),
                              ),
                              const Divider(
                                color: Color.fromRGBO(255, 255, 255, 0.18),
                              ),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.16),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Required Marks in Final',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.60,
                                        ),
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                              '$req',
                                              key: ValueKey(req),
                                              style: const TextStyle(
                                                fontSize: 44,
                                                fontWeight: FontWeight.w900,
                                                color: Colors.white,
                                              ),
                                            )
                                            .animate(key: ValueKey(req))
                                            .scale(
                                              duration: 260.ms,
                                              begin: const Offset(1.08, 1.08),
                                              curve: Curves.easeOut,
                                            ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '/ ${maxFinal.formatPrecise(maxDecimals: 2)}',
                                          style: TextStyle(
                                            fontSize: 20,
                                            color: Colors.white.withValues(
                                              alpha: 0.55,
                                            ),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(999),
                                      child: TweenAnimationBuilder<double>(
                                        tween: Tween(
                                          begin: 0,
                                          end: maxFinal == 0
                                              ? 0
                                              : (req / maxFinal).clamp(
                                                  0.0,
                                                  1.0,
                                                ),
                                        ),
                                        duration: 650.ms,
                                        curve: Curves.easeOutCubic,
                                        builder: (context, v, _) => Stack(
                                          children: [
                                            Container(
                                              height: 10,
                                              color: Colors.white.withValues(
                                                alpha: 0.10,
                                              ),
                                            ),
                                            FractionallySizedBox(
                                              widthFactor: v,
                                              child: Container(
                                                height: 10,
                                                decoration: const BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      AppColors.violet,
                                                      AppColors.cyan,
                                                    ],
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Color.fromRGBO(
                                                        139,
                                                        92,
                                                        246,
                                                        0.55,
                                                      ),
                                                      blurRadius: 14,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Projected Total',
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.60,
                                              ),
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${projected.formatPrecise(maxDecimals: 2)} / ${total.formatPrecise(maxDecimals: 2)}',
                                            style: const TextStyle(
                                              fontSize: 26,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.trending_up,
                                      color: AppColors.cyan,
                                    ),
                                  ],
                                ),
                              ),
                              if (req > maxFinal * 0.9) ...[
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.violet.withValues(
                                      alpha: 0.18,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.violet.withValues(
                                        alpha: 0.28,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'High target! You will need ${((req / maxFinal) * 100).formatPrecise(maxDecimals: 2)}% on the final exam component.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.82,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                ).animate().fadeIn(duration: 420.ms),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                'Projected overall: ${projectedPct.formatPrecise(maxDecimals: 2)}%',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate()
                        .fadeIn(delay: 320.ms, duration: 520.ms)
                        .moveY(begin: 12, end: 0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradeRow(List<String> grades) {
    return Row(
      children: [
        for (final g in grades) ...[
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _GradeChip(
                label: g,
                selected: _target == g,
                onTap: () => _setGrade(g),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _kv(String k, Widget v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            k,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.70)),
          ),
          Flexible(
            child: Align(alignment: Alignment.centerRight, child: v),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.60),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeChip extends StatelessWidget {
  const _GradeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: selected
                ? const LinearGradient(
                    colors: [AppColors.violet, AppColors.cyan],
                  )
                : null,
            color: selected ? null : Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: Colors.white.withValues(alpha: selected ? 0.00 : 0.10),
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.violet.withValues(alpha: 0.35),
                      blurRadius: 18,
                    ),
                  ]
                : const [],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.72),
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({
    required this.percent,
    required this.centerValue,
    required this.max,
  });

  final double percent;
  final double centerValue;
  final double max;

  @override
  Widget build(BuildContext context) {
    final r = 92.0;
    final stroke = 12.0;
    final c = 2 * math.pi * r;
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: percent.clamp(0, 100) / 100.0),
            duration: 900.ms,
            curve: Curves.easeOutCubic,
            builder: (context, progress, _) => CustomPaint(
              size: const Size(220, 220),
              painter: _RingPainter(
                progress: progress,
                circumference: c,
                radius: r,
                stroke: stroke,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerValue.formatPrecise(maxDecimals: 2),
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ).animate().scale(
                delay: 200.ms,
                duration: 420.ms,
                begin: const Offset(0.92, 0.92),
                curve: Curves.easeOutBack,
              ),
              Text(
                'out of ${max.formatPrecise(maxDecimals: 2)}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.60),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${percent.formatPrecise(maxDecimals: 2)}%',
                style: const TextStyle(
                  color: AppColors.cyan,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.circumference,
    required this.radius,
    required this.stroke,
  });

  final double progress;
  final double circumference;
  final double radius;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final bg = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bg);

    final rect = Rect.fromCircle(center: center, radius: radius);
    final grad = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: 1.5 * math.pi,
      colors: const [AppColors.violet, AppColors.cyan],
    );
    final fg = Paint()
      ..shader = grad.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final sweep = (progress * circumference / radius).clamp(
      0.0,
      6.283185307179586,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Assessment Breakdown Card
// ─────────────────────────────────────────────────────────────────────────────

class _AssessmentBreakdownCard extends StatelessWidget {
  const _AssessmentBreakdownCard({required this.course});
  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    final rows = course.assessmentRows
        .map((e) => AssessmentRow.fromJson(e))
        .toList();

    final ctRows =
        rows.where((r) => r.name.trim().toUpperCase().startsWith('CT')).toList()
          ..sort((a, b) => b.score.compareTo(a.score));
    final top2ids = ctRows.take(2).map((r) => r.name).toSet();

    final breakdown = IncourseCalculator.getBreakdown(
      rows,
      isTheory: course.isTheory,
      credits: course.credits,
    );
    final ctLabel = IncourseCalculator.ctBreakdownLabel(course.credits);
    final ctFormulaHint = IncourseCalculator.ctFormulaHint(course.credits);

    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [
                      AppColors.cyan.withValues(alpha: 0.22),
                      AppColors.violet.withValues(alpha: 0.18),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.cyan.withValues(alpha: 0.30),
                  ),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: AppColors.cyan,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Marks Breakdown',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // CT rows
          if (ctRows.isNotEmpty) ...[
            Text(
              'Class Tests (CTs)',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.55),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 6),
            ...ctRows.map((r) {
              final isTop = top2ids.contains(r.name);
              return _BreakdownRow(
                label: r.name,
                value: r.score,
                accent: isTop ? AppColors.violet : null,
                badge: isTop ? 'TOP 2' : null,
              );
            }),
            // CT formula line
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    course.credits <= 2.0
                        ? 'CT Base  (best-2 direct)'
                        : 'CT Base  (top-2 x 1.5)',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.violet.withValues(alpha: 0.90),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '= ${(breakdown[ctLabel] ?? 0).formatPrecise(maxDecimals: 2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.violet,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: Colors.white.withValues(alpha: 0.10)),
            const SizedBox(height: 10),
          ],

          // Other components
          _BreakdownRow(
            label: 'Mid Term',
            value: breakdown['Mid Term'] ?? 0,
            accent: AppColors.cyan,
          ),
          _BreakdownRow(
            label: 'Class Performance',
            value: breakdown['Class Performance'] ?? 0,
            accent: AppColors.cyan,
          ),
          _BreakdownRow(
            label: 'Attendance',
            value: breakdown['Attendance'] ?? 0,
            accent: AppColors.cyan,
          ),

          const SizedBox(height: 8),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.12)),
          const SizedBox(height: 10),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total In-Course',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                '${(breakdown['Total'] ?? 0).formatPrecise(maxDecimals: 2)} / ${course.maxIncourse.formatPrecise(maxDecimals: 2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.cyan,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),
          // Formula hint
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Text(
              ctFormulaHint,
              style: TextStyle(
                fontSize: 10.5,
                color: Colors.white.withValues(alpha: 0.50),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    this.accent,
    this.badge,
  });

  final String label;
  final double value;
  final Color? accent;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final col = accent ?? Colors.white.withValues(alpha: 0.72);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: col, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.80),
              ),
            ),
          ),
          if (badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.violet.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.violet.withValues(alpha: 0.40),
                ),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: AppColors.violet,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            value.formatPrecise(maxDecimals: 2),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: col,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sync Nudge — shown when marks haven't been synced yet
// ─────────────────────────────────────────────────────────────────────────────

class _SyncNudge extends StatelessWidget {
  const _SyncNudge({required this.course});
  final CourseModel course;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (course.detailUrl == null) return;
        // Open WebView — user navigates to the Assessments tab
        Get.to<void>(() => UniplexWebViewScreen(studentId: '', password: ''));
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppColors.violet.withValues(alpha: 0.10),
          border: Border.all(color: AppColors.violet.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.sync_rounded,
              color: AppColors.violet.withValues(alpha: 0.80),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Marks not synced yet. Open the Assessments page in the portal and tap "Sync Marks".',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
