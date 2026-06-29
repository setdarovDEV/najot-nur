import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/speech_models.dart';

/// Deep character-level visualization (TZ §3.5.6).
///
/// Renders the reference text with each word tinted by its char-level colour
/// (green / yellow / orange / red). Tapping a word that has errors opens a
/// detail sheet showing the expected vs spoken letters side by side with a
/// ✓ / ✗ / ~ marker and a per-letter tip.
///
/// UI copy here is intentionally Uzbek literals — this is an Uzbek-phonetics
/// feature and the tips themselves arrive from the backend already in Uzbek.
class CharAnalysisView extends StatelessWidget {
  const CharAnalysisView({super.key, required this.analysis});

  final VoiceAnalysis analysis;

  Color _hex(String hex) {
    final v = hex.replaceFirst('#', '');
    return Color(int.parse('FF$v', radix: 16));
  }

  void _openDetail(BuildContext context, WordAnalysis wa) {
    if (wa.charOps.every((o) => !o.isError)) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _WordDetailSheet(analysis: wa, color: _hex(wa.colorHex)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = analysis.referenceText;
    final byIndex = analysis.wordAnalysisByIndex;
    final wordRe = RegExp(r"[\w'ʻ’]+", unicode: true);
    final spans = <InlineSpan>[];
    int last = 0;
    int wordIndex = 0;

    for (final m in wordRe.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      final wa = byIndex[wordIndex];
      if (wa == null || wa.isCorrect) {
        spans.add(TextSpan(text: m.group(0)));
      } else {
        final color = _hex(wa.colorHex);
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: GestureDetector(
              onTap: () => _openDetail(context, wa),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color, width: 1.4),
                ),
                child: Text(
                  m.group(0)!,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.2,
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        );
      }
      last = m.end;
      wordIndex++;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  fontSize: 18, height: 1.9, color: AppColors.ink),
              children: spans,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const _Legend(),
        const SizedBox(height: 6),
        const Text(
          'Xato so\'zga bosib, qaysi harfda xato qilganingizni ko\'ring',
          style: TextStyle(color: AppColors.muted, fontSize: 12.5),
        ),
        if (analysis.topProblemChars.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Eng zaif harflar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: analysis.topProblemChars.map((c) {
              final ch = c['char']?.toString() ?? '';
              final n = c['count']?.toString() ?? '';
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.wine100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('$ch · $n×',
                    style: const TextStyle(
                        color: AppColors.wine, fontWeight: FontWeight.w800)),
              );
            }).toList(),
          ),
        ],
        if (analysis.minimalPairs.isNotEmpty) ...[
          const SizedBox(height: 18),
          const Text('Mashq uchun minimal juftliklar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: analysis.minimalPairs
                .map((p) => Chip(
                      backgroundColor: AppColors.blue.withValues(alpha: 0.12),
                      side: BorderSide.none,
                      label: Text(p,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, color: AppColors.ink)),
                    ))
                .toList(),
          ),
        ],
        if (analysis.phonemeTips.isNotEmpty) ...[
          const SizedBox(height: 18),
          const Text('Tovush bo\'yicha mashqlar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ...analysis.phonemeTips.map((t) => _PhonemeTipCard(tip: t)),
        ],
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget dot(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration:
                  BoxDecoration(color: c, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(width: 4),
            Text(label,
                style:
                    const TextStyle(fontSize: 11.5, color: AppColors.muted)),
          ],
        );
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        dot(const Color(0xFFFFC107), '1–2 harf'),
        dot(const Color(0xFFFF9800), '3+ harf'),
        dot(const Color(0xFFF44336), 'butunlay xato'),
      ],
    );
  }
}

class _PhonemeTipCard extends StatelessWidget {
  const _PhonemeTipCard({required this.tip});
  final Map<String, dynamic> tip;

  @override
  Widget build(BuildContext context) {
    final ch = tip['char']?.toString() ?? '';
    final body = tip['tip']?.toString() ?? '';
    final tongue = tip['tongue_position']?.toString();
    final words = (tip['practice_words'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const [];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                    color: AppColors.wine, shape: BoxShape.circle),
                child: Text(ch,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(body,
                    style: const TextStyle(
                        height: 1.4, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (tongue != null && tongue.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(tongue,
                style:
                    const TextStyle(color: AppColors.muted, fontSize: 13)),
          ],
          if (words.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: words
                  .map((w) => Chip(
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.line),
                        label: Text(w),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bottom sheet: expected vs spoken letters laid out with ✓ / ✗ / ~ markers.
class _WordDetailSheet extends StatelessWidget {
  const _WordDetailSheet({required this.analysis, required this.color});
  final WordAnalysis analysis;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final errorOps = analysis.charOps.where((o) => o.isError).toList();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(4)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(analysis.referenceWord,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${analysis.wordScore}/100',
                      style: TextStyle(
                          color: color, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _CharRow(
              label: 'TO\'G\'RI',
              chars: analysis.charOps
                  .where((o) => o.operation != 'insert')
                  .map((o) => o.expectedChar ?? '')
                  .toList(),
              ops: analysis.charOps
                  .where((o) => o.operation != 'insert')
                  .toList(),
              showExpected: true,
            ),
            const SizedBox(height: 10),
            _CharRow(
              label: 'AYTILDI',
              chars: analysis.charOps
                  .where((o) => o.operation != 'delete')
                  .map((o) => o.spokenChar ?? '')
                  .toList(),
              ops: analysis.charOps
                  .where((o) => o.operation != 'delete')
                  .toList(),
              showExpected: false,
            ),
            if (analysis.aiComment != null &&
                analysis.aiComment!.isNotEmpty) ...[
              const SizedBox(height: 20),
              _CommentCard(
                icon: Icons.auto_awesome_rounded,
                title: 'AI izohi',
                body: analysis.aiComment!,
                color: AppColors.wine,
                background: AppColors.wine100,
              ),
            ],
            if (analysis.recommendation != null &&
                analysis.recommendation!.isNotEmpty) ...[
              const SizedBox(height: 10),
              _CommentCard(
                icon: Icons.tips_and_updates_rounded,
                title: 'Tavsiya',
                body: analysis.recommendation!,
                color: AppColors.success,
                background: AppColors.success.withValues(alpha: 0.08),
              ),
            ],
            const SizedBox(height: 20),
            const Text('Xato harflar',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ...errorOps.map((o) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(_opIcon(o.operation),
                          size: 18, color: AppColors.danger),
                      const SizedBox(width: 8),
                      Expanded(child: Text(o.tip, style: const TextStyle(height: 1.4))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  IconData _opIcon(String op) {
    switch (op) {
      case 'delete':
        return Icons.remove_circle_outline;
      case 'insert':
        return Icons.add_circle_outline;
      case 'transpose':
        return Icons.swap_horiz_rounded;
      default:
        return Icons.close_rounded;
    }
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(title,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w800, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 6),
          Text(body,
              style: const TextStyle(height: 1.5, color: AppColors.ink)),
        ],
      ),
    );
  }
}

class _CharRow extends StatelessWidget {
  const _CharRow({
    required this.label,
    required this.chars,
    required this.ops,
    required this.showExpected,
  });

  final String label;
  final List<String> chars;
  final List<CharOp> ops;
  final bool showExpected;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 64,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.muted)),
        ),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (var i = 0; i < ops.length; i++)
                _CharBox(text: chars[i], op: ops[i]),
            ],
          ),
        ),
      ],
    );
  }
}

class _CharBox extends StatelessWidget {
  const _CharBox({required this.text, required this.op});
  final String text;
  final CharOp op;

  @override
  Widget build(BuildContext context) {
    final isMatch = op.operation == 'match';
    final color = isMatch ? AppColors.success : AppColors.danger;
    return Container(
      width: 34,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isMatch
            ? AppColors.success.withValues(alpha: 0.08)
            : AppColors.danger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Text(
        text.isEmpty ? '·' : text,
        style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w800, color: color),
      ),
    );
  }
}
