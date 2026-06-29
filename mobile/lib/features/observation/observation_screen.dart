import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/observation_models.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/common.dart';

// ─── Screen state machine ────────────────────────────────────────────────────

enum _Mode { loading, difficultyPicker, testing }

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
      setState(() => _mode = _Mode.difficultyPicker);
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.wine,
        elevation: 0,
        title: Text(
          l.observationTest,
          style: const TextStyle(color: AppColors.wine, fontWeight: FontWeight.w800),
        ),
        leading: _mode == _Mode.testing
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() {
                  _mode = ref.read(authControllerProvider).isLoggedIn
                      ? _Mode.difficultyPicker
                      : _Mode.loading;
                  if (_mode == _Mode.loading) _init();
                }),
              )
            : null,
      ),
      body: switch (_mode) {
        _Mode.loading => const AppLoader(),
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
            onAnswer: (id, opt) => setState(() => _answers[id] = opt),
            onSubmit: _submit,
          ),
      },
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
    if (generating) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.wine),
            SizedBox(height: 20),
            Text(
              'AI testlar tayyorlanmoqda...',
              style: TextStyle(color: AppColors.muted, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const Text(
              'Qiyinlik darajasini tanlang',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.wine,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'AI siz uchun alohida testlar yaratadi',
              style: TextStyle(color: AppColors.muted, fontSize: 14),
            ),
            const SizedBox(height: 28),
            _DifficultyCard(
              label: 'Oson',
              subtitle: 'Oddiy savollar, aniq javoblar',
              icon: Icons.sentiment_satisfied_alt_rounded,
              color: const Color(0xFF4CAF50),
              bgColor: const Color(0xFFE8F5E9),
              onTap: () => onPick('easy'),
            ),
            const SizedBox(height: 14),
            _DifficultyCard(
              label: "O'rtacha",
              subtitle: "O'ylashni talab etadi, nozik farqlar bor",
              icon: Icons.psychology_alt_rounded,
              color: const Color(0xFFF57C00),
              bgColor: const Color(0xFFFFF3E0),
              onTap: () => onPick('medium'),
            ),
            const SizedBox(height: 14),
            _DifficultyCard(
              label: 'Qiyin',
              subtitle: 'Murakkab tahlil, ekspert darajasi',
              icon: Icons.local_fire_department_rounded,
              color: AppColors.wine,
              bgColor: AppColors.wine100,
              onTap: () => onPick('hard'),
            ),
            if (error != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                ),
                child: Text(
                  error!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  const _DifficultyCard({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: color, size: 18),
            ],
          ),
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
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (page > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => controller.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      ),
                      child: Text(l.back),
                    ),
                  ),
                if (page > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: !answered || submitting
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
                    child: submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.4))
                        : Text(isLast ? l.finishAndAnalyze : l.next),
                  ),
                ),
              ],
            ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l.questionCounter(pageIndex + 1, total),
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.wine),
              ),
              Text(
                l.answeredCount(answered),
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (pageIndex + 1) / total,
              minHeight: 8,
              backgroundColor: AppColors.line,
              color: AppColors.wine,
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
    final labels = _catLabels(context);
    final cat = labels[test.category] ?? labels['observation']!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: [
        _MediaBlock(test: test),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: cat.$3.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
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
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Text(
              l.testNumber(index + 1),
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          test.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          test.prompt,
          style: const TextStyle(fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 18),
        ...List.generate(test.options.length, (i) {
          final isSelected = selected == i;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => onSelected(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.wine100 : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.wine : AppColors.line,
                    width: isSelected ? 1.8 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isSelected ? AppColors.wine : AppColors.muted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        test.options[i],
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ─── Media block ──────────────────────────────────────────────────────────────

class _MediaBlock extends ConsumerWidget {
  const _MediaBlock({required this.test});
  final ObservationTest test;

  static const _categoryGradients = {
    'psychology': [AppColors.blue, Color(0xFF2E9BC4)],
    'body_language': [AppColors.orange, Color(0xFFE0431F)],
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
        height: 200,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(22),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white54, size: 56),
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
          height: 200,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(22),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 44,
            ),
          ),
        ),
      );
    }

    final fullUrl = ref.read(apiClientProvider).resolveMediaUrl(url);
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Image.network(
        fullUrl,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(22),
            ),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(color: Colors.white),
          );
        },
        errorBuilder: (_, __, ___) => Container(
          height: 200,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(22),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: Colors.white54, size: 56),
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
