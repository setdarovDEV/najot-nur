import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/learning_models.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/voice_recorder.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: lessonAsync.maybeWhen(
          data: (ls) => Text(ls.title,
              style: const TextStyle(fontWeight: FontWeight.w800)),
          orElse: () => Text(l.lesson),
        ),
        titleSpacing: 4,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.wine,
          labelColor: AppColors.wine,
          unselectedLabelColor: AppColors.muted,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          tabs: [
            Tab(text: l.lessonTabVideo),
            Tab(text: l.lessonTabQuiz),
            Tab(text: l.lessonTabHomework),
          ],
        ),
      ),
      body: lessonAsync.when(
        loading: () => const AppLoader(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(lessonDetailProvider(widget.lessonId)),
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
                ref.invalidate(lessonDetailProvider(widget.lessonId));
                ref.invalidate(courseProgressProvider(widget.courseId));
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
                : _EmptyTab(
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
    );
  }
}

// ═══════════════════════════════════════════════════
// Tab 1 — Video & description
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Video thumbnail / open button
          if (lesson.videoUrl != null)
            GestureDetector(
              onTap: () => onOpenVideo(lesson.videoUrl!),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.wine, AppColors.wineDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.play_circle_fill_rounded,
                      color: Colors.white,
                      size: 72,
                    ),
                    Positioned(
                      bottom: 12,
                      right: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          l.tapToWatch,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (lesson.isCompleted)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
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
            )
          else
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.wine.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.wine.withValues(alpha: 0.2),
                ),
              ),
              child: Center(
                child: Text(
                  l.noVideoForLesson,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Description
          if (lesson.description != null && lesson.description!.isNotEmpty) ...[
            Text(
              l.lessonDescription,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lesson.description!,
              style: const TextStyle(
                height: 1.6,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Voice exercise note
          if (lesson.isVoiceExercise && lesson.voiceExercisePrompt != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.blue.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.mic_rounded,
                    color: AppColors.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.aiExercise,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.blue,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          lesson.voiceExercisePrompt!,
                          style: const TextStyle(
                            color: AppColors.inkSoft,
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
            const SizedBox(height: 20),
          ],

          // Mark as complete button (if no quiz and not yet completed)
          if (!lesson.hasQuiz && !lesson.isCompleted)
            ElevatedButton.icon(
              onPressed: onComplete,
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: Text(l.markAsComplete),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.wine,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

          if (lesson.isCompleted)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF16A34A),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      lesson.autoScore != null
                          ? l.lessonCompletedWithScore(lesson.autoScore!)
                          : l.lessonCompleted,
                      style: const TextStyle(
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
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
      setState(() =>
          _error = AppLocalizations.of(context).quizAnswerAll);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(learningRepositoryProvider)
          .submitLessonQuiz(
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

    if (_result != null) {
      return _QuizResult(result: _result!, l: l);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l.quizLessonTitle,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            l.quizLessonSubtitle(widget.lesson.questions.length),
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 20),

          ...widget.lesson.questions.asMap().entries.map((entry) {
            final qi = entry.key;
            final q = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _QuestionCard(
                index: qi + 1,
                question: q,
                selected: _answers[q.id],
                onSelect: (idx) =>
                    setState(() => _answers[q.id] = idx),
              ),
            );
          }),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                style: const TextStyle(
                  color: Color(0xFFEF4444),
                  fontSize: 13,
                ),
              ),
            ),

          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.wine,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    l.submitQuiz,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$index. ${question.question}',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 10),
        ...question.options.asMap().entries.map((opt) {
          final isSelected = selected == opt.key;
          return GestureDetector(
            onTap: () => onSelect(opt.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.wine.withValues(alpha: 0.08)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.wine : AppColors.line,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppColors.wine : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? AppColors.wine : AppColors.muted,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      opt.value,
                      style: TextStyle(
                        color: isSelected ? AppColors.wine : AppColors.ink,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _QuizResult extends StatelessWidget {
  const _QuizResult({required this.result, required this.l});
  final Map<String, int> result;
  final AppLocalizations l;

  @override
  Widget build(BuildContext context) {
    final score = result['score'] ?? 0;
    final passed = (result['passed'] ?? 0) == 1;
    final correct = result['correct'] ?? 0;
    final total = result['total'] ?? 0;
    final color = passed ? const Color(0xFF16A34A) : const Color(0xFFEF4444);
    final icon =
        passed ? Icons.emoji_events_rounded : Icons.replay_rounded;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
              ),
              child: Icon(icon, color: color, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              '$score%',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              passed ? l.quizPassed : l.quizFailed,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l.quizCorrectCount(correct, total),
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 14,
              ),
            ),
          ],
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
            content:
                Text(AppLocalizations.of(context).homeworkSubmitted),
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
    await ref.read(learningRepositoryProvider).submitHomework(
          lessonId: widget.lessonId,
          submissionUrl: filePath,
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
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final hwAsync = ref.watch(lessonHomeworkProvider(widget.lessonId));

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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l.homeworkTitle,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l.homeworkSubtitle,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // Toggle: Text or Voice
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _useVoice = false),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: !_useVoice ? AppColors.wine : Colors.white,
                          borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(12)),
                          border: Border.all(
                            color: !_useVoice
                                ? AppColors.wine
                                : AppColors.line,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.text_fields_rounded,
                                size: 16,
                                color: !_useVoice
                                    ? Colors.white
                                    : AppColors.inkSoft),
                            const SizedBox(width: 6),
                            Text(
                              'Matn',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: !_useVoice
                                    ? Colors.white
                                    : AppColors.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _useVoice = true),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        decoration: BoxDecoration(
                          color: _useVoice ? AppColors.wine : Colors.white,
                          borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(12)),
                          border: Border.all(
                            color: _useVoice ? AppColors.wine : AppColors.line,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.mic_rounded,
                                size: 16,
                                color: _useVoice
                                    ? Colors.white
                                    : AppColors.inkSoft),
                            const SizedBox(width: 6),
                            Text(
                              'Ovoz',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: _useVoice
                                    ? Colors.white
                                    : AppColors.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_useVoice)
                VoiceRecorder(
                  onSubmit: _submitVoice,
                  referenceText: null,
                )
              else ...[
                TextField(
                  controller: _textCtrl,
                  maxLines: 8,
                  minLines: 4,
                  decoration: InputDecoration(
                    hintText: l.homeworkHint,
                    hintStyle: const TextStyle(color: AppColors.muted),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: AppColors.wine, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),

                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFFEF4444),
                      fontSize: 13,
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                ElevatedButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _submitting ? l.sending : l.homeworkSend,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.wine,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),

                if (_editing) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => setState(() => _editing = false),
                    child: Text(l.cancel),
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
    final isReviewed = hw.isReviewed;
    final statusColor = isReviewed
        ? const Color(0xFF16A34A)
        : const Color(0xFFF59E0B);
    final statusLabel =
        isReviewed ? l.homeworkReviewed : l.homeworkPending;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.3),
              ),
            ),
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
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isReviewed && hw.curatorScore != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
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

          const SizedBox(height: 16),

          // Submitted text
          if (hw.submissionText != null) ...[
            Text(
              l.yourAnswer,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Text(
                hw.submissionText!,
                style: const TextStyle(
                  color: AppColors.ink,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Curator feedback
          if (isReviewed && hw.curatorFeedback != null) ...[
            Text(
              l.curatorFeedback,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Text(
                hw.curatorFeedback!,
                style: const TextStyle(
                  color: Color(0xFF166534),
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Resubmit button
          OutlinedButton.icon(
            onPressed: onResubmit,
            icon: const Icon(Icons.edit_rounded, size: 18),
            label: Text(l.homeworkResubmit),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.wine,
              side: const BorderSide(color: AppColors.wine),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
// Empty tab placeholder
// ═══════════════════════════════════════════════════

class _EmptyTab extends StatelessWidget {
  const _EmptyTab({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: AppColors.line),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
