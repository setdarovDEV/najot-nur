import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/learning_models.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/common.dart';

class CourseLearningScreen extends ConsumerWidget {
  const CourseLearningScreen({super.key, required this.courseId});
  final String courseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final courseAsync = ref.watch(courseDetailProvider(courseId));
    final progressAsync = ref.watch(courseProgressProvider(courseId));

    return Scaffold(
      body: courseAsync.when(
        loading: () => const AppLoader(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () {
            ref.invalidate(courseDetailProvider(courseId));
            ref.invalidate(courseProgressProvider(courseId));
          },
        ),
        data: (course) => progressAsync.when(
          loading: () => const AppLoader(),
          error: (e, _) => ErrorView(message: e.toString()),
          data: (progress) => CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                foregroundColor: Colors.white,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    course.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: AppColors.heroGradient,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.school_rounded,
                        color: Colors.white24,
                        size: 72,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Progress bar ──
              if (progress.enrolled)
                SliverToBoxAdapter(
                  child: _ProgressHeader(progress: progress, l: l),
                ),

              // ── Lessons list ──
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) {
                      final enrolled = progress.enrolled &&
                          progress.lessons.isNotEmpty;
                      final ep = enrolled
                          ? progress.lessons
                              .where((l) =>
                                  l.lessonId == course.lessons[i].id)
                              .firstOrNull
                          : null;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _LessonTile(
                          index: i + 1,
                          lesson: course.lessons[i],
                          isCompleted: ep?.isCompleted ?? false,
                          autoScore: ep?.autoScore,
                          isEnrolled: progress.enrolled,
                          onTap: progress.enrolled
                              ? () => context.push(
                                    '/courses/$courseId/lessons/${course.lessons[i].id}',
                                  )
                              : null,
                        ),
                      );
                    },
                    childCount: course.lessons.length,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.progress, required this.l});
  final CourseProgress progress;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final pct = progress.progressPct ?? 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.wine.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.wine.withValues(alpha: 0.2)),
      ),
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
                    fontWeight: FontWeight.w700,
                    color: progress.isCompleted
                        ? const Color(0xFF16A34A)
                        : AppColors.wine,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                '$pct%',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.wine,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct / 100,
              backgroundColor: AppColors.wine.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.wine),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.lessonsCompleted(
              progress.lessons.where((l) => l.isCompleted).length,
              progress.lessons.length,
            ),
            style: const TextStyle(color: AppColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.index,
    required this.lesson,
    required this.isCompleted,
    required this.isEnrolled,
    this.autoScore,
    this.onTap,
  });
  final int index;
  final Lesson lesson;
  final bool isCompleted;
  final bool isEnrolled;
  final int? autoScore;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final mins = (lesson.durationSec / 60).round();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isCompleted
              ? const Color(0xFFF0FDF4)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted
                ? const Color(0xFF86EFAC)
                : AppColors.line,
          ),
        ),
        child: Row(
          children: [
            // Index badge / check icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isCompleted
                    ? const Color(0xFF16A34A)
                    : isEnrolled
                        ? AppColors.wine100
                        : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 22,
                      )
                    : Text(
                        '$index',
                        style: TextStyle(
                          color: isEnrolled
                              ? AppColors.wine
                              : AppColors.muted,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Lesson info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isEnrolled
                          ? AppColors.ink
                          : AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 13,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l.minutesShort(mins),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                      if (lesson.isVoiceExercise) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.blue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            l.aiExercise,
                            style: const TextStyle(
                              color: AppColors.blue,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      if (isCompleted && autoScore != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${autoScore}%',
                            style: const TextStyle(
                              color: Color(0xFF16A34A),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Arrow / lock
            Icon(
              isEnrolled
                  ? Icons.chevron_right_rounded
                  : Icons.lock_outline_rounded,
              color: isEnrolled ? AppColors.wine : AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}
