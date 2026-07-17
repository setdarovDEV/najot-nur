import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/learning_models.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/secure_screen.dart';

/// Enrolled-course learning screen, Liquid Glass mockup "6b": glass back
/// chrome, a gradient course progress bar and the lesson list as rows inside
/// a single glass card. Navigation and progress logic are unchanged.
class CourseLearningScreen extends ConsumerStatefulWidget {
  const CourseLearningScreen({super.key, required this.courseId});
  final String courseId;

  @override
  ConsumerState<CourseLearningScreen> createState() =>
      _CourseLearningScreenState();
}

class _CourseLearningScreenState extends ConsumerState<CourseLearningScreen> {
  final _scrollOffset = ValueNotifier<double>(0);

  @override
  void dispose() {
    _scrollOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final courseAsync = ref.watch(courseDetailProvider(widget.courseId));
    final progressAsync = ref.watch(courseProgressProvider(widget.courseId));
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final topInset = MediaQuery.of(context).padding.top;

    // Paid video content — screenshots/recording blocked only here.
    return SecureScreen(
        child: Scaffold(
      body: Stack(
        children: [
          const AmbientOrbs(),
          courseAsync.when(
            loading: () => const AppLoader(),
            error: (e, _) => ErrorView(
              message: e.toString(),
              onRetry: () {
                ref.invalidate(courseDetailProvider(widget.courseId));
                ref.invalidate(courseProgressProvider(widget.courseId));
              },
            ),
            data: (course) => progressAsync.when(
              loading: () => const AppLoader(),
              error: (e, _) => ErrorView(message: e.toString()),
              data: (progress) => NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.axis == Axis.vertical) {
                    _scrollOffset.value = n.metrics.pixels;
                  }
                  return false;
                },
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16, topInset + 12, 16, 60),
                  children: [
                    GlassEntrance(
                      child: Row(
                        children: [
                          _GlassBackButton(
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          Expanded(
                            child: Text(
                              course.title,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (progress.enrolled) ...[
                      GlassEntrance(
                        delay: GlassMotion.entranceStep,
                        child: _ProgressHeader(progress: progress, l: l),
                      ),
                      const SizedBox(height: 14),
                    ],
                    GlassEntrance(
                      delay: GlassMotion.entranceStep * 2,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 2, bottom: 8),
                        child: Text(
                          'Kursdagi darslar',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                    GlassEntrance(
                      delay: GlassMotion.entranceStep * 3,
                      child: GlassContainer(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Column(
                          children: [
                            for (var i = 0; i < course.lessons.length; i++)
                              Builder(builder: (context) {
                                final ep = progress.enrolled &&
                                        progress.lessons.isNotEmpty
                                    ? progress.lessons
                                        .where((lp) =>
                                            lp.lessonId ==
                                            course.lessons[i].id)
                                        .firstOrNull
                                    : null;
                                return _LessonRow(
                                  index: i + 1,
                                  lesson: course.lessons[i],
                                  isCompleted: ep?.isCompleted ?? false,
                                  autoScore: ep?.autoScore,
                                  isEnrolled: progress.enrolled,
                                  showDivider:
                                      i < course.lessons.length - 1,
                                  onTap: progress.enrolled
                                      ? () => context.push(
                                            '/courses/${widget.courseId}/lessons/${course.lessons[i].id}',
                                          )
                                      : null,
                                );
                              }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GlassTopChrome(
              offset: _scrollOffset,
              title: courseAsync.maybeWhen(
                data: (c) => c.title,
                orElse: () => l.videoLessons,
              ),
            ),
          ),
        ],
      ),
    ));
  }
}

class _GlassBackButton extends StatelessWidget {
  const _GlassBackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GlassPressable(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: dark ? AppColors.glassFillDark : AppColors.glassFillLight,
          border: Border.all(
            color:
                dark ? AppColors.glassStrokeDark : AppColors.glassStrokeLight,
            width: 0.5,
          ),
        ),
        child: Icon(
          Icons.arrow_back_rounded,
          size: 20,
          color: dark ? AppColors.inkDarkPrimary : AppColors.ink,
        ),
      ),
    );
  }
}

/// Course progress — gradient bar in a glass card (mockup 6b's
/// "Kurs bo'yicha: N% yakunlandi" ramp).
class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.progress, required this.l});
  final CourseProgress progress;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final accent = dark ? AppColors.wine300 : AppColors.wine;
    final pct = progress.progressPct ?? 0;

    return GlassContainer(
      borderRadius: AppColors.radiusTariffCard,
      withShadow: false,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  progress.isCompleted
                      ? l.courseCompleted
                      : l.courseInProgress,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: progress.isCompleted ? AppColors.success : accent,
                    fontSize: 13.5,
                  ),
                ),
              ),
              Text(
                '$pct%',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: accent,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 6,
              color: dark
                  ? AppColors.wine300.withValues(alpha: 0.16)
                  : AppColors.wine.withValues(alpha: 0.10),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: (pct / 100).clamp(0.0, 1.0),
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(999)),
                    gradient: LinearGradient(
                      colors: [AppColors.wine, AppColors.orange],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.lessonsCompleted(
              progress.lessons.where((l) => l.isCompleted).length,
              progress.lessons.length,
            ),
            style: TextStyle(color: mutedColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Lesson row inside the glass list card (mockup 6b): icon tile, title,
/// meta pills and a chevron/lock.
class _LessonRow extends StatelessWidget {
  const _LessonRow({
    required this.index,
    required this.lesson,
    required this.isCompleted,
    required this.isEnrolled,
    required this.showDivider,
    this.autoScore,
    this.onTap,
  });
  final int index;
  final Lesson lesson;
  final bool isCompleted;
  final bool isEnrolled;
  final bool showDivider;
  final int? autoScore;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final accent = dark ? AppColors.wine300 : AppColors.wine;
    final lineColor = dark ? AppColors.lineDark : AppColors.line;
    final mins = (lesson.durationSec / 60).round();

    return Column(
      children: [
        GlassPressable(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.success.withValues(alpha: 0.14)
                        : (dark
                            ? AppColors.wine300.withValues(alpha: 0.16)
                            : AppColors.wine.withValues(alpha: 0.10)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check_rounded,
                          color: AppColors.success, size: 20)
                      : Text(
                          '$index',
                          style: TextStyle(
                            color: isEnrolled ? accent : mutedColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          color: isEnrolled ? textColor : mutedColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded,
                              size: 12, color: mutedColor),
                          const SizedBox(width: 4),
                          Text(
                            l.minutesShort(mins),
                            style:
                                TextStyle(color: mutedColor, fontSize: 11),
                          ),
                          if (lesson.isVoiceExercise) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.blue.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                l.aiExercise,
                                style: const TextStyle(
                                  color: AppColors.blue,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                          if (lesson.isDemo) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.orange.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                l.demoLabel,
                                style: const TextStyle(
                                  color: AppColors.orange,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                          if (isCompleted && autoScore != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success
                                    .withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$autoScore%',
                                style: const TextStyle(
                                  color: AppColors.success,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isEnrolled
                      ? Icons.chevron_right_rounded
                      : Icons.lock_outline_rounded,
                  size: 20,
                  color: isEnrolled ? accent : mutedColor,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(height: 1, thickness: 0.5, color: lineColor),
      ],
    );
  }
}
