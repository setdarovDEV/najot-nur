import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/observation_models.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/score_ring.dart';

/// Observation result, Liquid Glass mockup "6e"/"3d" language: score ring,
/// glass section cards for the summary / per-category analysis / strengths /
/// improvements, and a gradient auth CTA. Data handling is unchanged.
class ObservationResultScreen extends ConsumerWidget {
  const ObservationResultScreen({super.key, required this.attempt});
  final ObservationAttempt attempt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final isLoggedIn = ref.watch(authControllerProvider).isLoggedIn;
    final byCategory =
        (attempt.analysis['by_category'] as Map?)?.cast<String, dynamic>() ?? {};
    final catLabels = {
      'psychology': l.catPsychology,
      'body_language': l.catBodyLanguage,
      'observation': l.catObservation,
    };
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final bodyColor = dark
        ? AppColors.inkDarkPrimary.withValues(alpha: 0.82)
        : AppColors.inkSoft;
    final topInset = MediaQuery.of(context).padding.top;

    var stagger = 0;
    Duration nextDelay() => GlassMotion.entranceStep * ++stagger;

    return Scaffold(
      body: Stack(
        children: [
          const AmbientOrbs(),
          ListView(
            padding: EdgeInsets.fromLTRB(16, topInset + 12, 16,
                MediaQuery.of(context).padding.bottom + 24),
            children: [
              GlassEntrance(
                child: Row(
                  children: [
                    _GlassIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.of(context).canPop()
                          ? Navigator.of(context).pop()
                          : context.go('/home'),
                    ),
                    Expanded(
                      child: Text(
                        l.observationAnalysis,
                        textAlign: TextAlign.center,
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
              const SizedBox(height: 18),
              GlassEntrance(
                delay: nextDelay(),
                child: Center(
                  child: ScoreRing(
                    score: attempt.score ?? 0,
                    size: 150,
                    label: l.scoreOverallLabel,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (attempt.summary != null)
                GlassEntrance(
                  delay: nextDelay(),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: GlassContainer(
                      borderRadius: AppColors.radiusTariffCard,
                      withShadow: false,
                      padding: const EdgeInsets.all(18),
                      child: Text(
                        attempt.summary!,
                        style: TextStyle(
                            height: 1.5, fontSize: 13.5, color: bodyColor),
                      ),
                    ),
                  ),
                ),
              if (byCategory.isNotEmpty) ...[
                GlassEntrance(
                  delay: nextDelay(),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 2, bottom: 10),
                    child: Text(
                      l.byDirections,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
                for (final e in byCategory.entries
                    .where((e) => '${e.value}'.isNotEmpty))
                  GlassEntrance(
                    delay: nextDelay(),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GlassContainer(
                        borderRadius: AppColors.radiusTariffCard,
                        withShadow: false,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              catLabels[e.key] ?? e.key,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                                color: dark
                                    ? AppColors.wine300
                                    : AppColors.wine,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${e.value}',
                              style: TextStyle(
                                  height: 1.4,
                                  fontSize: 13,
                                  color: bodyColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 2),
              ],
              if (attempt.strengths.isNotEmpty)
                GlassEntrance(
                  delay: nextDelay(),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _ListCard(
                      title: l.strengthsTitle,
                      items: attempt.strengths,
                      color: AppColors.success,
                    ),
                  ),
                ),
              if (attempt.improvements.isNotEmpty)
                GlassEntrance(
                  delay: nextDelay(),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _ListCard(
                      title: l.improvementsTitle,
                      items: attempt.improvements,
                      color: AppColors.warning,
                    ),
                  ),
                ),
              if (!isLoggedIn)
                GlassEntrance(
                  delay: nextDelay(),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _AuthCtaCard(
                      title: l.loginRequiredTitle,
                      subtitle: l.loginRequiredSubtitle,
                      buttonLabel: l.registerLogin,
                      onTap: () => context.push('/auth'),
                    ),
                  ),
                ),
              GlassEntrance(
                delay: nextDelay(),
                child: _PrimaryCta(
                  label: l.backToHome,
                  onTap: () => context.go('/home'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Local widgets ────────────────────────────────────────────────────────────

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
  const _PrimaryCta({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassPressable(
      onTap: onTap,
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

class _ListCard extends StatelessWidget {
  const _ListCard({
    required this.title,
    required this.items,
    required this.color,
  });
  final String title;
  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final bodyColor = dark
        ? AppColors.inkDarkPrimary.withValues(alpha: 0.82)
        : AppColors.inkSoft;

    return GlassContainer(
      borderRadius: AppColors.radiusTariffCard,
      withShadow: false,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),
          for (final s in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration:
                          BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s,
                      style: TextStyle(
                          height: 1.5, fontSize: 13, color: bodyColor),
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

class _AuthCtaCard extends StatelessWidget {
  const _AuthCtaCard({
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.wineGradient,
        borderRadius: BorderRadius.circular(AppColors.radiusTariffCard),
        boxShadow: [
          BoxShadow(
            color: AppColors.wine.withValues(alpha: 0.30),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 14),
          GlassPressable(
            onTap: onTap,
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppColors.radiusSegment),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  color: AppColors.wine,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
