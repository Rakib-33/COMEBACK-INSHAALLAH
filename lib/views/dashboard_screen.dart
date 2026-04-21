import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../app_theme.dart';
import '../controllers/app_controller.dart';
import '../core/course_model.dart';
import '../core/number_formatters.dart';
import '../routes/app_pages.dart';
import 'gpa_predictor_sheet.dart';
import 'widgets/brand_logo.dart';
import 'widgets/glass_card.dart';
import 'widgets/neon_background.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ctl = Get.find<AppController>();
    return Scaffold(
      body: Container(
        decoration: AppTheme.pageBackground(),
        child: Stack(
          children: [
            const Positioned.fill(child: NeonBackgroundOrbs(durationSec: 12)),
            SafeArea(
              child: Obx(() {
                final courses = ctl.courses;
                final totalCred = courses.fold<double>(
                  0,
                  (a, c) => a + c.credits,
                );
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                            'Dashboard',
                                            style: Theme.of(context)
                                                .textTheme
                                                .headlineMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.white,
                                                ),
                                          )
                                          .animate()
                                          .fadeIn(duration: 520.ms)
                                          .moveY(begin: -10, end: 0),
                                      const SizedBox(height: 4),
                                      Obx(
                                        () => Text(
                                          ctl.semesterLabel.value,
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.60,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const BrandLogo(
                                      size: 62,
                                      radius: 20,
                                      padding: 3,
                                    )
                                    .animate(
                                      onPlay: (c) => c.repeat(reverse: true),
                                    )
                                    .scale(
                                      begin: const Offset(1, 1),
                                      end: const Offset(1.06, 1.06),
                                      duration: 1500.ms,
                                      curve: Curves.easeInOut,
                                    ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child:
                                      _statCard(
                                            context,
                                            title: 'Total Courses',
                                            value: courses.length.toString(),
                                            icon: Icons.track_changes,
                                            iconColor: AppColors.violet,
                                          )
                                          .animate()
                                          .fadeIn(
                                            delay: 120.ms,
                                            duration: 520.ms,
                                          )
                                          .moveY(begin: 12, end: 0),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child:
                                      _statCard(
                                            context,
                                            title: 'Total Credits',
                                            value: totalCred.formatPrecise(
                                              maxDecimals: 2,
                                            ),
                                            icon: Icons.emoji_events_outlined,
                                            iconColor: AppColors.cyan,
                                          )
                                          .animate()
                                          .fadeIn(
                                            delay: 200.ms,
                                            duration: 520.ms,
                                          )
                                          .moveY(begin: 12, end: 0),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'My Courses',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                  ),
                                ),
                                _GlowActionButton(
                                      onPressed: courses.isEmpty
                                          ? null
                                          : () => showModalBottomSheet<void>(
                                              context: context,
                                              isScrollControlled: true,
                                              backgroundColor:
                                                  Colors.transparent,
                                              builder: (_) =>
                                                  const GpaPredictorSheet(),
                                            ),
                                      label: 'View GPA',
                                    )
                                    .animate(
                                      onPlay: (controller) =>
                                          controller.repeat(reverse: true),
                                    )
                                    .shimmer(
                                      duration: 1800.ms,
                                      color: Colors.white.withValues(
                                        alpha: 0.22,
                                      ),
                                    ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: ctl.logout,
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.white.withValues(
                                      alpha: 0.06,
                                    ),
                                    foregroundColor: Colors.white,
                                    side: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.10,
                                      ),
                                    ),
                                  ),
                                  icon: const Icon(Icons.logout),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                    if (courses.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: GlassCard(
                            child: Text(
                              'No courses yet. Go back to sync and import from Uniplex.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.70),
                              ),
                            ),
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                      sliver: SliverList.separated(
                        itemCount: courses.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final c = courses[index];
                          return _CourseTile(
                            course: c,
                            index: index,
                            onOpenTheory: () =>
                                Get.toNamed('${AppRoutes.course}/${c.id}'),
                            onPredict: (g) => ctl.updatePredictedGrade(c.id, g),
                          );
                        },
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconColor.withValues(alpha: 0.14),
                  border: Border.all(color: iconColor.withValues(alpha: 0.28)),
                ),
                child: Icon(icon, size: 15, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.60),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
        ],
      ),
    );
  }
}

class _GlowActionButton extends StatelessWidget {
  const _GlowActionButton({required this.onPressed, required this.label});

  final VoidCallback? onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: disabled
            ? const []
            : [
                BoxShadow(
                  color: AppColors.violet.withValues(alpha: 0.34),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppColors.cyan.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(999),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                colors: disabled
                    ? [
                        Colors.white.withValues(alpha: 0.08),
                        Colors.white.withValues(alpha: 0.06),
                      ]
                    : const [AppColors.violet, AppColors.cyan],
              ),
              border: Border.all(
                color: disabled
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.22),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  size: 18,
                  color: disabled
                      ? Colors.white.withValues(alpha: 0.45)
                      : Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: disabled
                        ? Colors.white.withValues(alpha: 0.45)
                        : Colors.white,
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

class _CourseTile extends StatelessWidget {
  const _CourseTile({
    required this.course,
    required this.index,
    required this.onOpenTheory,
    required this.onPredict,
  });

  final CourseModel course;
  final int index;
  final VoidCallback onOpenTheory;
  final void Function(String grade) onPredict;

  void _openSyncScreen() {
    Get.offAllNamed(AppRoutes.sync);
  }

  @override
  Widget build(BuildContext context) {
    final theory = course.isTheory;
    final pct = course.maxIncourse == 0
        ? 0.0
        : (course.incourseMarks / course.maxIncourse) * 100.0;
    return GlassCard(
          onTap: theory ? onOpenTheory : null,
          borderColor: theory
              ? Colors.white.withValues(alpha: 0.10)
              : Colors.white.withValues(alpha: 0.08),
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
                        Row(
                          children: [
                            Text(
                              course.code,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                            ),
                            const Spacer(),
                            // Sync indicator
                            if (theory &&
                                course.incourseMarks == 0 &&
                                !course.hasAssessmentData)
                              _SyncChip(onTap: _openSyncScreen)
                                  .animate(
                                    onPlay: (c) => c.repeat(reverse: true),
                                  )
                                  .fadeIn(duration: 900.ms)
                                  .then()
                                  .fadeOut(duration: 900.ms)
                            else if (theory && course.hasAssessmentData)
                              _SyncedBadge(
                                marks: course.incourseMarks,
                                max: course.maxIncourse,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          course.name,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.70),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${course.credits.formatPrecise(maxDecimals: 2)} Credits',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.48),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (theory)
                    Icon(
                      Icons.chevron_right,
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                ],
              ),
              if (theory) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Incourse Progress',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.60),
                      ),
                    ),
                    Text(
                      '${course.incourseMarks.formatPrecise(maxDecimals: 2)}/${course.maxIncourse.formatPrecise(maxDecimals: 2)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.cyan,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: pct.clamp(0, 100) / 100.0),
                    duration: Duration(milliseconds: 650 + (index * 80)),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) {
                      return Stack(
                        children: [
                          Container(
                            height: 8,
                            color: Colors.white.withValues(alpha: 0.10),
                          ),
                          FractionallySizedBox(
                            widthFactor: v,
                            child: Container(
                              height: 8,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppColors.violet, AppColors.cyan],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color.fromRGBO(139, 92, 246, 0.45),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
              if (!theory) ...[
                const SizedBox(height: 12),
                const Divider(
                  height: 1,
                  color: Color.fromRGBO(255, 255, 255, 0.10),
                ),
                const SizedBox(height: 10),
                Text(
                  'Predicted Grade',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.60),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['A+', 'A', 'A-', 'B+', 'B'].map((g) {
                    final selected = course.predictedGrade == g;
                    return ChoiceChip(
                      label: Text(g),
                      selected: selected,
                      onSelected: (_) => onPredict(g),
                      selectedColor: AppColors.violet.withValues(alpha: 0.55),
                      backgroundColor: Colors.white.withValues(alpha: 0.06),
                      labelStyle: TextStyle(
                        color: selected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        )
        .animate()
        .fadeIn(delay: (60 * index).ms, duration: 420.ms)
        .moveX(begin: -14, end: 0);
  }
}

// ── Pulsing chip for unsynced theory courses ──────────────────────────────────

class _SyncChip extends StatelessWidget {
  const _SyncChip({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: AppColors.cyan.withValues(alpha: 0.15),
          border: Border.all(color: AppColors.cyan.withValues(alpha: 0.40)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sync_rounded,
              size: 12,
              color: AppColors.cyan.withValues(alpha: 0.90),
            ),
            const SizedBox(width: 4),
            Text(
              'Sync',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.cyan.withValues(alpha: 0.90),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Green marks badge for synced theory courses ───────────────────────────────

class _SyncedBadge extends StatelessWidget {
  const _SyncedBadge({required this.marks, required this.max});
  final double marks;
  final double max;

  @override
  Widget build(BuildContext context) {
    final pct = max == 0 ? 0.0 : (marks / max * 100);
    final col = pct >= 75
        ? const Color(0xFF22C55E) // green
        : pct >= 55
        ? AppColors.cyan
        : AppColors.violet;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: col.withValues(alpha: 0.15),
        border: Border.all(color: col.withValues(alpha: 0.40)),
      ),
      child: Text(
        '${marks.formatPrecise(maxDecimals: 2)}/${max.formatPrecise(maxDecimals: 2)}',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: col),
      ),
    );
  }
}
