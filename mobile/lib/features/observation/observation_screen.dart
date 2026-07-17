import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/observation_models.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/enrollment_lock.dart';

// ─── Screen state machine ────────────────────────────────────────────────────

enum _Mode { loading, locked, difficultyPicker, testing }

/// Observation test flow, Liquid Glass mockup "6a" language: glass
/// difficulty cards, gradient progress bar, glass question card and
/// letter-chip option rows. The mode state machine, AI generation and
/// submit logic are unchanged.
class ObservationScreen extends ConsumerStatefulWidget {
  const ObservationScreen({super.key});

  @override
  ConsumerState<ObservationScreen> createState() => _ObservationScreenState();
}

class _ObservationScreenState extends ConsumerState<ObservationScreen> {
  _Mode _mode = _Mode.loading;
  List<ObservationTest> _tests = [];
  String? _sessionId; // non-null = AI session
  bool _generating = false;
  String? _genError;

  // Test progress
  final _controller = PageController();
  final Map<String, int> _answers = {};
  int _page = 0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final isLoggedIn = ref.read(authControllerProvider).isLoggedIn;
    if (isLoggedIn) {
      // Enrollment holatini tekshiramiz — kuzatuvchanlik testi faqat
      // faol kursga ega foydalanuvchilar uchun ochiq.
      try {
        final status = await ref.read(enrollmentStatusProvider.future);
        if (!status.hasActiveEnrollment) {
          if (mounted) setState(() => _mode = _Mode.locked);
        } else {
          if (mounted) setState(() => _mode = _Mode.difficultyPicker);
        }
      } catch (_) {
        if (mounted) setState(() => _mode = _Mode.difficultyPicker);
      }
    } else {
      await _loadDefaultTests();
    }
  }

  Future<void> _loadDefaultTests() async {
    setState(() {
      _mode = _Mode.loading;
      _genError = null;
    });
    try {
      final tests =
          await ref.read(observationRepositoryProvider).tests();
      setState(() {
        _tests = tests;
        _sessionId = null;
        _mode = _Mode.testing;
      });
    } catch (e) {
      setState(() {
        _genError = e.toString();
        _mode = _Mode.difficultyPicker; // show error on picker for logged-in, or stay
      });
    }
  }

  Future<void> _generateTests(String difficulty) async {
    setState(() {
      _generating = true;
      _genError = null;
    });
    try {
      final result = await ref
          .read(observationRepositoryProvider)
          .generateTests(difficulty);
      setState(() {
        _tests = result.tests;
        _sessionId = result.sessionId;
        _answers.clear();
        _page = 0;
        _mode = _Mode.testing;
      });
      // Reset page controller
      if (_controller.hasClients) {
        _controller.jumpToPage(0);
      }
    } catch (e) {
      setState(() => _genError = e.toString());
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    setState(() => _submitting = true);
    try {
      final payload = _tests
          .map((t) => {'test_id': t.id, 'selected_option': _answers[t.id]})
          .toList();

      final ObservationAttempt attempt;
      final isLoggedIn = ref.read(authControllerProvider).isLoggedIn;
      final sid = _sessionId;

      if (sid != null) {
        attempt = await ref.read(observationRepositoryProvider).submitAi(
              sessionId: sid,
              answers: payload,
            );
      } else if (isLoggedIn) {
        attempt =
            await ref.read(observationRepositoryProvider).submit(payload);
      } else {
        attempt = await ref
            .read(observationRepositoryProvider)
            .submitGuest(payload);
      }

      if (!mounted) return;
      context.pushReplacement('/observation/result', extra: attempt);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.errorPrefix(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _onBack() {
    if (_mode == _Mode.testing) {
      setState(() {
        _mode = ref.read(authControllerProvider).isLoggedIn
            ? _Mode.difficultyPicker
            : _Mode.loading;
        if (_mode == _Mode.loading) _init();
      });
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          const AmbientOrbs(),
          Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, topInset + 12, 16, 0),
                child: GlassEntrance(
                  child: Row(
                    children: [
                      _GlassIconButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: _onBack,
                      ),
                      Expanded(
                        child: Text(
                          l.observationTest,
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
              ),
              Expanded(
                child: switch (_mode) {
                  _Mode.loading => const AppLoader(),
                  _Mode.locked => const EnrollmentLock(
                      reason: EnrollmentLockReason.observation,
                    ),
                  _Mode.difficultyPicker => _DifficultyPickerView(
                      generating: _generating,
                      error: _genError,
                      onPick: _generateTests,
                    ),
                  _Mode.testing => _TestingView(
                      tests: _tests,
                      controller: _controller,
                      answers: _answers,
                      page: _page,
                      submitting: _submitting,
                      onPageChanged: (i) => setState(() => _page = i),
                      onAnswer: (id, opt) =>
                          setState(() => _answers[id] = opt),
                      onSubmit: _submit,
                    ),
                },
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
        opacity: onTap == null && !loading ? 0.5 : 1,
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

// ─── Difficulty Picker ────────────────────────────────────────────────────────

class _DifficultyPickerView extends StatelessWidget {
  const _DifficultyPickerView({
    required this.generating,
    required this.error,
    required this.onPick,
  });

  final bool generating;
  final String? error;
  final void Function(String difficulty) onPick;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;

    if (generating) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.wine),
            const SizedBox(height: 20),
            Text(
              'AI testlar tayyorlanmoqda...',
              style: TextStyle(color: mutedColor, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        GlassEntrance(
          child: Text(
            'Qiyinlik darajasini tanlang',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'AI siz uchun alohida testlar yaratadi',
          style: TextStyle(color: mutedColor, fontSize: 13),
        ),
        const SizedBox(height: 20),
        GlassEntrance(
          delay: GlassMotion.entranceStep,
          child: _DifficultyCard(
            label: 'Oson',
            subtitle: 'Oddiy savollar, aniq javoblar',
            icon: Icons.sentiment_satisfied_alt_rounded,
            color: AppColors.success,
            onTap: () => onPick('easy'),
          ),
        ),
        const SizedBox(height: 12),
        GlassEntrance(
          delay: GlassMotion.entranceStep * 2,
          child: _DifficultyCard(
            label: "O'rtacha",
            subtitle: "O'ylashni talab etadi, nozik farqlar bor",
            icon: Icons.psychology_alt_rounded,
            color: AppColors.warning,
            onTap: () => onPick('medium'),
          ),
        ),
        const SizedBox(height: 12),
        GlassEntrance(
          delay: GlassMotion.entranceStep * 3,
          child: _DifficultyCard(
            label: 'Qiyin',
            subtitle: 'Murakkab tahlil, ekspert darajasi',
            icon: Icons.local_fire_department_rounded,
            color: AppColors.wine,
            onTap: () => onPick('hard'),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppColors.radiusSegment),
              border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.3)),
            ),
            child: Text(
              error!,
              style: const TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  const _DifficultyCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;

    return GlassPressable(
      onTap: onTap,
      child: GlassContainer(
        borderRadius: AppColors.radiusTariffCard,
        withShadow: false,
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12.5, color: mutedColor),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}

// ─── Testing view (existing logic, extracted) ─────────────────────────────────

class _TestingView extends StatelessWidget {
  const _TestingView({
    required this.tests,
    required this.controller,
    required this.answers,
    required this.page,
    required this.submitting,
    required this.onPageChanged,
    required this.onAnswer,
    required this.onSubmit,
  });

  final List<ObservationTest> tests;
  final PageController controller;
  final Map<String, int> answers;
  final int page;
  final bool submitting;
  final ValueChanged<int> onPageChanged;
  final void Function(String id, int opt) onAnswer;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    if (tests.isEmpty) return ErrorView(message: l.noTests);

    final isLast = page == tests.length - 1;
    final current = tests[page];
    final answered = answers.containsKey(current.id);

    return Column(
      children: [
        _Header(
          pageIndex: page,
          total: tests.length,
          answered: answers.length,
        ),
        Expanded(
          child: PageView.builder(
            controller: controller,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tests.length,
            onPageChanged: onPageChanged,
            itemBuilder: (_, i) => _TestView(
              test: tests[i],
              index: i,
              selected: answers[tests[i].id],
              onSelected: (opt) => onAnswer(tests[i].id, opt),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
              16, 4, 16, MediaQuery.of(context).padding.bottom + 16),
          child: Column(
            children: [
              _PrimaryCta(
                label: isLast ? l.finishAndAnalyze : l.next,
                loading: submitting,
                onTap: !answered
                    ? null
                    : () {
                        if (isLast) {
                          onSubmit();
                        } else {
                          controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        }
                      },
              ),
              if (page > 0)
                GlassPressable(
                  onTap: () => controller.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      l.back,
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
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.pageIndex,
    required this.total,
    required this.answered,
  });
  final int pageIndex;
  final int total;
  final int answered;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final accent = dark ? AppColors.wine300 : AppColors.wine;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.questionCounter(pageIndex + 1, total),
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  color: accent,
                ),
              ),
              Text(
                l.answeredCount(answered),
                style: TextStyle(color: mutedColor, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Thin gradient progress bar (mockup 6a).
          ClipRRect(
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
                widthFactor: (pageIndex + 1) / total,
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
        ],
      ),
    );
  }
}

// ─── Test view ────────────────────────────────────────────────────────────────

class _TestView extends StatelessWidget {
  const _TestView({
    required this.test,
    required this.index,
    required this.selected,
    required this.onSelected,
  });
  final ObservationTest test;
  final int index;
  final int? selected;
  final ValueChanged<int> onSelected;

  Map<String, (String, IconData, Color)> _catLabels(BuildContext context) {
    final l = AppLocalizations.of(context);
    return {
      'psychology': (l.catPsychology, Icons.psychology_rounded, AppColors.blue),
      'body_language': (
        l.catBodyLanguage,
        Icons.accessibility_new_rounded,
        AppColors.orange
      ),
      'observation': (
        l.catObservation,
        Icons.visibility_rounded,
        AppColors.wine
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final labels = _catLabels(context);
    final cat = labels[test.category] ?? labels['observation']!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      children: [
        _MediaBlock(test: test),
        const SizedBox(height: 14),
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: cat.$3.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(cat.$2, size: 14, color: cat.$3),
                  const SizedBox(width: 5),
                  Text(
                    cat.$1,
                    style: TextStyle(
                      color: cat.$3,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Text(
              l.testNumber(index + 1),
              style: TextStyle(
                color: mutedColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Question card (mockup 6a).
        GlassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                test.title.toUpperCase(),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: mutedColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                test.prompt,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < test.options.length; i++) ...[
          _OptionTile(
            letter: String.fromCharCode(65 + i),
            text: test.options[i],
            selected: selected == i,
            onTap: () => onSelected(i),
          ),
          const SizedBox(height: 10),
        ],
      ],
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

// ─── Media block ──────────────────────────────────────────────────────────────

class _MediaBlock extends ConsumerWidget {
  const _MediaBlock({required this.test});
  final ObservationTest test;

  // Brand-only gradients per category.
  static const _categoryGradients = {
    'psychology': [AppColors.blue, AppColors.wine],
    'body_language': [AppColors.orange, AppColors.wine],
    'observation': [AppColors.wine, AppColors.wineDeep],
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final url = test.mediaUrl;
    final hasUrl = url != null && url.isNotEmpty;
    final gradient = LinearGradient(
      colors: _categoryGradients[test.category] ??
          _categoryGradients['observation']!,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final icon = test.mediaType == 'video'
        ? Icons.play_circle_outline_rounded
        : Icons.image_outlined;

    if (!hasUrl) {
      return Container(
        height: 190,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppColors.radiusTariffCard),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white54, size: 52),
            const SizedBox(height: 8),
            Text(
              l.mediaPlaceholder,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      );
    }

    if (test.mediaType == 'video') {
      return GestureDetector(
        onTap: () => _openVideo(context, ref, url),
        child: Container(
          height: 190,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppColors.radiusTariffCard),
          ),
          alignment: Alignment.center,
          // Frosted play button (mockup 6b idiom).
          child: Container(
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
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
        ),
      );
    }

    final fullUrl = ref.read(apiClientProvider).resolveMediaUrl(url);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppColors.radiusTariffCard),
      child: Image.network(
        fullUrl,
        height: 190,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            height: 190,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius:
                  BorderRadius.circular(AppColors.radiusTariffCard),
            ),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(color: Colors.white),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          height: 190,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(AppColors.radiusTariffCard),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white54, size: 52),
        ),
      ),
    );
  }

  Future<void> _openVideo(
      BuildContext context, WidgetRef ref, String relativePath) async {
    final l = AppLocalizations.of(context);
    final fullUrl = ref.read(apiClientProvider).resolveMediaUrl(relativePath);
    final uri = Uri.tryParse(fullUrl);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.cannotOpenVideo)),
      );
    }
  }
}
