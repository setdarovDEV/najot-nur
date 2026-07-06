import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/speech_models.dart';
import 'widgets/char_analysis_view.dart';

class VoiceResultScreen extends StatelessWidget {
  const VoiceResultScreen({super.key, required this.analysis});
  final VoiceAnalysis analysis;

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

    final metrics = [
      _Metric(
        label: l.metricPronunciationAccuracy,
        value: analysis.accuracyScore,
        color: AppColors.wine,
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

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Hero card ──────────────────────────────────────────────────────
          _HeroCard(
            score: analysis.overallScore,
            title: _gradeTitle(context),
            subtitle: _gradeSub(context),
            screenTitle: l.voiceAnalysis,
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Waveform ─────────────────────────────────────────────────
                _WaveformCard(),
                const SizedBox(height: 20),

                // ── Metrics ───────────────────────────────────────────────────
                _SectionTitle(l.analysisMetrics),
                const SizedBox(height: 12),
                _MetricsCard(metrics: metrics),
                const SizedBox(height: 20),

                // ── Text with errors ──────────────────────────────────────────
                _SectionTitle(l.textWithErrors),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                          fontSize: 17, height: 1.7, color: AppColors.ink),
                      children: _spans(),
                    ),
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
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.danger.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              e.word,
                              style: const TextStyle(
                                color: AppColors.danger,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  _SuccessRow(l.perfectPronunciation),
                ],
                const SizedBox(height: 20),

                // ── Letter-by-letter analysis ─────────────────────────────────
                if (analysis.hasCharAnalysis) ...[
                  _SectionTitle(l.charLevelAnalysis),
                  const SizedBox(height: 12),
                  CharAnalysisView(analysis: analysis),
                  const SizedBox(height: 20),
                ],

                // ── Summary ───────────────────────────────────────────────────
                if (analysis.summary.isNotEmpty) ...[
                  _SectionTitle(l.overallAnalysis),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.wine100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      analysis.summary,
                      style: const TextStyle(
                          height: 1.6, color: AppColors.ink),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Phoneme errors ────────────────────────────────────────────
                if (analysis.phonemeErrors.isNotEmpty) ...[
                  _SectionTitle(l.soundErrors),
                  const SizedBox(height: 10),
                  ...analysis.phonemeErrors.map(
                    (p) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.wine.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.record_voice_over_rounded,
                              color: AppColors.wine,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l.wordAndSound(
                                    p['word']?.toString() ?? '',
                                    p['sound']?.toString() ?? '',
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.ink,
                                  ),
                                ),
                                if ((p['note']?.toString() ?? '').isNotEmpty)
                                  Text(
                                    p['note'].toString(),
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 13,
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
                  const SizedBox(height: 20),
                ],

                // ── Back button ────────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.go('/home'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.wine),
                      foregroundColor: AppColors.wine,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(l.backToHome),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.score,
    required this.title,
    required this.subtitle,
    required this.screenTitle,
  });
  final int score;
  final String title;
  final String subtitle;
  final String screenTitle;

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(24, topPad + 16, 24, 30),
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                screenTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CustomPaint(
                  painter: _WhiteRingPainter(score / 100),
                  child: Center(
                    child: Text(
                      '$score',
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.5,
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

class _WhiteRingPainter extends CustomPainter {
  _WhiteRingPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 8;
    final bg = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bg);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(_WhiteRingPainter old) => old.progress != progress;
}

class _WaveformCard extends StatelessWidget {
  static const _heights = [
    0.3, 0.5, 0.8, 0.6, 1.0, 0.7, 0.4, 0.9, 0.6, 0.3,
    0.7, 0.5, 0.8, 0.4, 0.6, 1.0, 0.7, 0.5, 0.3, 0.6,
    0.9, 0.4, 0.7, 0.5, 0.8, 0.6, 0.3, 0.7, 0.9, 0.5,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _heights.map((h) {
          return Container(
            width: 4,
            height: 40 * h,
            decoration: BoxDecoration(
              color: AppColors.wine.withValues(alpha: 0.6 + h * 0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({required this.metrics});
  final List<_Metric> metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
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
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.inkSoft,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${m.value}%',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: m.color,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: m.value / 100,
                        minHeight: 7,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
      );
}

class _SuccessRow extends StatelessWidget {
  const _SuccessRow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
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
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
