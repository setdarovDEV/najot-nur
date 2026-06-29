import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/speech_models.dart';
import '../../shared/widgets/score_ring.dart';
import 'widgets/char_analysis_view.dart';

class VoiceResultScreen extends StatelessWidget {
  const VoiceResultScreen({super.key, required this.analysis});
  final VoiceAnalysis analysis;

  /// Tokenize like the backend ([\w'ʻ’]+) and color error words red.
  List<InlineSpan> _spans() {
    final text = analysis.referenceText;
    final errors = analysis.errorIndexes;
    final wordRe = RegExp(r"[\w'ʻ’]+", unicode: true);
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
    return Scaffold(
      appBar: AppBar(title: Text(l.voiceAnalysis)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: ScoreRing(
              score: analysis.overallScore,
              size: 140,
              label: l.scoreOverallLabel,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              l.accuracyLabel(analysis.accuracyScore),
              style: const TextStyle(
                  color: AppColors.muted, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 28),
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
                    fontSize: 18, height: 1.7, color: AppColors.ink),
                children: _spans(),
              ),
            ),
          ),
          if (analysis.wordErrors.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: analysis.wordErrors
                  .map((e) => Chip(
                        backgroundColor: AppColors.danger.withValues(alpha: 0.1),
                        side: BorderSide.none,
                        label: Text(
                          e.word,
                          style: const TextStyle(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w700),
                        ),
                      ))
                  .toList(),
            ),
          ],
          if (analysis.hasCharAnalysis) ...[
            const SizedBox(height: 28),
            const _SectionTitle('Harf darajasidagi tahlil'),
            const SizedBox(height: 12),
            CharAnalysisView(analysis: analysis),
          ],
          const SizedBox(height: 24),
          _SectionTitle(l.overallAnalysis),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.wine100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(analysis.summary,
                style: const TextStyle(height: 1.5, color: AppColors.ink)),
          ),
          if (analysis.phonemeErrors.isNotEmpty) ...[
            const SizedBox(height: 24),
            _SectionTitle(l.soundErrors),
            const SizedBox(height: 10),
            ...analysis.phonemeErrors.map(
              (p) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.record_voice_over_rounded,
                    color: AppColors.wine),
                title: Text(
                    l.wordAndSound(
                      p['word']?.toString() ?? '',
                      p['sound']?.toString() ?? '',
                    ),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(p['note']?.toString() ?? ''),
              ),
            ),
          ],
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      );
}
