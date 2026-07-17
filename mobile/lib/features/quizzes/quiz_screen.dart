import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/quiz_models.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/enrollment_lock.dart';

/// Quiz taking flow, Liquid Glass mockups "6a" (question + options) and
/// "6e" (result). Question/answer/submit logic is unchanged — only the
/// chrome moved to glass: gradient progress bar, glass question card,
/// letter-chip option rows and an animated score ring on the result.
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

  void _showLockedSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.sheetScrim,
      builder: (ctx) {
        final dark = Theme.of(ctx).brightness == Brightness.dark;
        final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
        final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
        final accent = dark ? AppColors.wine300 : AppColors.wine;
        return GlassSheet(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 14),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dark
                      ? AppColors.wine300.withValues(alpha: 0.16)
                      : AppColors.wine.withValues(alpha: 0.10),
                ),
                child: Icon(Icons.lock_rounded, color: accent, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                "Natijani ko'rish uchun kurs kerak",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Testni to'liq topshirib ball olish va natijangizni ko'rish uchun avval kurs sotib oling.",
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: mutedColor, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: _PrimaryCta(
                  label: 'Kurs sotib olish',
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go('/home');
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final accent = dark ? AppColors.wine300 : AppColors.wine;
    final topInset = MediaQuery.of(context).padding.top;

    final enrollment = ref.watch(enrollmentStatusProvider);
    final isLocked = enrollment.when(
      loading: () => false,
      error: (_, __) => false,
      data: (s) => !s.hasActiveEnrollment && !s.isStaff,
    );

    if (_loading) {
      return const Scaffold(
        body: Stack(children: [AmbientOrbs(), AppLoader()]),
      );
    }
    if (_error != null) {
      return Scaffold(
        body: Stack(
          children: [
            const AmbientOrbs(),
            SafeArea(child: ErrorView(message: l.errorPrefix(_error!))),
            Positioned(
              top: topInset + 8,
              left: 12,
              child: _GlassIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
          ],
        ),
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
    final progress = (_currentIndex + 1) / quiz.questions.length;
    final counter =
        '${'${_currentIndex + 1}'.padLeft(2, '0')}/${'${quiz.questions.length}'.padLeft(2, '0')}';

    return Scaffold(
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
                            icon: Icons.close_rounded,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          Expanded(
                            child: Text(
                              quiz.title,
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 11, vertical: 7),
                            decoration: BoxDecoration(
                              color: dark
                                  ? AppColors.wine300.withValues(alpha: 0.16)
                                  : AppColors.wine.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              counter,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                                color: accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Thin gradient progress bar (mockup 6a).
                    GlassEntrance(
                      delay: GlassMotion.entranceStep,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          height: 6,
                          color: dark
                              ? AppColors.wine300.withValues(alpha: 0.16)
                              : AppColors.wine.withValues(alpha: 0.10),
                          alignment: Alignment.centerLeft,
                          child: AnimatedFractionallySizedBox(
                            duration: GlassMotion.tabMorph,
                            curve: GlassMotion.tabMorphCurve,
                            widthFactor: progress,
                            child: Container(
                              decoration: const BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(999)),
                                gradient: LinearGradient(
                                  colors: [AppColors.wine, AppColors.orange],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: GlassMotion.stepSlide,
                  switchInCurve: GlassMotion.stepSlideCurve,
                  switchOutCurve: Curves.easeOut,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.08, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: SingleChildScrollView(
                    key: ValueKey(_currentIndex),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_currentIndex == 0) ...[
                          if (coverImage != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  AppColors.radiusTariffCard),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Image.network(
                                  coverImage,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: AppColors.wine
                                        .withValues(alpha: 0.08),
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      color: mutedColor,
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
                            borderRadius: BorderRadius.circular(
                                AppColors.radiusTariffCard),
                            child: Image.network(
                              _absoluteUrl(question.imageUrl)!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (question.videoUrl != null) ...[
                          _VideoPlayerBlock(
                              url: _absoluteUrl(question.videoUrl)!),
                          const SizedBox(height: 12),
                        ],
                        // Question card (mockup 6a).
                        GlassContainer(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SAVOL ${_currentIndex + 1}',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                  color: mutedColor,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                question.question,
                                style: TextStyle(
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.w800,
                                  height: 1.4,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (var i = 0; i < question.options.length; i++) ...[
                          _OptionTile(
                            letter: String.fromCharCode(65 + i),
                            text: question.options[i],
                            selected: _answers[_currentIndex] == i,
                            onTap: () =>
                                setState(() => _answers[_currentIndex] = i),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    16, 4, 16, MediaQuery.of(context).padding.bottom + 16),
                child: Column(
                  children: [
                    _PrimaryCta(
                      label: isLast ? l.quizFinish : l.quizNext,
                      loading: _submitting,
                      onTap: _answers[_currentIndex] == null
                          ? null
                          : () {
                              if (isLast) {
                                if (isLocked) {
                                  _showLockedSheet(context);
                                } else {
                                  _submit();
                                }
                              } else {
                                setState(() => _currentIndex++);
                              }
                            },
                    ),
                    if (_currentIndex > 0)
                      GlassPressable(
                        onTap: () => setState(() => _currentIndex--),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            l.prev,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: mutedColor,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Shared bits ─────────────────────────

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

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({
    required this.label,
    required this.onTap,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onTap;
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
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Answer option row (mockup 6a): glass row with an A/B/C/D letter chip;
/// selected = wine ring + tinted letter chip.
class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.letter,
    required this.text,
    required this.selected,
    required this.onTap,
  });
  final String letter;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final accent = dark ? AppColors.wine300 : AppColors.wine;

    return GlassPressable(
      onTap: onTap,
      child: Stack(
        children: [
          GlassContainer(
            borderRadius: AppColors.radiusButton,
            withShadow: false,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.wine
                        : (dark
                            ? AppColors.wine300.withValues(alpha: 0.16)
                            : AppColors.wine.withValues(alpha: 0.10)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    letter,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : accent,
                    ),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (selected)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(AppColors.radiusButton),
                    border: Border.all(color: AppColors.wine, width: 1.5),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────── Result (mockup 6e) ─────────────────────────

class _ResultScreen extends StatefulWidget {
  const _ResultScreen({required this.quiz, required this.result});
  final QuizDetail quiz;
  final QuizAttemptResult result;

  @override
  State<_ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<_ResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _ring.forward();
    });
  }

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final result = widget.result;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final topInset = MediaQuery.of(context).padding.top;

    final isGood = result.score >= 70;
    final ringColor = isGood ? AppColors.success : AppColors.warning;
    final wrongCount = result.totalCount - result.correctCount;

    return Scaffold(
      body: Stack(
        children: [
          const AmbientOrbs(),
          ListView(
            padding: EdgeInsets.fromLTRB(16, topInset + 24, 16,
                MediaQuery.of(context).padding.bottom + 24),
            children: [
              GlassEntrance(
                child: Column(
                  children: [
                    Text(
                      widget.quiz.title.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: mutedColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l.testComplete}!',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Animated score ring (mockup 6e).
              GlassEntrance(
                delay: GlassMotion.entranceStep * 2,
                child: Center(
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: AnimatedBuilder(
                      animation: _ring,
                      builder: (context, _) => CustomPaint(
                        painter: _ScoreRingPainter(
                          progress: Curves.easeOutCubic
                                  .transform(_ring.value) *
                              (result.score / 100),
                          color: ringColor,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${result.score}',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                'ball · ${result.correctCount}/${result.totalCount}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: mutedColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GlassEntrance(
                delay: GlassMotion.entranceStep * 3,
                child: Text(
                  isGood ? l.quizGoodSubtitle : l.quizBadSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: mutedColor),
                ),
              ),
              const SizedBox(height: 14),
              // Stats card (mockup 6e).
              GlassEntrance(
                delay: GlassMotion.entranceStep * 4,
                child: GlassContainer(
                  borderRadius: AppColors.radiusTariffCard,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Column(
                    children: [
                      _StatRow(
                        icon: Icons.check_rounded,
                        color: AppColors.success,
                        label: l.quizMetricCorrect,
                        value: '${result.correctCount}',
                        showDivider: true,
                      ),
                      _StatRow(
                        icon: Icons.close_rounded,
                        color: AppColors.danger,
                        label: "Noto'g'ri javoblar",
                        value: '$wrongCount',
                        showDivider: true,
                      ),
                      _StatRow(
                        icon: Icons.percent_rounded,
                        color: AppColors.warning,
                        label: l.quizMetricScore,
                        value: '${result.score}%',
                        showDivider: false,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              GlassEntrance(
                delay: GlassMotion.entranceStep * 5,
                child: Row(
                  children: [
                    if (!isGood) ...[
                      Expanded(
                        flex: 10,
                        child: GlassPressable(
                          onTap: () => Navigator.of(context).pop(),
                          child: GlassContainer(
                            borderRadius: AppColors.radiusButton,
                            height: 54,
                            withShadow: false,
                            alignment: Alignment.center,
                            child: Text(
                              l.tryAgain,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: dark
                                    ? AppColors.inkDarkPrimary
                                    : AppColors.inkSoft,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      flex: isGood ? 10 : 13,
                      child: _PrimaryCta(
                        label: l.backToHome,
                        onTap: () => context.go('/home'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.showDivider,
  });
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final lineColor = dark ? AppColors.lineDark : AppColors.line;
    final labelColor = dark
        ? AppColors.inkDarkPrimary.withValues(alpha: 0.78)
        : AppColors.inkSoft;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: labelColor,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        if (showDivider) Divider(height: 1, thickness: 0.5, color: lineColor),
      ],
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  _ScoreRingPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 11;
    final bg = Paint()
      ..color = color.withValues(alpha: 0.14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bg);
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress.clamp(0.0, 1.0),
        false,
        fg,
      );
    }
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) =>
      old.progress != progress || old.color != color;
}

// ───────────────────────── Media blocks ─────────────────────────

class _VideoPlayerBlock extends StatelessWidget {
  const _VideoPlayerBlock({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppColors.radiusTariffCard),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.ink, AppColors.wineDeep],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glass play button (mockup 6b idiom).
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 0.5,
                  ),
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 30),
              ),
              Positioned(
                bottom: 8,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                      width: 0.5,
                    ),
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
    );
  }
}

String? _absoluteUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http')) return path;
  return '${AppConstants.apiUrl}$path';
}
