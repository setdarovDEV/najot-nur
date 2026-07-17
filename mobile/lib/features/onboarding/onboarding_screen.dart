import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../providers/providers.dart';

/// Onboarding, Liquid Glass mockup "6c": three swipeable pages with a
/// gradient squircle illustration, stretching page dots and a "Keyingi" /
/// "Boshlash" gradient CTA plus a muted skip button. Completion logic is
/// unchanged — seen-flag + language picker redirect.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(tokenStoreProvider).setOnboardingSeen();
    if (mounted) context.go('/language', extra: 'onboarding');
  }

  void _next(int pageCount) {
    if (_page == pageCount - 1) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: GlassMotion.stepSlideCurve,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final pages = <_OnboardPage>[
      const _OnboardPage(
        icon: Icons.menu_book_rounded,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.wine, AppColors.wineDeep],
        ),
        title: 'Notiqlik kurslari',
        body:
            "Video darslar, amaliy mashqlar va professional ustozlar bilan o'rganing",
      ),
      const _OnboardPage(
        icon: Icons.record_voice_over_rounded,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.orange, AppColors.wine],
        ),
        title: 'AI bilan nutq mashqi',
        body:
            "Talaffuz, tezlik va pauzalar bo'yicha sun'iy intellektdan shaxsiy fikr oling",
      ),
      const _OnboardPage(
        icon: Icons.workspace_premium_rounded,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.blue, AppColors.wine],
        ),
        title: 'Sertifikat oling',
        body:
            "Kursni tamomlab, QR orqali tasdiqlanadigan rasmiy sertifikatga ega bo'ling",
      ),
    ];
    final isLast = _page == pages.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          const AmbientOrbs(),
          Column(
            children: [
              // Skip — muted text button, top-right (mockup 6c).
              Padding(
                padding: EdgeInsets.fromLTRB(20, topInset + 12, 20, 0),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GlassPressable(
                    onTap: _finish,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(
                        "O'tkazib yuborish",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: mutedColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (_, i) => _OnboardPageView(
                    page: pages[i],
                    textColor: textColor,
                    mutedColor: mutedColor,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, bottomInset + 28),
                child: Column(
                  children: [
                    _PageDots(count: pages.length, activeIndex: _page),
                    const SizedBox(height: 20),
                    _PrimaryCta(
                      label: isLast ? l.start : l.next,
                      onTap: () => _next(pages.length),
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

class _OnboardPage {
  const _OnboardPage({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final LinearGradient gradient;
  final String title;
  final String body;
}

class _OnboardPageView extends StatelessWidget {
  const _OnboardPageView({
    required this.page,
    required this.textColor,
    required this.mutedColor,
  });

  final _OnboardPage page;
  final Color textColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GlassEntrance(
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                gradient: page.gradient,
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.wineDeep.withValues(alpha: 0.30),
                    blurRadius: 46,
                    offset: const Offset(0, 22),
                  ),
                ],
              ),
              child: Icon(page.icon, size: 58, color: Colors.white),
            ),
          ),
          const SizedBox(height: 18),
          GlassEntrance(
            delay: GlassMotion.entranceStep,
            child: Text(
              page.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
                color: textColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          GlassEntrance(
            delay: GlassMotion.entranceStep * 2,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Text(
                page.body,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.6,
                  color: mutedColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Page dots — active dot stretches into a pill (same idiom as the checkout
/// step dots, mockup 6c).
class _PageDots extends StatelessWidget {
  const _PageDots({required this.count, required this.activeIndex});
  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final inactive =
        dark ? AppColors.glassStrokeDark : AppColors.glassStrokeLight;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: AnimatedContainer(
              duration: GlassMotion.tabMorph,
              curve: GlassMotion.tabMorphCurve,
              width: i == activeIndex ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == activeIndex ? AppColors.wine : inactive,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
      ],
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassPressable(
      onTap: onTap,
      child: Container(
        height: 54,
        width: double.infinity,
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
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
