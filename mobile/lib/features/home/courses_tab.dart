import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/learning_models.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/common.dart';

class CoursesTab extends ConsumerWidget {
  const CoursesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final courses = ref.watch(coursesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.videoLessons), titleSpacing: 20),
      body: courses.when(
        loading: () => const AppLoader(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(coursesProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyView(
              icon: Icons.play_circle_outline_rounded,
              message: l.noCourses,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (_, i) => _CourseCard(course: list[i]),
          );
        },
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course});
  final Course course;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () => context.push('/courses/${course.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              decoration: const BoxDecoration(gradient: AppColors.wineGradient),
              child: const Center(
                child: Icon(Icons.play_circle_fill_rounded,
                    color: Colors.white, size: 52),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 17),
                  ),
                  if (course.description != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      course.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      PillTag(course.level),
                      if (course.lessons.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        PillTag(
                          l.lessonsShort(course.lessons.length),
                          color: AppColors.blue,
                        ),
                      ],
                      const Spacer(),
                      Text(
                        course.isFree
                            ? l.free
                            : l.sumPrice(course.price.toStringAsFixed(0)),
                        style: const TextStyle(
                          color: AppColors.wine,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (course.lessons.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 24, color: AppColors.line),
                    for (final ls in course.lessons.take(3))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.wine100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                size: 16,
                                color: AppColors.wine,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                ls.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.inkSoft,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (ls.isVoiceExercise)
                              const PillTag('AI', color: AppColors.blue),
                          ],
                        ),
                      ),
                    if (course.lessons.length > 3)
                      Padding(
                        padding: const EdgeInsets.only(left: 36, top: 2),
                        child: Text(
                          '+ ${l.andMore(course.lessons.length - 3)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
