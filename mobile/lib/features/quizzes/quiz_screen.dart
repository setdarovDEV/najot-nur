import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/quiz_models.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/enrollment_lock.dart';

class QuizScreen extends ConsumerStatefulWidget {
  const QuizScreen({super.key, required this.quizId});
  final String quizId;

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  QuizDetail? _quiz;
  bool _loading = true;
  String? _error;

  int _currentIndex = 0;
  final List<int?> _answers = [];
  bool _submitted = false;
  QuizAttemptResult? _result;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    try {
      final quiz =
          await ref.read(quizRepositoryProvider).getQuiz(widget.quizId);
      if (mounted) {
        setState(() {
          _quiz = quiz;
          _answers.addAll(List<int?>.filled(quiz.questions.length, null));
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _submit() async {
    final quiz = _quiz;
    if (quiz == null) return;
    if (_answers.any((a) => a == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)
                .answeredCount(_answers.whereType<int>().length))),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final result = await ref
          .read(quizRepositoryProvider)
          .submitAttempt(widget.quizId, _answers.cast<int>());
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)
                  .errorPrefix(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    final enrollment = ref.watch(enrollmentStatusProvider);
    final isLocked = enrollment.when(
      loading: () => false,
      error: (_, __) => false,
      data: (s) => !s.hasActiveEnrollment,
    );
    if (isLocked) {
      return Scaffold(
        appBar: AppBar(title: Text(l.testsTitle)),
        body: const EnrollmentLock(reason: EnrollmentLockReason.quiz),
      );
    }

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l.errorPrefix(_error!))),
      );
    }

    final quiz = _quiz!;
    if (_result != null) {
      return _ResultScreen(quiz: quiz, result: _result!);
    }

    final question = quiz.questions[_currentIndex];
    final isLast = _currentIndex == quiz.questions.length - 1;
    final coverImage = _absoluteUrl(quiz.coverImageUrl);
    final introVideo = _absoluteUrl(quiz.videoUrl);

    return Scaffold(
      appBar: AppBar(
        title: Text(quiz.title),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: (_currentIndex + 1) / quiz.questions.length,
            backgroundColor: AppColors.line,
            color: AppColors.wine,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_currentIndex == 0) ...[
                    if (coverImage != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            coverImage,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.wine.withValues(alpha: 0.08),
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (introVideo != null) ...[
                      _VideoPlayerBlock(url: introVideo),
                      const SizedBox(height: 12),
                    ],
                  ],
                  if (question.imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.network(
                        _absoluteUrl(question.imageUrl)!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (question.videoUrl != null) ...[
                    _VideoPlayerBlock(url: _absoluteUrl(question.videoUrl)!),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    question.question,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  ...List.generate(
                    question.options.length,
                    (i) => _OptionTile(
                      text: question.options[i],
                      selected: _answers[_currentIndex] == i,
                      onTap: () =>
                          setState(() => _answers[_currentIndex] = i),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
            child: Row(
              children: [
                if (_currentIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          setState(() => _currentIndex--),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppColors.line),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(l.prev),
                    ),
                  ),
                if (_currentIndex > 0) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _answers[_currentIndex] == null
                        ? null
                        : () {
                            if (isLast) {
                              _submit();
                            } else {
                              setState(() => _currentIndex++);
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.wine,
                      disabledBackgroundColor:
                          AppColors.wine.withValues(alpha: 0.4),
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            isLast ? l.quizFinish : l.quizNext,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700),
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

class _OptionTile extends StatelessWidget {
  const _OptionTile(
      {required this.text, required this.selected, required this.onTap});
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.wine.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.wine : AppColors.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.wine : Colors.transparent,
                border: Border.all(
                  color: selected ? AppColors.wine : AppColors.muted,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 15,
                  color: selected ? AppColors.wine : AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultScreen extends StatelessWidget {
  const _ResultScreen({required this.quiz, required this.result});
  final QuizDetail quiz;
  final QuizAttemptResult result;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isGood = result.score >= 70;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.quizResult),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isGood ? Colors.green : AppColors.orange)
                      .withValues(alpha: 0.12),
                ),
                child: Icon(
                  isGood
                      ? Icons.emoji_events_rounded
                      : Icons.replay_rounded,
                  size: 50,
                  color: isGood ? Colors.green : AppColors.orange,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '${result.score}%',
                style: const TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: AppColors.wine),
              ),
              const SizedBox(height: 8),
              Text(
                l.quizScore(result.correctCount, result.totalCount),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => Navigator.of(context)
                    .popUntil((r) => r.settings.name == '/home'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.wine,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  l.backToHome,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoPlayerBlock extends StatelessWidget {
  const _VideoPlayerBlock({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 56,
                ),
              ),
              Positioned(
                bottom: 8,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.videocam_rounded,
                          color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Video',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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
    );
  }
}

String? _absoluteUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http')) return path;
  return '${AppConstants.apiUrl}$path';
}
