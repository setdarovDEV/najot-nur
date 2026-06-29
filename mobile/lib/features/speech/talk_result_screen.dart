import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/speech_models.dart';
import '../../shared/widgets/score_ring.dart';

class TalkResultScreen extends StatelessWidget {
  const TalkResultScreen({super.key, required this.analysis});
  final SpeechAnalysis analysis;

  String _balanceText(BuildContext context) {
    final l = AppLocalizations.of(context);
    return switch (analysis.infoBalance) {
      'too_little' => l.balanceTooLittle,
      'too_much' => l.balanceTooMuch,
      _ => l.balanceGood,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final fillers = analysis.fillerWords;
    return Scaffold(
      appBar: AppBar(title: Text(l.speechAnalysis)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: ScoreRing(
                score: analysis.overallScore, size: 140, label: l.scoreOverallLabel),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _MetricBar(
                    label: l.scoreMeaning, value: analysis.meaningScore),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _MetricBar(
                    label: l.scoreFluency, value: analysis.fluencyScore),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.wine100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.balance_rounded, color: AppColors.wine),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(_balanceText(context),
                      style: const TextStyle(
                          color: AppColors.wine, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _Title(l.fillersTitle),
          const SizedBox(height: 10),
          if (fillers.isEmpty)
            Text(l.noFillers,
                style: const TextStyle(color: AppColors.success))
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: fillers.entries
                  .map((e) => Chip(
                        backgroundColor:
                            AppColors.warning.withValues(alpha: 0.12),
                        side: BorderSide.none,
                        label: Text(l.fillerCount(e.key, e.value),
                            style: const TextStyle(
                                color: Color(0xFFB87503),
                                fontWeight: FontWeight.w700)),
                      ))
                  .toList(),
            ),
          if (analysis.strengths.isNotEmpty) ...[
            const SizedBox(height: 24),
            _Title(l.strengthsTitle),
            const SizedBox(height: 8),
            ...analysis.strengths.map((s) => _Bullet(s, AppColors.success)),
          ],
          if (analysis.improvements.isNotEmpty) ...[
            const SizedBox(height: 20),
            _Title(l.improvementsTitle),
            const SizedBox(height: 8),
            ...analysis.improvements.map((s) => _Bullet(s, AppColors.warning)),
          ],
          const SizedBox(height: 24),
          _Title(l.summaryTitle),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.line),
            ),
            child: Text(analysis.summary,
                style: const TextStyle(height: 1.5, color: AppColors.ink)),
          ),
          const SizedBox(height: 28),
          OutlinedButton(
            onPressed: () => context.go('/home'),
            child: Text(l.backToHome),
          ),
        ],
      ),
    );
  }
}

class _MetricBar extends StatelessWidget {
  const _MetricBar({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.muted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('$value',
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.wine)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value / 100,
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

class _Bullet extends StatelessWidget {
  const _Bullet(this.text, this.color);
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text, style: const TextStyle(height: 1.4))),
        ],
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800));
}
