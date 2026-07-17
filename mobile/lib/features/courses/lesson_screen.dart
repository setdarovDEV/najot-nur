import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/learning_models.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/secure_screen.dart';
import '../../shared/widgets/voice_recorder.dart';

/// Lesson screen, Liquid Glass mockup "6b": dark gradient video block with a
/// frosted play button and glass chrome, a glass segmented tab picker and
/// glass cards for description/quiz/homework. Video opening, lesson
/// completion, quiz submission and homework logic are unchanged.
class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({
    super.key,
    required this.courseId,
    required this.lessonId,
  });
  final String courseId;
  final String lessonId;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _openVideo(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).videoOpenError),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lessonAsync = ref.watch(lessonDetailProvider(widget.lessonId));
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final topInset = MediaQuery.of(context).padding.top;

    // Paid video content — screenshots/recording blocked only here.
    return SecureScreen(
        child: Scaffold(
      body: Stack(
        children: [
          const AmbientOrbs(),
          Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, topInset + 12, 16, 0),
                child: Column(
                  children: [
                    GlassEntrance(
                      child: Row(
                        children: [
                          _GlassIconButton(
                            icon: Icons.arrow_back_rounded,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          Expanded(
                            child: Text(
                              lessonAsync.maybeWhen(
                                data: (ls) => ls.title,
                                orElse: () => l.lesson,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                            ),
                          ),
                          // Balance the back button so the title stays centered.
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassEntrance(
                      delay: GlassMotion.entranceStep,
                      child: _SegmentPicker(
                        labels: [
                          l.lessonTabVideo,
                          l.lessonTabQuiz,
                          l.lessonTabHomework,
                        ],
                        index: _tabs.index,
                        onSelect: (i) => _tabs.animateTo(i),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: lessonAsync.when(
                  loading: () => const AppLoader(),
                  error: (e, _) => ErrorView(
                    message: e.toString(),
                    onRetry: () =>
                        ref.invalidate(lessonDetailProvider(widget.lessonId)),
                  ),
                  data: (lesson) => TabBarView(
                    controller: _tabs,
                    children: [
                      // ── Tab 1: Video + Description ──
                      _VideoTab(
                        lesson: lesson,
                        courseId: widget.courseId,
                        onOpenVideo: _openVideo,
                        onComplete: () async {
                          await ref
                              .read(learningRepositoryProvider)
                              .completeLesson(widget.lessonId);
                          ref.invalidate(
                              lessonDetailProvider(widget.lessonId));
                          ref.invalidate(
                              courseProgressProvider(widget.courseId));
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l.lessonCompleted)),
                            );
                          }
                        },
                      ),

                      // ── Tab 2: Quiz ──
                      lesson.hasQuiz
                          ? _QuizTab(
                              lesson: lesson,
                              courseId: widget.courseId,
                              lessonId: widget.lessonId,
                            )
                          : EmptyView(
                              icon: Icons.quiz_outlined,
                              message: l.noQuizForLesson,
                            ),

                      // ── Tab 3: Homework ──
                      _HomeworkTab(
                        lessonId: widget.lessonId,
                        courseId: widget.courseId,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ));
  }
}

// ═══════════════════════════════════════════════════
// Shared bits
// ═══════════════════════════════════════════════════

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onTap});
  final IconData icon;
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
          icon,
          size: 20,
          color: dark ? AppColors.inkDarkPrimary : AppColors.ink,
        ),
      ),
    );
  }
}

/// Glass segmented picker with a morphing gradient indicator
/// (order_sheet.dart idiom).
class _SegmentPicker extends StatelessWidget {
  const _SegmentPicker({
    required this.labels,
    required this.index,
    required this.onSelect,
  });
  final List<String> labels;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;

    return GlassContainer(
      borderRadius: AppColors.radiusButton,
      withShadow: false,
      padding: const EdgeInsets.all(4),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segWidth = constraints.maxWidth / labels.length;
          return SizedBox(
            height: 38,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: GlassMotion.tabMorph,
                  curve: GlassMotion.tabMorphCurve,
                  left: segWidth * index,
                  top: 0,
                  bottom: 0,
                  width: segWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.wineGradient,
                      borderRadius:
                          BorderRadius.circular(AppColors.radiusSegment),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.wine.withValues(alpha: 0.30),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < labels.length; i++)
                      Expanded(
                        child: GlassPressable(
                          onTap: () => onSelect(i),
                          child: Container(
                            height: 38,
                            alignment: Alignment.center,
                            color: Colors.transparent,
                            child: AnimatedDefaultTextStyle(
                              duration: GlassMotion.tabMorph,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color:
                                    i == index ? Colors.white : mutedColor,
                              ),
                              child: Text(labels[i]),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.label,
    required this.onTap,
    this.icon,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return GlassPressable(
      onTap: loading ? null : onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Container(
          height: 54,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppColors.wineGradient,
            borderRadius: BorderRadius.circular(AppColors.radiusButton),
            boxShadow: [
              BoxShadow(
                color: AppColors.wine.withValues(alpha: 0.30),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Tab 1 — Video & description (mockup 6b)
// ═══════════════════════════════════════════════════

class _VideoTab extends ConsumerWidget {
  const _VideoTab({
    required this.lesson,
    required this.courseId,
    required this.onOpenVideo,
    required this.onComplete,
  });
  final LessonDetail lesson;
  final String courseId;
  final Future<void> Function(String) onOpenVideo;
  final Future<void> Function() onComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final bodyColor = dark
        ? AppColors.inkDarkPrimary.withValues(alpha: 0.78)
        : AppColors.inkSoft;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          16, 14, 16, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Video block: dark gradient frame + frosted play button (6b).
          if (lesson.videoUrl != null)
            GlassEntrance(
              child: GlassPressable(
                onTap: () => onOpenVideo(lesson.videoUrl!),
                child: Container(
                  height: 220,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.ink, AppColors.wineDeep],
                    ),
                    borderRadius:
                        BorderRadius.circular(AppColors.radiusTariffCard),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 0.5,
                          ),
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 32),
                      ),
                      // Frosted chrome bar (glass pill, mockup 6b).
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius:
                                BorderRadius.circular(AppColors.radiusSegment),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.28),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.videocam_rounded,
                                  color: Colors.white, size: 15),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  l.tapToWatch,
                                  style: TextStyle(
                                    color:
                                        Colors.white.withValues(alpha: 0.85),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Icon(Icons.open_in_new_rounded,
                                  color: Colors.white, size: 15),
                            ],
                          ),
                        ),
                      ),
                      if (lesson.isCompleted)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  l.completed,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            )
          else
            GlassEntrance(
              child: GlassContainer(
                borderRadius: AppColors.radiusTariffCard,
                height: 120,
                withShadow: false,
                alignment: Alignment.center,
                child: Text(
                  l.noVideoForLesson,
                  style: TextStyle(color: mutedColor, fontSize: 14),
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Description card
          if (lesson.description != null &&
              lesson.description!.isNotEmpty) ...[
            GlassEntrance(
              delay: GlassMotion.entranceStep,
              child: GlassContainer(
                borderRadius: AppColors.radiusTariffCard,
                withShadow: false,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.lessonDescription,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: mutedColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lesson.description!,
                      style: TextStyle(
                        height: 1.6,
                        fontSize: 13.5,
                        color: bodyColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Voice exercise note
          if (lesson.isVoiceExercise &&
              lesson.voiceExercisePrompt != null) ...[
            GlassEntrance(
              delay: GlassMotion.entranceStep * 2,
              child: GlassContainer(
                borderRadius: AppColors.radiusTariffCard,
                withShadow: false,
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.blue.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.mic_rounded,
                          color: AppColors.blue, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.aiExercise,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.blue,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lesson.voiceExercisePrompt!,
                            style: TextStyle(
                              color: bodyColor,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Mark as complete button (if no quiz and not yet completed)
          if (!lesson.hasQuiz && !lesson.isCompleted)
            GlassEntrance(
              delay: GlassMotion.entranceStep * 3,
              child: _PrimaryCta(
                label: l.markAsComplete,
                icon: Icons.check_circle_outline_rounded,
                onTap: onComplete,
              ),
            ),

          if (lesson.isCompleted)
            GlassEntrance(
              delay: GlassMotion.entranceStep * 3,
              child: GlassContainer(
                borderRadius: AppColors.radiusTariffCard,
                withShadow: false,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        lesson.autoScore != null
                            ? l.lessonCompletedWithScore(lesson.autoScore!)
                            : l.lessonCompleted,
                        style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Tab 2 — Quiz
// ═══════════════════════════════════════════════════

class _QuizTab extends ConsumerStatefulWidget {
  const _QuizTab({
    required this.lesson,
    required this.courseId,
    required this.lessonId,
  });
  final LessonDetail lesson;
  final String courseId;
  final String lessonId;

  @override
  ConsumerState<_QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends ConsumerState<_QuizTab> {
  final Map<String, int> _answers = {};
  Map<String, int>? _result;
  bool _submitting = false;
  String? _error;

  Future<void> _submit() async {
    if (_answers.length < widget.lesson.questions.length) {
      setState(() => _error = AppLocalizations.of(context).quizAnswerAll);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result =
          await ref.read(learningRepositoryProvider).submitLessonQuiz(
                lessonId: widget.lessonId,
                answers: _answers,
              );
      setState(() => _result = result);
      ref.invalidate(lessonDetailProvider(widget.lessonId));
      ref.invalidate(courseProgressProvider(widget.courseId));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;

    if (_result != null) {
      return _QuizResult(result: _result!, l: l);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          16, 14, 16, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassEntrance(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.quizLessonTitle,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                Text(
                  l.quizLessonSubtitle(widget.lesson.questions.length),
                  style: TextStyle(color: mutedColor, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...widget.lesson.questions.asMap().entries.map((entry) {
            final qi = entry.key;
            final q = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassEntrance(
                delay: GlassMotion.entranceStep * (1 + qi),
                child: _QuestionCard(
                  index: qi + 1,
                  question: q,
                  selected: _answers[q.id],
                  onSelect: (idx) => setState(() => _answers[q.id] = idx),
                ),
              ),
            );
          }),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                style:
                    const TextStyle(color: AppColors.danger, fontSize: 13),
              ),
            ),
          _PrimaryCta(
            label: l.submitQuiz,
            loading: _submitting,
            onTap: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.question,
    required this.selected,
    required this.onSelect,
  });
  final int index;
  final LessonQuizQuestion question;
  final int? selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;

    return GlassContainer(
      borderRadius: AppColors.radiusTariffCard,
      withShadow: false,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$index. ${question.question}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              height: 1.4,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          ...question.options.asMap().entries.map((opt) {
            final isSelected = selected == opt.key;
            final accent = dark ? AppColors.wine300 : AppColors.wine;
            return GestureDetector(
              onTap: () => onSelect(opt.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.wine.withValues(alpha: dark ? 0.20 : 0.08)
                      : Colors.transparent,
                  borderRadius:
                      BorderRadius.circular(AppColors.radiusSegment),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.wine
                        : (dark
                            ? AppColors.glassStrokeDark
                            : AppColors.glassStrokeLight),
                    width: isSelected ? 1.5 : 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.wine
                            : (dark
                                ? AppColors.wine300.withValues(alpha: 0.16)
                                : AppColors.wine.withValues(alpha: 0.10)),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        String.fromCharCode(65 + opt.key),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        opt.value,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 13.5,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _QuizResult extends StatelessWidget {
  const _QuizResult({required this.result, required this.l});
  final Map<String, int> result;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final score = result['score'] ?? 0;
    final passed = (result['passed'] ?? 0) == 1;
    final correct = result['correct'] ?? 0;
    final total = result['total'] ?? 0;
    final color = passed ? AppColors.success : AppColors.danger;
    final icon = passed ? Icons.emoji_events_rounded : Icons.replay_rounded;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassEntrance(
          child: GlassContainer(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.12),
                    border: Border.all(
                      color: color.withValues(alpha: 0.35),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(icon, color: color, size: 44),
                ),
                const SizedBox(height: 18),
                Text(
                  '$score%',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  passed ? l.quizPassed : l.quizFailed,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.quizCorrectCount(correct, total),
                  style: TextStyle(color: mutedColor, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Tab 3 — Homework
// ═══════════════════════════════════════════════════

class _HomeworkTab extends ConsumerStatefulWidget {
  const _HomeworkTab({required this.lessonId, required this.courseId});
  final String lessonId;
  final String courseId;

  @override
  ConsumerState<_HomeworkTab> createState() => _HomeworkTabState();
}

class _HomeworkTabState extends ConsumerState<_HomeworkTab> {
  final _textCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;
  bool _editing = false;
  bool _useVoice = false; // toggle: text vs voice submission

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      setState(() => _error = AppLocalizations.of(context).homeworkEmpty);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(learningRepositoryProvider).submitHomework(
            lessonId: widget.lessonId,
            submissionText: text,
          );
      ref.invalidate(lessonHomeworkProvider(widget.lessonId));
      setState(() => _editing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).homeworkSubmitted),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _submitVoice(String filePath) async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      // Upload the audio file first to get a real server URL, then send it
      // alongside (or instead of) the previously submitted text.
      final audioUrl =
          await ref.read(learningRepositoryProvider).uploadHomeworkAudio(
                lessonId: widget.lessonId,
                filePath: filePath,
              );
      await ref.read(learningRepositoryProvider).submitHomework(
            lessonId: widget.lessonId,
            submissionUrl: audioUrl,
          );
      ref.invalidate(lessonHomeworkProvider(widget.lessonId));
      if (mounted) {
        setState(() => _editing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ovozli uyga vazifa yuborildi!'),
            backgroundColor: AppColors.wine,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final hwAsync = ref.watch(lessonHomeworkProvider(widget.lessonId));
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;

    return hwAsync.when(
      loading: () => const AppLoader(),
      error: (e, _) => ErrorView(message: e.toString()),
      data: (hw) {
        if (hw != null && !_editing) {
          return _HomeworkResult(
            hw: hw,
            l: l,
            onResubmit: () {
              _textCtrl.text = hw.submissionText ?? '';
              setState(() => _editing = true);
            },
          );
        }

        // Submission form
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              16, 14, 16, MediaQuery.of(context).padding.bottom + 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassEntrance(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.homeworkTitle,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l.homeworkSubtitle,
                      style: TextStyle(
                        color: mutedColor,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Toggle: Text or Voice
              GlassEntrance(
                delay: GlassMotion.entranceStep,
                child: _SegmentPicker(
                  labels: const ['Matn', 'Ovoz'],
                  index: _useVoice ? 1 : 0,
                  onSelect: (i) => setState(() => _useVoice = i == 1),
                ),
              ),
              const SizedBox(height: 14),

              if (_useVoice)
                VoiceRecorder(
                  onSubmit: _submitVoice,
                  referenceText: null,
                )
              else ...[
                GlassEntrance(
                  delay: GlassMotion.entranceStep * 2,
                  child: GlassContainer(
                    borderRadius: AppColors.radiusTariffCard,
                    withShadow: false,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    child: TextField(
                      controller: _textCtrl,
                      maxLines: 8,
                      minLines: 4,
                      style: TextStyle(fontSize: 13.5, color: textColor),
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        fillColor: Colors.transparent,
                        filled: false,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 10),
                        hintText: l.homeworkHint,
                        hintStyle:
                            TextStyle(fontSize: 13.5, color: mutedColor),
                      ),
                    ),
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: const TextStyle(
                        color: AppColors.danger, fontSize: 13),
                  ),
                ],

                const SizedBox(height: 14),

                GlassEntrance(
                  delay: GlassMotion.entranceStep * 3,
                  child: _PrimaryCta(
                    label: _submitting ? l.sending : l.homeworkSend,
                    icon: _submitting ? null : Icons.send_rounded,
                    loading: _submitting,
                    onTap: _submitting ? null : _submit,
                  ),
                ),

                if (_editing) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => setState(() => _editing = false),
                    child: Text(
                      l.cancel,
                      style: TextStyle(color: mutedColor),
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

class _HomeworkResult extends StatelessWidget {
  const _HomeworkResult({
    required this.hw,
    required this.l,
    required this.onResubmit,
  });
  final HomeworkSubmission hw;
  final AppLocalizations l;
  final VoidCallback onResubmit;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final bodyColor = dark
        ? AppColors.inkDarkPrimary.withValues(alpha: 0.78)
        : AppColors.inkSoft;
    final isReviewed = hw.isReviewed;
    final statusColor = isReviewed ? AppColors.success : AppColors.warning;
    final statusLabel = isReviewed ? l.homeworkReviewed : l.homeworkPending;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          16, 14, 16, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status banner
          GlassEntrance(
            child: GlassContainer(
              borderRadius: AppColors.radiusTariffCard,
              withShadow: false,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    isReviewed
                        ? Icons.check_circle_rounded
                        : Icons.hourglass_top_rounded,
                    color: statusColor,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  if (isReviewed && hw.curatorScore != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${hw.curatorScore}/100',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Submitted text
          if (hw.submissionText != null) ...[
            GlassEntrance(
              delay: GlassMotion.entranceStep,
              child: GlassContainer(
                borderRadius: AppColors.radiusTariffCard,
                withShadow: false,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.yourAnswer,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: mutedColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hw.submissionText!,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13.5,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Curator feedback
          if (isReviewed && hw.curatorFeedback != null) ...[
            GlassEntrance(
              delay: GlassMotion.entranceStep * 2,
              child: GlassContainer(
                borderRadius: AppColors.radiusTariffCard,
                withShadow: false,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.curatorFeedback,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      hw.curatorFeedback!,
                      style: TextStyle(
                        color: bodyColor,
                        fontSize: 13.5,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Resubmit button
          GlassEntrance(
            delay: GlassMotion.entranceStep * 3,
            child: GlassPressable(
              onTap: onResubmit,
              child: GlassContainer(
                borderRadius: AppColors.radiusButton,
                height: 50,
                withShadow: false,
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_rounded,
                        size: 18,
                        color: dark ? AppColors.wine300 : AppColors.wine),
                    const SizedBox(width: 8),
                    Text(
                      l.homeworkResubmit,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: dark ? AppColors.wine300 : AppColors.wine,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
