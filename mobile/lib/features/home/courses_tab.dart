import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/learning_models.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/common.dart';

/// Kurs kartasini bosganda to'g'ri marshrutni tanlaydi.
/// Cache da progress ma'lumoti bo'lsa va foydalanuvchi enrolled bo'lsa —
/// reklam sahifasini o'tkazib, bevosita o'rganish ekraniga yuboradi.
void _navigateToCourse(WidgetRef ref, BuildContext context, String courseId) {
  final cached = ref.read(courseProgressProvider(courseId)).valueOrNull;
  if (cached != null && cached.enrolled) {
    context.push('/courses/$courseId/learn');
  } else {
    context.push('/courses/$courseId');
  }
}

String _levelLabel(AppLocalizations l, String level) {
  switch (level) {
    case 'intermediate':
      return l.levelIntermediate;
    case 'advanced':
      return l.levelAdvanced;
    default:
      return l.levelBeginner;
  }
}

/// Courses tab, Liquid Glass mockup "2a": large in-scroll title, glass
/// search field, level filter chips, and glass course cards with a frosted
/// level pill over the cover. Client-side search/filter only — the course
/// list itself still comes from [coursesProvider].
class CoursesTab extends ConsumerStatefulWidget {
  const CoursesTab({super.key});

  @override
  ConsumerState<CoursesTab> createState() => _CoursesTabState();
}

class _CoursesTabState extends ConsumerState<CoursesTab> {
  final _scrollOffset = ValueNotifier<double>(0);
  String _query = '';
  String? _levelFilter; // null = all

  @override
  void dispose() {
    _scrollOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final courses = ref.watch(coursesProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AmbientOrbs(),
          courses.when(
            loading: () => const AppLoader(),
            error: (e, _) => ErrorView(
              message: e.toString(),
              onRetry: () => ref.invalidate(coursesProvider),
            ),
            data: (list) {
              final filtered = list.where((c) {
                final byLevel =
                    _levelFilter == null || c.level == _levelFilter;
                final byQuery = _query.isEmpty ||
                    c.title.toLowerCase().contains(_query.toLowerCase());
                return byLevel && byQuery;
              }).toList();

              return NotificationListener<ScrollNotification>(
                onNotification: (n) {
                  if (n.metrics.axis == Axis.vertical) {
                    _scrollOffset.value = n.metrics.pixels;
                  }
                  return false;
                },
                child: ListView(
                  padding: EdgeInsets.fromLTRB(16, topInset + 18, 16, 150),
                  children: [
                    GlassEntrance(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.videoLessons,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            l.coursesCount(list.length),
                            style:
                                TextStyle(fontSize: 12.5, color: mutedColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassEntrance(
                      delay: GlassMotion.entranceStep,
                      child: _SearchField(
                        hint: l.searchCoursesHint,
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassEntrance(
                      delay: GlassMotion.entranceStep * 2,
                      child: _LevelChips(
                        selected: _levelFilter,
                        onSelect: (lvl) =>
                            setState(() => _levelFilter = lvl),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: EmptyView(
                          icon: Icons.play_circle_outline_rounded,
                          message: l.noCourses,
                        ),
                      )
                    else
                      for (var i = 0; i < filtered.length; i++) ...[
                        GlassEntrance(
                          delay: GlassMotion.entranceStep * (3 + i),
                          child: _CourseCard(course: filtered[i]),
                        ),
                        const SizedBox(height: 12),
                      ],
                  ],
                ),
              );
            },
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child:
                GlassTopChrome(offset: _scrollOffset, title: l.videoLessons),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.hint, required this.onChanged});
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;

    return GlassContainer(
      borderRadius: AppColors.radiusButton,
      height: 48,
      withShadow: false,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.search_rounded, size: 20, color: mutedColor),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: TextStyle(fontSize: 13.5, color: textColor),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                filled: false,
                contentPadding: EdgeInsets.zero,
                hintText: hint,
                hintStyle: TextStyle(fontSize: 13.5, color: mutedColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelChips extends StatelessWidget {
  const _LevelChips({required this.selected, required this.onSelect});
  final String? selected;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final chips = <(String?, String)>[
      (null, l.filterAll),
      ('beginner', l.levelBeginner),
      ('intermediate', l.levelIntermediate),
      ('advanced', l.levelAdvanced),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final (value, label) in chips) ...[
            _FilterChip(
              label: label,
              active: selected == value,
              onTap: () => onSelect(value),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;

    return GlassPressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: GlassMotion.pressOut,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          gradient: active ? AppColors.wineGradient : null,
          color: active
              ? null
              : (dark
                  ? AppColors.glassFillDark
                  : AppColors.glassFillLight),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active
                ? Colors.transparent
                : (dark
                    ? AppColors.glassStrokeDark
                    : AppColors.glassStrokeLight),
            width: 0.5,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: AppColors.wine.withValues(alpha: 0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: active ? Colors.white : mutedColor,
          ),
        ),
      ),
    );
  }
}

class _CourseCard extends ConsumerWidget {
  const _CourseCard({required this.course});
  final Course course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final coverUrl = course.coverUrl == null
        ? null
        : ref.read(apiClientProvider).resolveMediaUrl(course.coverUrl!);

    return GlassPressable(
      onTap: () => _navigateToCourse(ref, context, course.id),
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 112,
                    width: double.infinity,
                    child: coverUrl != null
                        ? Image.network(
                            coverUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const _CoverPlaceholder(),
                          )
                        : const _CoverPlaceholder(),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.7),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      _levelLabel(l, course.level),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.wine,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 12, 6, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (course.lessons.isNotEmpty)
                              l.lessonsShort(course.lessons.length),
                            if (course.lessons
                                .any((ls) => ls.isVoiceExercise))
                              'AI',
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: mutedColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 13, vertical: 8),
                    decoration: BoxDecoration(
                      gradient:
                          course.isFree ? null : AppColors.wineGradient,
                      color: course.isFree
                          ? AppColors.success.withValues(alpha: 0.12)
                          : null,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: course.isFree
                          ? null
                          : [
                              BoxShadow(
                                color:
                                    AppColors.wine.withValues(alpha: 0.30),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ],
                    ),
                    child: Text(
                      course.isFree
                          ? l.free
                          : l.sumPrice(course.price.toStringAsFixed(0)),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color:
                            course.isFree ? AppColors.success : Colors.white,
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

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.wineGradient),
      child: const Center(
        child: Icon(Icons.play_circle_fill_rounded,
            color: Colors.white, size: 44),
      ),
    );
  }
}
