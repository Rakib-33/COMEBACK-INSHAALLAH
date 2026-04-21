import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../app_theme.dart';
import '../controllers/app_controller.dart';
import '../core/course_model.dart';
import '../core/number_formatters.dart';
import 'widgets/brand_logo.dart';
import 'widgets/glass_card.dart';

class GpaPredictorSheet extends StatelessWidget {
  const GpaPredictorSheet({super.key});

  static const _topGrades = ['A+', 'A', 'A-', 'B+', 'B'];

  @override
  Widget build(BuildContext context) {
    final ctl = Get.find<AppController>();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.76,
      minChildSize: 0.42,
      maxChildSize: 0.90,
      builder: (context, scroll) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromRGBO(15, 23, 42, 0.96),
                      Color.fromRGBO(26, 11, 46, 0.96),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.violet.withValues(alpha: 0.24),
                      blurRadius: 34,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  child: Obx(() {
                    final courses = ctl.courses;
                    final cgpa = ctl.predictedTermCgpa();
                    final cgpaText = cgpa.toStringAsFixed(2);
                    final totalCred = courses.fold<double>(
                      0,
                      (a, c) => a + c.credits,
                    );
                    final status = cgpa >= 3.5
                        ? 'Spark'
                        : cgpa >= 3.0
                        ? 'Steady'
                        : 'Focus';
                    final statusIcon = cgpa >= 3.5
                        ? Icons.auto_awesome_rounded
                        : cgpa >= 3.0
                        ? Icons.thumb_up_alt_rounded
                        : Icons.menu_book_rounded;
                    return Column(
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 14, 10, 10),
                          child: Row(
                            children: [
                              const BrandLogo(size: 62, radius: 18, padding: 2),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Term GPA Predictor',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                          ),
                                    ),
                                    Obx(
                                      () => Text(
                                        ctl.semesterLabel.value,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.58,
                                          ),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.06,
                                  ),
                                  foregroundColor: Colors.white,
                                  side: BorderSide(
                                    color: Colors.white.withValues(alpha: 0.10),
                                  ),
                                ),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: _CgpaHero(cgpa: cgpa, cgpaText: cgpaText),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'ADJUST GRADES',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.58),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ScrollbarTheme(
                            data: ScrollbarThemeData(
                              thumbColor: WidgetStatePropertyAll(
                                AppColors.textMuted.withValues(alpha: 0.85),
                              ),
                              trackColor: WidgetStatePropertyAll(
                                Colors.white.withValues(alpha: 0.08),
                              ),
                              trackBorderColor: WidgetStatePropertyAll(
                                Colors.transparent,
                              ),
                              radius: const Radius.circular(999),
                              thickness: const WidgetStatePropertyAll(8),
                              thumbVisibility: const WidgetStatePropertyAll(
                                true,
                              ),
                              trackVisibility: const WidgetStatePropertyAll(
                                true,
                              ),
                            ),
                            child: Scrollbar(
                              controller: scroll,
                              child: ListView.separated(
                                controller: scroll,
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  16,
                                ),
                                itemCount: courses.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final c = courses[index];
                                  return _CourseGradeCard(
                                        course: c,
                                        grades: _topGrades,
                                        onPick: (g) async {
                                          if (c.isTheory) {
                                            await ctl.updateTargetGrade(
                                              c.id,
                                              g,
                                            );
                                          } else {
                                            await ctl.updatePredictedGrade(
                                              c.id,
                                              g,
                                            );
                                          }
                                        },
                                      )
                                      .animate()
                                      .fadeIn(
                                        delay: (40 * index).ms,
                                        duration: 380.ms,
                                      )
                                      .moveX(begin: -12, end: 0);
                                },
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.18),
                            border: Border(
                              top: BorderSide(
                                color: Colors.white.withValues(alpha: 0.10),
                              ),
                            ),
                          ),
                          child: SafeArea(
                            top: false,
                            child: Row(
                              children: [
                                Expanded(
                                  child: _FooterStat(
                                    title: 'Courses',
                                    value: '${courses.length}',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _FooterStat(
                                    title: 'Credits',
                                    value: totalCred.formatPrecise(
                                      maxDecimals: 2,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _FooterStat(
                                    title: 'Status',
                                    value: status,
                                    icon: statusIcon,
                                    highlighted: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CgpaHero extends StatelessWidget {
  const _CgpaHero({required this.cgpa, required this.cgpaText});

  final double cgpa;
  final String cgpaText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [
            AppColors.violet.withValues(alpha: 0.22),
            AppColors.cyan.withValues(alpha: 0.18),
          ],
        ),
        border: Border.all(color: AppColors.violet.withValues(alpha: 0.30)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -10,
            right: -10,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.violet.withValues(alpha: 0.18),
              ),
            ),
          ),
          Positioned(
            bottom: -14,
            left: -14,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyan.withValues(alpha: 0.16),
              ),
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Predicted Term CGPA',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.62),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                                  cgpaText,
                                  key: ValueKey(cgpaText),
                                  style: const TextStyle(
                                    fontSize: 54,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                )
                                .animate(key: ValueKey(cgpaText))
                                .scale(
                                  duration: 260.ms,
                                  begin: const Offset(1.06, 1.06),
                                  curve: Curves.easeOut,
                                ),
                            const SizedBox(width: 8),
                            Text(
                              '/ 4.00',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white.withValues(alpha: 0.55),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.cyan.withValues(alpha: 0.28),
                              AppColors.violet.withValues(alpha: 0.24),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.cyan.withValues(alpha: 0.30),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.verified_rounded,
                          color: AppColors.cyan,
                          size: 34,
                        ),
                      )
                      .animate(onPlay: (c) => c.repeat())
                      .rotate(
                        begin: 0,
                        end: 1,
                        duration: 5200.ms,
                        curve: Curves.linear,
                      ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: (cgpa / 4.0).clamp(0.0, 1.0)),
                  duration: 900.ms,
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => Stack(
                    children: [
                      Container(
                        height: 10,
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                      FractionallySizedBox(
                        widthFactor: v,
                        child: Container(
                          height: 10,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.violet, AppColors.cyan],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromRGBO(139, 92, 246, 0.55),
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
        ],
      ),
    );
  }
}

class _CourseGradeCard extends StatelessWidget {
  const _CourseGradeCard({
    required this.course,
    required this.grades,
    required this.onPick,
  });

  final CourseModel course;
  final List<String> grades;
  final Future<void> Function(String grade) onPick;

  @override
  Widget build(BuildContext context) {
    final isTheory = course.isTheory;
    final current = isTheory
        ? (course.targetGrade ?? 'A')
        : (course.predictedGrade ?? 'A');
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.code,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      course.name,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.62),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${course.credits.formatPrecise(maxDecimals: 2)} credits',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.48),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (isTheory)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.violet.withValues(alpha: 0.22),
                        AppColors.cyan.withValues(alpha: 0.18),
                      ],
                    ),
                    border: Border.all(
                      color: AppColors.violet.withValues(alpha: 0.28),
                    ),
                  ),
                  child: const Text(
                    'Theory',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final g in grades)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => onPick(g),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: current == g
                                ? const LinearGradient(
                                    colors: [AppColors.violet, AppColors.cyan],
                                  )
                                : null,
                            color: current == g
                                ? null
                                : Colors.white.withValues(alpha: 0.06),
                            border: Border.all(
                              color: Colors.white.withValues(
                                alpha: current == g ? 0.00 : 0.10,
                              ),
                            ),
                            boxShadow: current == g
                                ? [
                                    BoxShadow(
                                      color: AppColors.violet.withValues(
                                        alpha: 0.30,
                                      ),
                                      blurRadius: 14,
                                    ),
                                  ]
                                : const [],
                          ),
                          child: Center(
                            child: Text(
                              g,
                              style: TextStyle(
                                color: Colors.white.withValues(
                                  alpha: current == g ? 1.0 : 0.72,
                                ),
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FooterStat extends StatelessWidget {
  const _FooterStat({
    required this.title,
    required this.value,
    this.icon,
    this.highlighted = false,
  });

  final String title;
  final String value;
  final IconData? icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: highlighted
            ? LinearGradient(
                colors: [
                  AppColors.violet.withValues(alpha: 0.24),
                  AppColors.cyan.withValues(alpha: 0.18),
                ],
              )
            : null,
        color: highlighted ? null : Colors.white.withValues(alpha: 0.06),
        border: Border.all(
          color: highlighted
              ? AppColors.violet.withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.58),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          if (icon != null)
            Icon(icon, color: const Color(0xFFFFB454), size: 22)
          else
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          if (icon != null)
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
