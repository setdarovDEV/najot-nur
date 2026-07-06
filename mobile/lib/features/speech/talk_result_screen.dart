import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/speech_models.dart';

class TalkResultScreen extends StatelessWidget {
  const TalkResultScreen({super.key, required this.analysis});
  final SpeechAnalysis analysis;

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

    final metrics = [
      _Metric(
        label: l.metricVoiceConfidence,
        value: ((analysis.meaningScore + analysis.fluencyScore) ~/ 2),
        color: AppColors.wine,
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

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── Hero card ──────────────────────────────────────────────────────
          _HeroCard(
            score: analysis.overallScore,
            title: _gradeTitle(context),
            subtitle: analysis.summary.isNotEmpty
                ? analysis.summary
                : l.speechAnalysis,
            screenTitle: l.speechAnalysis,
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

                // ── Filler words ──────────────────────────────────────────────
                if (fillers.isNotEmpty) ...[
                  _SectionTitle(l.fillersTitle),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: fillers.entries
                        .map(
                          (e) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${e.key}  ×${e.value}',
                              style: const TextStyle(
                                color: Color(0xFFB87503),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  _SuccessRow(l.noFillers),
                  const SizedBox(height: 20),
                ],

                // ── Strengths ─────────────────────────────────────────────────
                if (analysis.strengths.isNotEmpty) ...[
                  _SectionTitle(l.strengthsTitle),
                  const SizedBox(height: 8),
                  ...analysis.strengths.map(
                    (s) => _BulletRow(text: s, color: AppColors.success),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Improvements ──────────────────────────────────────────────
                if (analysis.improvements.isNotEmpty) ...[
                  _SectionTitle(l.improvementsTitle),
                  const SizedBox(height: 8),
                  ...analysis.improvements.map(
                    (s) => _BulletRow(text: s, color: AppColors.warning),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Summary ───────────────────────────────────────────────────
                if (analysis.summary.isNotEmpty) ...[
                  _SectionTitle(l.summaryTitle),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.wine100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      analysis.summary,
                      style: const TextStyle(height: 1.6, color: AppColors.ink),
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

  Color get _ringColor {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.wine;
    if (score >= 40) return AppColors.warning;
    return AppColors.danger;
  }

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
          // nav row
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
          // score + text row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 100,
                height: 100,
                child: CustomPaint(
                  painter: _WhiteRingPainter(score / 100, _ringColor),
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
  _WhiteRingPainter(this.progress, this.accentColor);
  final double progress;
  final Color accentColor;

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
  bool shouldRepaint(_WhiteRingPainter old) =>
      old.progress != progress || old.accentColor != accentColor;
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

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(height: 1.5)),
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
