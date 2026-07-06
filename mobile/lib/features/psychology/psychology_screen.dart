import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/psychology_models.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/common.dart';

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
    final tests = _staticTests ?? const <PsychologyTest>[];
    if (tests.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l.psychologyTest)),
        body: ErrorView(message: l.noTests),
      );
    }

    final isLast = _page == tests.length - 1;
    final currentId = tests[_page].id;
    final answered = _answers.containsKey(currentId);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.wine,
        elevation: 0,
        title: Text(
          l.psychologyTest,
          style: const TextStyle(color: AppColors.wine, fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          _Header(
            pageIndex: _page,
            total: tests.length,
            answered: _answers.length,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Text(
              l.psychologyIntro,
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
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
                onSelected: (opt) => setState(() => _answers[tests[i].id] = opt),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  if (_page > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _controller.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                        ),
                        child: Text(l.back),
                      ),
                    ),
                  if (_page > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: !answered || _submitting
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
                      child: _submitting
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
      ),
    );
  }
}

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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
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

  static const _gradients = <String, List<Color>>{
    'emotions': [Color(0xFF7B2FF7), Color(0xFF4A0EB5)],
    'stress': [Color(0xFFFF5C39), Color(0xFFE0431F)],
    'motivation': [Color(0xFF5BC2E7), Color(0xFF2E9BC4)],
    'general': [AppColors.wine, AppColors.wineDeep],
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final gradient = LinearGradient(
      colors: _gradients[test.category] ?? _gradients['general']!,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        _MediaBlock(test: test, gradient: gradient),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.wine.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.psychology_rounded,
                      size: 14, color: AppColors.wine),
                  const SizedBox(width: 5),
                  Text(
                    l.psychologyTest,
                    style: const TextStyle(
                      color: AppColors.wine,
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
