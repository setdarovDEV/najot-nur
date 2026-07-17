import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/speech_models.dart';
import '../../shared/widgets/score_ring.dart';
import 'widgets/char_analysis_view.dart';

/// AI pronunciation result, Liquid Glass mockup "3d": score ring on top,
/// glass metric cards with progress bars, transcript card with
/// danger-highlighted mispronounced words, then recommendation cards.
class VoiceResultScreen extends StatefulWidget {
  const VoiceResultScreen({super.key, required this.analysis});
  final VoiceAnalysis analysis;

  @override
  State<VoiceResultScreen> createState() => _VoiceResultScreenState();
}

class _VoiceResultScreenState extends State<VoiceResultScreen> {
  final _scrollOffset = ValueNotifier<double>(0);

  VoiceAnalysis get analysis => widget.analysis;

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

  String _gradeSub(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (analysis.wordErrors.isEmpty) return l.gradePronunciationPerfect;
    if (analysis.wordErrors.length <= 2) return l.gradePronunciationMinor;
    return l.gradePronunciationNeedsWork(analysis.wordErrors.length);
  }

  int get _wordAccuracyScore {
    final totalWords = analysis.referenceText
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    if (totalWords == 0) return 100;
    final errors = analysis.wordErrors.length;
    return ((1 - errors / totalWords) * 100).clamp(0, 100).round();
  }

  int get _avgWordScore {
    if (analysis.wordAnalysis.isEmpty) return analysis.accuracyScore;
    final avg = analysis.wordAnalysis
            .map((w) => w.wordScore)
            .fold<int>(0, (s, v) => s + v) /
        analysis.wordAnalysis.length;
    return avg.round();
  }

  List<InlineSpan> _spans() {
    final text = analysis.referenceText;
    final errors = analysis.errorIndexes;
    final wordRe = RegExp(r"[\w'ʻ']+", unicode: true);
    final spans = <InlineSpan>[];
    int last = 0;
    int wordIndex = 0;
    for (final m in wordRe.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      final isError = errors.contains(wordIndex);
      spans.add(
        TextSpan(
          text: m.group(0),
          style: isError
              ? const TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w800,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.danger,
                )
              : null,
        ),
      );
      last = m.end;
      wordIndex++;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final accent = dark ? AppColors.wine300 : AppColors.wine;
    final topInset = MediaQuery.of(context).padding.top;

    final metrics = [
      _Metric(
        label: l.metricPronunciationAccuracy,
        value: analysis.accuracyScore,
        color: accent,
      ),
      _Metric(
        label: l.metricWordAccuracy,
        value: _wordAccuracyScore,
        color: AppColors.blue,
      ),
      _Metric(
        label: l.metricAvgWordScore,
        value: _avgWordScore,
        color: AppColors.success,
      ),
      if (analysis.phonemeErrors.isNotEmpty)
        _Metric(
          label: l.metricPhonemeErrors,
          value: (100 - analysis.phonemeErrors.length * 8).clamp(0, 100),
          color: AppColors.warning,
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
                          l.voiceAnalysis,
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
                        l.voiceCheck.toUpperCase(),
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
                const SizedBox(height: 10),
                GlassEntrance(
                  delay: nextDelay(),
                  child: Text(
                    _gradeSub(context),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12.5, height: 1.5, color: mutedColor),
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
                  child: _SectionLabel(l.textWithErrors),
                ),
                const SizedBox(height: 10),
                GlassEntrance(
                  delay: nextDelay(),
                  child: GlassContainer(
                    borderRadius: AppColors.radiusTariffCard,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.7,
                              color: textColor,
                            ),
                            children: _spans(),
                          ),
                        ),
                        if (analysis.wordErrors.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: analysis.wordErrors
                                .map(
                                  (e) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 11, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.danger
                                          .withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      e.word,
                                      style: const TextStyle(
                                        color: AppColors.danger,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Belgilangan so\'zlarda talaffuzni yaxshilash mumkin',
                            style: TextStyle(
                                fontSize: 10.5, color: mutedColor),
                          ),
                        ] else ...[
                          const SizedBox(height: 12),
                          _SuccessRow(l.perfectPronunciation),
                        ],
                      ],
                    ),
                  ),
                ),
                if (analysis.hasCharAnalysis) ...[
                  const SizedBox(height: 16),
                  GlassEntrance(
                    delay: nextDelay(),
                    child: _SectionLabel(l.charLevelAnalysis),
                  ),
                  const SizedBox(height: 10),
                  GlassEntrance(
                    delay: nextDelay(),
                    child: CharAnalysisView(analysis: analysis),
                  ),
                ],
                if (analysis.summary.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  GlassEntrance(
                    delay: nextDelay(),
                    child: _SectionLabel(l.overallAnalysis),
                  ),
                  const SizedBox(height: 10),
                  GlassEntrance(
                    delay: nextDelay(),
                    child: _RecommendationCard(text: analysis.summary),
                  ),
                ],
                if (analysis.phonemeErrors.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  GlassEntrance(
                    delay: nextDelay(),
                    child: _SectionLabel(l.soundErrors),
                  ),
                  const SizedBox(height: 10),
                  ...analysis.phonemeErrors.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GlassEntrance(
                        delay: nextDelay(),
                        child: GlassContainer(
                          borderRadius: AppColors.radiusButton,
                          withShadow: false,
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: dark
                                      ? AppColors.wine300
                                          .withValues(alpha: 0.16)
                                      : AppColors.wine100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.record_voice_over_rounded,
                                  color: accent,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l.wordAndSound(
                                        p['word']?.toString() ?? '',
                                        p['sound']?.toString() ?? '',
                                      ),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: textColor,
                                      ),
                                    ),
                                    if ((p['note']?.toString() ?? '')
                                        .isNotEmpty)
                                      Text(
                                        p['note'].toString(),
                                        style: TextStyle(
                                          color: mutedColor,
                                          fontSize: 12.5,
                                          height: 1.4,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
                GlassTopChrome(offset: _scrollOffset, title: l.voiceAnalysis),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets (duplicated locally to avoid cross-feature imports) ───────

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

/// Metric rows in one glass card: label + % + tinted progress bar (mockup 3d).
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

/// AI recommendation glass card with a wine-tinted sparkle chip.
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
