import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/speech_models.dart';
import '../../shared/widgets/score_ring.dart';

/// Free-talk AI analysis result, Liquid Glass mockup "3d": score ring on top,
/// glass metric card, filler-word pills and AI recommendation cards.
class TalkResultScreen extends StatefulWidget {
  const TalkResultScreen({super.key, required this.analysis});
  final SpeechAnalysis analysis;

  @override
  State<TalkResultScreen> createState() => _TalkResultScreenState();
}

class _TalkResultScreenState extends State<TalkResultScreen> {
  final _scrollOffset = ValueNotifier<double>(0);

  SpeechAnalysis get analysis => widget.analysis;

  @override
  void dispose() {
    _scrollOffset.dispose();
    super.dispose();
  }

  String _gradeTitle(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = analysis.overallScore;
    if (s >= 85) return l.gradeTitleExcellent;
    if (s >= 70) return l.gradeTitleGood;
    if (s >= 50) return l.gradeTitleAverage;
    return l.gradeTitleWeak;
  }

  int get _fillerScore {
    final total = analysis.fillerWords.values
        .fold<int>(0, (sum, v) => sum + ((v as num?)?.toInt() ?? 0));
    return (100 - (total * 12).clamp(0, 100)).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final fillers = analysis.fillerWords;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final accent = dark ? AppColors.wine300 : AppColors.wine;
    final topInset = MediaQuery.of(context).padding.top;

    final metrics = [
      _Metric(
        label: l.metricVoiceConfidence,
        value: ((analysis.meaningScore + analysis.fluencyScore) ~/ 2),
        color: accent,
      ),
      _Metric(
        label: l.metricPauseBalance,
        value: analysis.fluencyScore,
        color: AppColors.blue,
      ),
      _Metric(
        label: l.metricFillerWords,
        value: _fillerScore,
        color: AppColors.warning,
      ),
      _Metric(
        label: l.metricThoughtFlow,
        value: analysis.meaningScore,
        color: AppColors.success,
      ),
    ];

    var entrance = 0;
    Duration nextDelay() => GlassMotion.entranceStep * entrance++;

    return Scaffold(
      body: Stack(
        children: [
          const AmbientOrbs(),
          NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n.metrics.axis == Axis.vertical) {
                _scrollOffset.value = n.metrics.pixels;
              }
              return false;
            },
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, topInset + 12, 16, 60),
              children: [
                GlassEntrance(
                  delay: nextDelay(),
                  child: Row(
                    children: [
                      _GlassBackButton(
                          onTap: () => Navigator.of(context).maybePop()),
                      Expanded(
                        child: Text(
                          l.speechAnalysis,
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
                const SizedBox(height: 14),
                GlassEntrance(
                  delay: nextDelay(),
                  child: Column(
                    children: [
                      Text(
                        l.speechAnalysis.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                          color: mutedColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _gradeTitle(context),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                GlassEntrance(
                  delay: nextDelay(),
                  child: Center(
                    child: ScoreRing(
                      score: analysis.overallScore,
                      size: 150,
                      label: 'umumiy ball',
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                GlassEntrance(
                  delay: nextDelay(),
                  child: _SectionLabel(l.analysisMetrics),
                ),
                const SizedBox(height: 10),
                GlassEntrance(
                  delay: nextDelay(),
                  child: _MetricsCard(metrics: metrics),
                ),
                const SizedBox(height: 16),
                GlassEntrance(
                  delay: nextDelay(),
                  child: _SectionLabel(l.fillersTitle),
                ),
                const SizedBox(height: 10),
                if (fillers.isNotEmpty)
                  GlassEntrance(
                    delay: nextDelay(),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: fillers.entries
                          .map(
                            (e) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.warning
                                    .withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${e.key}  ×${e.value}',
                                style: const TextStyle(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  )
                else
                  GlassEntrance(
                    delay: nextDelay(),
                    child: _SuccessRow(l.noFillers),
                  ),
                if (analysis.strengths.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  GlassEntrance(
                    delay: nextDelay(),
                    child: _SectionLabel(l.strengthsTitle),
                  ),
                  const SizedBox(height: 10),
                  GlassEntrance(
                    delay: nextDelay(),
                    child: _BulletCard(
                      items: analysis.strengths,
                      color: AppColors.success,
                    ),
                  ),
                ],
                if (analysis.improvements.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  GlassEntrance(
                    delay: nextDelay(),
                    child: _SectionLabel(l.improvementsTitle),
                  ),
                  const SizedBox(height: 10),
                  GlassEntrance(
                    delay: nextDelay(),
                    child: _BulletCard(
                      items: analysis.improvements,
                      color: AppColors.warning,
                    ),
                  ),
                ],
                if (analysis.summary.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  GlassEntrance(
                    delay: nextDelay(),
                    child: _SectionLabel(l.summaryTitle),
                  ),
                  const SizedBox(height: 10),
                  GlassEntrance(
                    delay: nextDelay(),
                    child: _RecommendationCard(text: analysis.summary),
                  ),
                ],
                const SizedBox(height: 18),
                GlassEntrance(
                  delay: nextDelay(),
                  child: _PrimaryCta(
                    label: l.backToHome,
                    onTap: () => context.go('/home'),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child:
                GlassTopChrome(offset: _scrollOffset, title: l.speechAnalysis),
          ),
        ],
      ),
    );
  }
}

// ── Shared result screen widgets ─────────────────────────────────────────────

class _Metric {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final int value;
  final Color color;
}

class _GlassBackButton extends StatelessWidget {
  const _GlassBackButton({required this.onTap});
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
          Icons.arrow_back_rounded,
          size: 20,
          color: dark ? AppColors.inkDarkPrimary : AppColors.ink,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
          color: mutedColor,
        ),
      ),
    );
  }
}

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({required this.metrics});
  final List<_Metric> metrics;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;

    return GlassContainer(
      borderRadius: AppColors.radiusTariffCard,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Column(
        children: metrics
            .map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          m.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: textColor,
                            fontSize: 13.5,
                          ),
                        ),
                        Text(
                          '${m.value}%',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: m.color,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: m.value / 100,
                        minHeight: 5,
                        backgroundColor: m.color.withValues(alpha: 0.12),
                        color: m.color,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

/// Bullet list inside a single glass card (strengths / improvements).
class _BulletCard extends StatelessWidget {
  const _BulletCard({required this.items, required this.color});
  final List<String> items;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;

    return GlassContainer(
      borderRadius: AppColors.radiusTariffCard,
      withShadow: false,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        s,
                        style: TextStyle(
                          height: 1.5,
                          fontSize: 13.5,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final accent = dark ? AppColors.wine300 : AppColors.wine;

    return GlassContainer(
      borderRadius: AppColors.radiusTariffCard,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: dark
                  ? AppColors.wine300.withValues(alpha: 0.16)
                  : AppColors.wine100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.auto_awesome_rounded, color: accent, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style:
                  TextStyle(height: 1.6, fontSize: 13.5, color: textColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessRow extends StatelessWidget {
  const _SuccessRow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: dark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(AppColors.radiusSegment),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
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
