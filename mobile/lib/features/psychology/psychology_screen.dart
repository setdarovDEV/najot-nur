import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/psychology_models.dart';
import '../../providers/providers.dart';

/// Psychology test flow, Liquid Glass mockup "6a" language: gradient
/// progress bar, glass question card and letter-chip option rows (selected =
/// wine ring). Static test content, answers and submit logic are unchanged.
class PsychologyScreen extends ConsumerStatefulWidget {
  const PsychologyScreen({super.key});

  @override
  ConsumerState<PsychologyScreen> createState() => _PsychologyScreenState();
}

class _PsychologyScreenState extends ConsumerState<PsychologyScreen> {
  final _controller = PageController();
  final Map<String, int> _answers = {};
  int _page = 0;
  bool _submitting = false;
  List<PsychologyTest>? _staticTests;

  @override
  void initState() {
    super.initState();
    // Use static content for now (per request: "static bo'lib tursin").
    _staticTests = _buildStaticTests();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    setState(() => _submitting = true);
    try {
      final payload = _staticTests!
          .map((t) => PsychologyAnswer(
                testId: t.id,
                optionIndex: _answers[t.id] ?? 0,
              ))
          .toList();
      final attempt =
          await ref.read(psychologyRepositoryProvider).submit(payload);
      if (!mounted) return;
      context.pushReplacement('/psychology/result', extra: attempt);
    } catch (e) {
      if (!mounted) return;
      // Backend may not be wired up yet — fall back to a local attempt so
      // the user can still see the result page with the auth CTA.
      final local = PsychologyAttempt(
        id: 'local-${DateTime.now().millisecondsSinceEpoch}',
        score: _computeLocalScore(),
        summary: l.psychologyIntro,
        analysis: const {},
        answers: _staticTests!
            .map((t) => PsychologyAnswer(
                  testId: t.id,
                  optionIndex: _answers[t.id] ?? 0,
                ))
            .toList(),
        createdAt: DateTime.now(),
      );
      context.pushReplacement('/psychology/result', extra: local);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  int? _computeLocalScore() {
    if (_staticTests == null || _staticTests!.isEmpty) return null;
    final answered = _answers.length;
    return ((answered / _staticTests!.length) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final accent = dark ? AppColors.wine300 : AppColors.wine;
    final topInset = MediaQuery.of(context).padding.top;

    final tests = _staticTests ?? const <PsychologyTest>[];
    if (tests.isEmpty) {
      return Scaffold(
        body: Stack(
          children: [
            const AmbientOrbs(),
            Center(
              child: Text(l.noTests, style: TextStyle(color: mutedColor)),
            ),
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

    final isLast = _page == tests.length - 1;
    final currentId = tests[_page].id;
    final answered = _answers.containsKey(currentId);
    final progress = (_page + 1) / tests.length;
    final counter =
        '${'${_page + 1}'.padLeft(2, '0')}/${'${tests.length}'.padLeft(2, '0')}';

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
                            icon: Icons.arrow_back_rounded,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          Expanded(
                            child: Text(
                              l.psychologyTest,
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
                    const SizedBox(height: 8),
                    Text(
                      l.psychologyIntro,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: mutedColor, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tests.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) => _TestView(
                    test: tests[i],
                    index: i,
                    selected: _answers[tests[i].id],
                    onSelected: (opt) =>
                        setState(() => _answers[tests[i].id] = opt),
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
                      loading: _submitting,
                      onTap: !answered
                          ? null
                          : () {
                              if (isLast) {
                                _submit();
                              } else {
                                _controller.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                );
                              }
                            },
                    ),
                    if (_page > 0)
                      GlassPressable(
                        onTap: () => _controller.previousPage(
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

// ───────────────────────── Question page ─────────────────────────

class _TestView extends ConsumerWidget {
  const _TestView({
    required this.test,
    required this.index,
    required this.selected,
    required this.onSelected,
  });

  final PsychologyTest test;
  final int index;
  final int? selected;
  final ValueChanged<int> onSelected;

  // Brand-only gradients per category (purple replaced with wine/orange/blue).
  static const _gradients = <String, List<Color>>{
    'emotions': [AppColors.wine, AppColors.wineDeep],
    'stress': [AppColors.orange, AppColors.wine],
    'motivation': [AppColors.blue, AppColors.wine],
    'general': [AppColors.wine, AppColors.wineDeep],
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final accent = dark ? AppColors.wine300 : AppColors.wine;
    final gradient = LinearGradient(
      colors: _gradients[test.category] ?? _gradients['general']!,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      children: [
        _MediaBlock(test: test, gradient: gradient),
        const SizedBox(height: 14),
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: dark
                    ? AppColors.wine300.withValues(alpha: 0.16)
                    : AppColors.wine.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.psychology_rounded, size: 14, color: accent),
                  const SizedBox(width: 5),
                  Text(
                    l.psychologyTest,
                    style: TextStyle(
                      color: accent,
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

// ───────────────────────── Media block ─────────────────────────

class _MediaBlock extends ConsumerWidget {
  const _MediaBlock({required this.test, required this.gradient});
  final PsychologyTest test;
  final LinearGradient gradient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final url = test.mediaUrl;
    final hasUrl = url != null && url.isNotEmpty;
    final icon = test.mediaType == 'video'
        ? Icons.play_circle_outline_rounded
        : Icons.image_outlined;

    if (!hasUrl) {
      // Static placeholder until real media is wired up.
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

// ─── Static content ───────────────────────────────────────────────────────────
//
// Per the product brief, the psychology test runs against a static set of
// questions for now. Real media (images / videos) will be plugged in later —
// the UI gracefully shows a placeholder block until `mediaUrl` is provided.

List<PsychologyTest> _buildStaticTests() => <PsychologyTest>[
      PsychologyTest(
        id: 'p1',
        orderIndex: 0,
        title: 'Stressga munosabatingiz',
        prompt: 'Qiyin vaziyatga tushib qolsangiz, odatda nima qilasiz?',
        mediaType: 'image',
        mediaUrl: null,
        category: 'stress',
        options: const [
          'Vaziyatni tahlil qilib, yechim izlayman',
          'Bir oz vaqt o\'tib, keyin harakat qilaman',
          'Boshqalardan yordam so\'rayman',
          'Hisobga olmay, o\'z holicha hal bo\'lishini kutaman',
        ],
      ),
      PsychologyTest(
        id: 'p2',
        orderIndex: 1,
        title: 'Emotsiyalarni boshqarish',
        prompt:
            'Kuchli emotsiya (g\'azab, xafa bo\'lish) paytida o\'zingizni qanday tutasiz?',
        mediaType: 'video',
        mediaUrl: null,
        category: 'emotions',
        options: const [
          'Chuqur nafas olib, o\'zimni tinchlantiraman',
          'Jismoniy faollik bilan chalg\'iyman',
          'Yaqin odam bilan gaplashaman',
          'Hisni yashirib, davom etaveraman',
        ],
      ),
      PsychologyTest(
        id: 'p3',
        orderIndex: 2,
        title: 'Ishonch va muloqot',
        prompt:
            'Notanish odamlar bilan muloqot qilishda qanchalik ishonchli his qilasiz?',
        mediaType: 'image',
        mediaUrl: null,
        category: 'general',
        options: const [
          'Juda ishonchli — oson muloqot qilaman',
          'O\'rtacha — vaziyatga qarab',
          'Biroz qiynalaman, lekin harakat qilaman',
          'Juda qiynalaman, ko\'pincha voz kechaman',
        ],
      ),
      PsychologyTest(
        id: 'p4',
        orderIndex: 3,
        title: 'Motivatsiya manbasi',
        prompt: 'Sizni eng ko\'p nima ilhomlantiradi?',
        mediaType: 'image',
        mediaUrl: null,
        category: 'motivation',
        options: const [
          'Shaxsiy maqsadlar va yutuqlar',
          'Boshqalarning muvaffaqiyati',
          'Jamoa va hamkasabalar',
          'Ichki qoniqish va tinchlik',
        ],
      ),
      PsychologyTest(
        id: 'p5',
        orderIndex: 4,
        title: 'Qaror qabul qilish',
        prompt: 'Muhim qaror qabul qilishda qanday yondashasiz?',
        mediaType: 'video',
        mediaUrl: null,
        category: 'general',
        options: const [
          'Barcha ma\'lumotlarni to\'plab, tahlil qilaman',
          'Ichki hissiyotimga tayanaman',
          'Tez qaror qabul qilib, javobgarlikni o\'z zimmamga olaman',
          'Boshqalarning fikrini so\'rab, birga hal qilamiz',
        ],
      ),
    ];
