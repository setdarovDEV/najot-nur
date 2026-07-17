import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/learning_models.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/order_sheet.dart';

// ---------------------------------------------------------------------------
// Speed and quality option constants
// ---------------------------------------------------------------------------

const _kSpeedOptions = [0.75, 1.0, 1.25, 1.5, 2.0];
const _kQualityOptions = ['360p', '480p', '720p', '1080p'];
const _kDefaultQuality = '720p';

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

// ---------------------------------------------------------------------------
// CourseDetailScreen — Liquid Glass mockup "2b": gradient hero with frosted
// meta chips, glass lesson list, and a floating price + CTA bar pinned over
// the scrolling content.
// ---------------------------------------------------------------------------

class CourseDetailScreen extends ConsumerStatefulWidget {
  const CourseDetailScreen({super.key, required this.courseId});
  final String courseId;

  @override
  ConsumerState<CourseDetailScreen> createState() =>
      _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen> {
  final _scrollOffset = ValueNotifier<double>(0);

  @override
  void dispose() {
    _scrollOffset.dispose();
    super.dispose();
  }

  void _onBuyPressed(BuildContext context, Course c) {
    if (c.isFree) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).startCourse)),
      );
      return;
    }
    showOrderRequestSheet(
      context,
      purpose: OrderPurpose.course,
      targetId: c.id,
      targetTitle: c.title,
      amount: c.price,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final course = ref.watch(courseDetailProvider(widget.courseId));
    final progressAsync = ref.watch(courseProgressProvider(widget.courseId));

    // Kurs sotib olingan bo'lsa — reklam sahifasini o'tkazib, to'g'ridan-to'g'ri
    // o'rganish ekraniga yuborish.
    ref.listen(courseProgressProvider(widget.courseId), (_, next) {
      next.whenData((p) {
        if (p.enrolled && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.replace('/courses/${widget.courseId}/learn');
            }
          });
        }
      });
    });

    final progress = progressAsync.valueOrNull;
    final isEnrolled = progress?.enrolled ?? false;
    final hasPendingOrder = progress?.hasPendingOrder ?? false;

    return Scaffold(
      body: course.when(
        loading: () => const AppLoader(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () =>
              ref.invalidate(courseDetailProvider(widget.courseId)),
        ),
        data: (c) => Stack(
          children: [
            const AmbientOrbs(),
            NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.axis == Axis.vertical) {
                  _scrollOffset.value = n.metrics.pixels;
                }
                return false;
              },
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CourseHero(course: c),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 170),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (c.coverUrl != null) ...[
                            GlassEntrance(
                              delay: GlassMotion.entranceStep,
                              child: _CoverBlock(coverUrl: c.coverUrl!),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (isEnrolled) ...[
                            GlassEntrance(
                              delay: GlassMotion.entranceStep,
                              child: _EnrolledBanner(
                                label: l.courseInProgress,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ] else if (hasPendingOrder) ...[
                            GlassEntrance(
                              delay: GlassMotion.entranceStep,
                              child: _PendingOrderBanner(
                                onViewOrders: () =>
                                    context.push('/profile/orders'),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (c.description != null) ...[
                            GlassEntrance(
                              delay: GlassMotion.entranceStep * 2,
                              child: _DescriptionCard(
                                  description: c.description!),
                            ),
                            const SizedBox(height: 12),
                          ],
                          _SectionTitle(l.lessonsCount(c.lessons.length)),
                          const SizedBox(height: 12),
                          GlassEntrance(
                            delay: GlassMotion.entranceStep * 3,
                            child: _LessonsCard(
                              lessons: c.lessons,
                              courseId: c.id,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: GlassTopChrome(offset: _scrollOffset, title: c.title),
            ),
            // Floating back button over the hero.
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              child: _GlassBackButton(onTap: () => context.pop()),
            ),
            // Sticky price + CTA bar.
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 14,
              child: _BottomCta(
                course: c,
                isEnrolled: isEnrolled,
                hasPendingOrder: hasPendingOrder,
                onBuy: () => _onBuyPressed(context, c),
                onContinue: () =>
                    context.push('/courses/${widget.courseId}/learn'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── Hero ─────────────────────────

class _CourseHero extends StatelessWidget {
  const _CourseHero({required this.course});
  final Course course;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final topInset = MediaQuery.of(context).padding.top;
    final totalMins = (course.lessons
                .fold<int>(0, (sum, ls) => sum + ls.durationSec) /
            60)
        .round();

    return GlassEntrance(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(20, topInset + 52, 20, 26),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.58, 1.0],
            colors: [AppColors.wine, AppColors.wineDark, AppColors.wineDeep],
          ),
          borderRadius:
              BorderRadius.vertical(bottom: Radius.circular(32)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.videoLessons.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              course.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _HeroChip(_levelLabel(l, course.level)),
                if (course.lessons.isNotEmpty)
                  _HeroChip(
                    totalMins > 0
                        ? '${l.lessonsShort(course.lessons.length)} · ${l.minutesShort(totalMins)}'
                        : l.lessonsShort(course.lessons.length),
                  ),
                _HeroChip(
                  course.isFree
                      ? l.free
                      : l.sumPrice(course.price.toStringAsFixed(0)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.30),
          width: 0.5,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _GlassBackButton extends StatelessWidget {
  const _GlassBackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassPressable(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 0.5,
          ),
        ),
        child: const Icon(Icons.arrow_back_rounded,
            color: Colors.white, size: 20),
      ),
    );
  }
}

// ───────────────────────── Content blocks ─────────────────────────

class _CoverBlock extends ConsumerWidget {
  const _CoverBlock({required this.coverUrl});
  final String coverUrl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.read(apiClientProvider).resolveMediaUrl(coverUrl);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppColors.radiusCard),
      child: SizedBox(
        height: 140,
        width: double.infinity,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: AppColors.wine.withValues(alpha: 0.08),
            alignment: Alignment.center,
            child: Icon(
              Icons.play_circle_outline_rounded,
              size: 44,
              color: AppColors.wine.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: dark ? AppColors.inkDarkPrimary : AppColors.ink,
        ),
      ),
    );
  }
}

class _DescriptionCard extends StatelessWidget {
  const _DescriptionCard({required this.description});
  final String description;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GlassContainer(
      borderRadius: AppColors.radiusTariffCard,
      padding: const EdgeInsets.all(16),
      child: Text(
        description,
        style: TextStyle(
          height: 1.5,
          fontSize: 13.5,
          color: dark
              ? AppColors.inkDarkPrimary.withValues(alpha: 0.78)
              : AppColors.inkSoft,
        ),
      ),
    );
  }
}

class _EnrolledBanner extends StatelessWidget {
  const _EnrolledBanner({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: AppColors.radiusTariffCard,
      withShadow: false,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lessons card — one glass surface, hairline-separated rows (mockup 2b).
// Rows still expand to the speed/quality selectors from the old screen.
// ---------------------------------------------------------------------------

class _LessonsCard extends StatelessWidget {
  const _LessonsCard({required this.lessons, required this.courseId});
  final List<Lesson> lessons;
  final String courseId;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          for (var i = 0; i < lessons.length; i++)
            _LessonTile(
              index: i + 1,
              lesson: lessons[i],
              courseId: courseId,
              isLast: i == lessons.length - 1,
            ),
        ],
      ),
    );
  }
}

class _LessonTile extends StatefulWidget {
  const _LessonTile({
    required this.index,
    required this.lesson,
    required this.courseId,
    required this.isLast,
  });
  final int index;
  final Lesson lesson;
  final String courseId;
  final bool isLast;

  @override
  State<_LessonTile> createState() => _LessonTileState();
}

class _LessonTileState extends State<_LessonTile> {
  double _selectedSpeed = 1.0;
  String _selectedQuality = _kDefaultQuality;
  bool _expanded = false;

  String _speedLabel(double speed) {
    if (speed == speed.truncateToDouble()) {
      return '${speed.toInt()}.0x';
    }
    return '${speed}x';
  }

  void _openDemoLesson(BuildContext context) {
    context.push(
      '/courses/${widget.courseId}/lessons/${widget.lesson.id}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final lineColor = dark ? AppColors.lineDark : AppColors.line;
    final accent = dark ? AppColors.wine300 : AppColors.wine;
    final mins = (widget.lesson.durationSec / 60).round();
    final isDemo = widget.lesson.isDemo;

    return Column(
      children: [
        InkWell(
          onTap: isDemo
              ? () => _openDemoLesson(context)
              : () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDemo
                        ? AppColors.orange.withValues(alpha: 0.14)
                        : (dark
                            ? AppColors.wine300.withValues(alpha: 0.16)
                            : AppColors.wine100),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: isDemo
                        ? const Icon(Icons.play_arrow_rounded,
                            color: AppColors.orange, size: 20)
                        : Text(
                            '${widget.index}',
                            style: TextStyle(
                              color: dark ? AppColors.wine300 : AppColors.wine,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.lesson.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          l.minutesShort(mins),
                          if (widget.lesson.isVoiceExercise) l.aiExercise,
                          if (isDemo) l.demoLabel,
                        ].join(' · '),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDemo ? AppColors.orange : mutedColor,
                          fontWeight: isDemo ? FontWeight.w800 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isDemo
                      ? Icons.play_circle_outline_rounded
                      : (_expanded
                          ? Icons.expand_less_rounded
                          : Icons.lock_outline_rounded),
                  color: isDemo ? accent : mutedColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (_expanded && !isDemo)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.speedLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: mutedColor,
                  ),
                ),
                const SizedBox(height: 8),
                _OptionPills<double>(
                  selected: _selectedSpeed,
                  options: _kSpeedOptions,
                  labelBuilder: _speedLabel,
                  onSelected: (v) => setState(() => _selectedSpeed = v),
                ),
                const SizedBox(height: 14),
                Text(
                  l.qualityLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: mutedColor,
                  ),
                ),
                const SizedBox(height: 8),
                _OptionPills<String>(
                  selected: _selectedQuality,
                  options: _kQualityOptions,
                  labelBuilder: (q) => q,
                  onSelected: (q) {
                    setState(() => _selectedQuality = q);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.qualityChanged(q))),
                    );
                  },
                ),
              ],
            ),
          ),
        if (!widget.isLast)
          Divider(height: 1, thickness: 0.5, color: lineColor),
      ],
    );
  }
}

class _OptionPills<T> extends StatelessWidget {
  const _OptionPills({
    required this.selected,
    required this.options,
    required this.labelBuilder,
    required this.onSelected,
  });

  final T selected;
  final List<T> options;
  final String Function(T) labelBuilder;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? AppColors.wine300 : AppColors.wine;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((option) {
          final isActive = option == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive ? AppColors.wine : Colors.transparent,
                  border: Border.all(color: accent, width: 1.5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  labelBuilder(option),
                  style: TextStyle(
                    color: isActive ? Colors.white : accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ───────────────────────── Bottom CTA ─────────────────────────

class _BottomCta extends StatelessWidget {
  const _BottomCta({
    required this.course,
    required this.isEnrolled,
    required this.hasPendingOrder,
    required this.onBuy,
    required this.onContinue,
  });

  final Course course;
  final bool isEnrolled;
  final bool hasPendingOrder;
  final VoidCallback onBuy;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;

    if (hasPendingOrder) return const SizedBox.shrink();

    final ctaLabel = isEnrolled
        ? l.continueCourse
        : (course.isFree ? l.startCourse : l.buy);
    final onTap = isEnrolled ? onContinue : onBuy;

    return Row(
      children: [
        if (!isEnrolled && !course.isFree) ...[
          GlassContainer(
            tier: GlassTier.chrome,
            borderRadius: AppColors.radiusButton,
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.priceLabel.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: mutedColor,
                  ),
                ),
                Text(
                  course.price.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: GlassPressable(
            onTap: onTap,
            child: Container(
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppColors.wineGradient,
                borderRadius:
                    BorderRadius.circular(AppColors.radiusButton),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.wine.withValues(alpha: 0.35),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Text(
                ctaLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PendingOrderBanner extends StatelessWidget {
  const _PendingOrderBanner({required this.onViewOrders});
  final VoidCallback onViewOrders;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return GlassContainer(
      borderRadius: AppColors.radiusTariffCard,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.hourglass_top_rounded,
                  color: AppColors.warning, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'So\'rovingiz ko\'rib chiqilmoqda',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Naqd to\'lov so\'rovingiz admin tomonidan ko\'rib chiqilmoqda. Tasdiqlangandan so\'ng kursga avtomatik kirish beriladi.',
            style: TextStyle(
              fontSize: 13,
              color: dark
                  ? AppColors.inkDarkPrimary.withValues(alpha: 0.78)
                  : AppColors.inkSoft,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onViewOrders,
            child: Text(
              'Buyurtmalarimni ko\'rish →',
              style: TextStyle(
                color: dark ? AppColors.wine300 : AppColors.wine,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
