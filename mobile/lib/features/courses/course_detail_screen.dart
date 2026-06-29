import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
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

// ---------------------------------------------------------------------------
// CourseDetailScreen
// ---------------------------------------------------------------------------

class CourseDetailScreen extends ConsumerStatefulWidget {
  const CourseDetailScreen({super.key, required this.courseId});
  final String courseId;

  @override
  ConsumerState<CourseDetailScreen> createState() =>
      _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen> {
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
        data: (c) => CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(c.title,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                background: Container(
                  decoration: const BoxDecoration(
                      gradient: AppColors.heroGradient),
                  child: const Center(
                    child: Icon(Icons.play_circle_fill_rounded,
                        color: Colors.white24, size: 80),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        PillTag(c.level),
                        const SizedBox(width: 8),
                        PillTag(
                          c.isFree
                              ? l.free
                              : l.sumPrice(c.price.toStringAsFixed(0)),
                          color: AppColors.orange,
                        ),
                        if (isEnrolled) ...[
                          const SizedBox(width: 8),
                          PillTag(l.courseInProgress, color: const Color(0xFF16A34A)),
                        ],
                      ],
                    ),
                    if (c.description != null) ...[
                      const SizedBox(height: 16),
                      Text(c.description!,
                          style: const TextStyle(
                              height: 1.5, color: AppColors.inkSoft)),
                    ],
                    const SizedBox(height: 20),
                    if (isEnrolled)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              context.push('/courses/${widget.courseId}/learn'),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: Text(l.continueCourse),
                        ),
                      )
                    else if (hasPendingOrder)
                      _PendingOrderBanner(
                        onViewOrders: () => context.push('/profile/orders'),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _onBuyPressed(context, c),
                          icon: Icon(c.isFree
                              ? Icons.play_arrow_rounded
                              : Icons.lock_open_rounded),
                          label: Text(c.isFree ? l.startCourse : l.buy),
                        ),
                      ),
                    const SizedBox(height: 24),
                    Text(l.lessonsCount(c.lessons.length),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 12),
                    ...c.lessons.asMap().entries.map(
                          (e) =>
                              _LessonTile(index: e.key + 1, lesson: e.value),
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lesson tile with speed + quality selectors
// ---------------------------------------------------------------------------

class _LessonTile extends StatefulWidget {
  const _LessonTile({required this.index, required this.lesson});
  final int index;
  final Lesson lesson;

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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final mins = (widget.lesson.durationSec / 60).round();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.wine100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text('${widget.index}',
                          style: const TextStyle(
                              color: AppColors.wine,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.lesson.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.schedule_rounded,
                                size: 14, color: AppColors.muted),
                            const SizedBox(width: 4),
                            Text(l.minutesShort(mins),
                                style: const TextStyle(
                                    color: AppColors.muted, fontSize: 12)),
                            if (widget.lesson.isVoiceExercise) ...[
                              const SizedBox(width: 8),
                              PillTag(l.aiExercise,
                                  color: AppColors.blue),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less_rounded
                        : Icons.lock_outline_rounded,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.line),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.speedLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SpeedSelector(
                    selected: _selectedSpeed,
                    options: _kSpeedOptions,
                    labelBuilder: _speedLabel,
                    onSelected: (v) =>
                        setState(() => _selectedSpeed = v),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l.qualityLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _QualitySelector(
                    selected: _selectedQuality,
                    options: _kQualityOptions,
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
          ],
        ],
      ),
    );
  }
}

class _SpeedSelector extends StatelessWidget {
  const _SpeedSelector({
    required this.selected,
    required this.options,
    required this.labelBuilder,
    required this.onSelected,
  });

  final double selected;
  final List<double> options;
  final String Function(double) labelBuilder;
  final ValueChanged<double> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((speed) {
        final isActive = speed == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onSelected(speed),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? AppColors.wine : Colors.transparent,
                border: Border.all(
                  color: AppColors.wine,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                labelBuilder(speed),
                style: TextStyle(
                  color: isActive ? Colors.white : AppColors.wine,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PendingOrderBanner extends StatelessWidget {
  const _PendingOrderBanner({required this.onViewOrders});
  final VoidCallback onViewOrders;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hourglass_top_rounded,
                  color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              const Text(
                'So\'rovingiz ko\'rib chiqilmoqda',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Naqd to\'lov so\'rovingiz admin tomonidan ko\'rib chiqilmoqda. Tasdiqlangandan so\'ng kursga avtomatik kirish beriladi.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.inkSoft,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onViewOrders,
            child: const Text(
              'Buyurtmalarimni ko\'rish →',
              style: TextStyle(
                color: AppColors.wine,
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

class _QualitySelector extends StatelessWidget {
  const _QualitySelector({
    required this.selected,
    required this.options,
    required this.onSelected,
  });

  final String selected;
  final List<String> options;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((quality) {
        final isActive = quality == selected;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onSelected(quality),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? AppColors.wine : Colors.transparent,
                border: Border.all(
                  color: AppColors.wine,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                quality,
                style: TextStyle(
                  color: isActive ? Colors.white : AppColors.wine,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
