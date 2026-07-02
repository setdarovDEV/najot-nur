/// Deep letter-by-letter analysis view for voice analysis results.
///
/// Shows:
///  • Expert & user audio players (side-by-side)
///  • Full transcript with per-word color coding
///  • Per-character diff: which letter was wrong, what was said instead, tip
///  • AI per-word comments (when available)
library;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';

/// Compact but rich deep-analysis view rendered below the score card.
///
/// [expertAudioUrl] / [userAudioUrl] are server-relative paths (e.g. "/media/…")
/// and get prefixed with the API base. [referenceText] is the expert's text
/// the user was asked to read; [transcript] is the STT result. [wordAnalysis]
/// is the raw per-word data from the backend (each entry has
/// reference_word / spoken_word / is_correct / word_score / char_ops[]).
class DeepLetterAnalysis extends StatelessWidget {
  const DeepLetterAnalysis({
    super.key,
    required this.expertAudioUrl,
    required this.userAudioUrl,
    required this.referenceText,
    required this.transcript,
    required this.wordAnalysis,
  });

  final String? expertAudioUrl;
  final String? userAudioUrl;
  final String? referenceText;
  final String? transcript;
  final List<dynamic> wordAnalysis;

  String _fullUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${AppConstants.apiUrl}$path';
  }

  @override
  Widget build(BuildContext context) {
    final hasExpertAudio = (expertAudioUrl ?? '').isNotEmpty;
    final hasUserAudio = (userAudioUrl ?? '').isNotEmpty;
    final words = wordAnalysis
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Audio compare ────────────────────────────────────────────────────
        if (hasExpertAudio || hasUserAudio)
          _SectionCard(
            icon: Icons.headphones_rounded,
            iconColor: Colors.indigo,
            title: 'Ovozlarni solishtirish',
            child: Column(
              children: [
                if (hasExpertAudio)
                  _AudioRow(
                    label: 'Ekspert ovozi',
                    color: Colors.blue,
                    url: _fullUrl(expertAudioUrl),
                  ),
                if (hasExpertAudio && hasUserAudio) const SizedBox(height: 12),
                if (hasUserAudio)
                  _AudioRow(
                    label: 'Sizning ovozingiz',
                    color: AppColors.wine,
                    url: _fullUrl(userAudioUrl),
                  ),
              ],
            ),
          ),
        if (hasExpertAudio || hasUserAudio) const SizedBox(height: 12),

        // ── Reference vs transcript text ─────────────────────────────────────
        if ((referenceText ?? '').isNotEmpty || (transcript ?? '').isNotEmpty)
          _SectionCard(
            icon: Icons.text_fields_rounded,
            iconColor: Colors.teal,
            title: 'Matn taqqoslash',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if ((referenceText ?? '').isNotEmpty) ...[
                  const _LabelRow(
                    label: 'Ekspert matni',
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 4),
                  _ReferenceTextBlock(text: referenceText!),
                  const SizedBox(height: 12),
                ],
                if ((transcript ?? '').isNotEmpty) ...[
                  const _LabelRow(
                    label: 'Siz aytgan matn',
                    color: AppColors.wine,
                  ),
                  const SizedBox(height: 4),
                  _ReferenceTextBlock(
                    text: transcript!,
                    isTranscript: true,
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 12),

        // ── Letter-by-letter analysis ────────────────────────────────────────
        if (words.isNotEmpty)
          _SectionCard(
            icon: Icons.search_rounded,
            iconColor: Colors.deepOrange,
            title: 'Harf-harf tahlil',
            child: _LetterByLetterView(words: words),
          ),
      ],
    );
  }
}

// ── Audio row ───────────────────────────────────────────────────────────────

class _AudioRow extends StatelessWidget {
  const _AudioRow({
    required this.label,
    required this.color,
    required this.url,
  });
  final String label;
  final Color color;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.record_voice_over_rounded, color: color, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              InlineAudioPlayer(url: url, color: color),
            ],
          ),
        ),
      ],
    );
  }
}

/// Compact native audio player (no external dependency).
class InlineAudioPlayer extends StatefulWidget {
  const InlineAudioPlayer({super.key, required this.url, required this.color});
  final String url;
  final Color color;

  @override
  State<InlineAudioPlayer> createState() => _InlineAudioPlayerState();
}

class _InlineAudioPlayerState extends State<InlineAudioPlayer> {
  late final AudioPlayer _player = AudioPlayer();
  bool _ready = false;
  bool _playing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _player.playerStateStream.listen((s) {
      if (!mounted) return;
      setState(() => _playing = s.playing);
      if (s.processingState == ProcessingState.completed) {
        _player.seek(Duration.zero);
        setState(() => _playing = false);
      }
    });
    _init();
  }

  Future<void> _init() async {
    try {
      await _player.setUrl(widget.url);
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      if (mounted) setState(() => _error = 'Audio yuklanmadi');
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (!_ready) return;
    if (_playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: _ready ? _toggle : null,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _ready ? widget.color : AppColors.line,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
        Expanded(
          child: _error != null
              ? Text(
                  _error!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                  ),
                )
              : SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 12,
                    ),
                    activeTrackColor: widget.color,
                    inactiveTrackColor: widget.color.withValues(alpha: 0.15),
                    thumbColor: widget.color,
                    overlayColor: widget.color.withValues(alpha: 0.15),
                  ),
                  child: StreamBuilder<Duration>(
                    stream: _player.positionStream,
                    builder: (context, snap) {
                      final pos = snap.data ?? Duration.zero;
                      final dur = _player.duration ?? Duration.zero;
                      final maxMs = dur.inMilliseconds
                          .toDouble()
                          .clamp(1.0, double.infinity);
                      return Slider(
                        min: 0,
                        max: maxMs,
                        value: pos.inMilliseconds
                            .toDouble()
                            .clamp(0.0, maxMs),
                        onChanged: (v) => _player.seek(
                          Duration(milliseconds: v.toInt()),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

// ── Section / label / text block ────────────────────────────────────────────

class _LabelRow extends StatelessWidget {
  const _LabelRow({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ReferenceTextBlock extends StatelessWidget {
  const _ReferenceTextBlock({required this.text, this.isTranscript = false});
  final String text;
  final bool isTranscript;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: isTranscript ? AppColors.ink : AppColors.inkSoft,
          fontStyle: isTranscript ? FontStyle.italic : FontStyle.normal,
        ),
      ),
    );
  }
}

// ── Letter-by-letter view ───────────────────────────────────────────────────

class _LetterByLetterView extends StatefulWidget {
  const _LetterByLetterView({required this.words});
  final List<Map<String, dynamic>> words;

  @override
  State<_LetterByLetterView> createState() => _LetterByLetterViewState();
}

class _LetterByLetterViewState extends State<_LetterByLetterView> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final errored = widget.words
        .asMap()
        .entries
        .where((e) => e.value['is_correct'] != true)
        .toList();

    if (errored.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ajoyib! Barcha so\'zlar to\'g\'ri talaffuz qilindi.',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            '${errored.length} ta so\'zda xatolik topildi. Tafsilotlarni ko\'rish uchun bosing:',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.muted,
            ),
          ),
        ),
        ...errored.map((entry) {
          final i = entry.key;
          final wa = entry.value;
          return _WordDetailCard(
            key: ValueKey('word-detail-$i'),
            wordIndex: i,
            wordData: wa,
            expanded: _expandedIndex == i,
            onToggle: () => setState(() {
              _expandedIndex = _expandedIndex == i ? null : i;
            }),
          );
        }),
      ],
    );
  }
}

class _WordDetailCard extends StatelessWidget {
  const _WordDetailCard({
    super.key,
    required this.wordIndex,
    required this.wordData,
    required this.expanded,
    required this.onToggle,
  });
  final int wordIndex;
  final Map<String, dynamic> wordData;
  final bool expanded;
  final VoidCallback onToggle;

  Color get _color {
    final score = (wordData['word_score'] as num?)?.toInt() ?? 0;
    if (score >= 85) return Colors.green;
    if (score >= 65) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final refWord = (wordData['reference_word'] ?? '').toString();
    final spoken = (wordData['spoken_word'] ?? '').toString();
    final aiComment = (wordData['ai_comment'] ?? '').toString();
    final rec = (wordData['recommendation'] ?? '').toString();
    final charOps = ((wordData['char_ops'] as List?) ?? [])
        .cast<Map<String, dynamic>>();
    final score = (wordData['word_score'] as num?)?.toInt() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${wordIndex + 1}',
                        style: TextStyle(
                          color: _color,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          refWord,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        if (spoken.isNotEmpty && spoken != refWord)
                          Text(
                            'Aytildi: $spoken',
                            style: TextStyle(
                              fontSize: 12,
                              color: _color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$score',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: _color,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1, color: AppColors.line),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (charOps.isNotEmpty) ...[
                    const Text(
                      'Harflar taqqoslash:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _CharDiffView(refWord: refWord, charOps: charOps),
                    const SizedBox(height: 10),
                  ],
                  if (aiComment.isNotEmpty) ...[
                    _InfoRow(
                      icon: Icons.info_outline_rounded,
                      color: Colors.indigo,
                      label: aiComment,
                    ),
                    const SizedBox(height: 6),
                  ],
                  if (rec.isNotEmpty)
                    _InfoRow(
                      icon: Icons.tips_and_updates_rounded,
                      color: AppColors.wine,
                      label: rec,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Renders the reference word letter by letter, with the spoken char shown
/// beneath each wrong position and a color code (red/green) for ops.
class _CharDiffView extends StatelessWidget {
  const _CharDiffView({required this.refWord, required this.charOps});
  final String refWord;
  final List<Map<String, dynamic>> charOps;

  Color _opColor(String op) {
    switch (op) {
      case 'match':
        return Colors.green;
      case 'substitute':
        return Colors.red;
      case 'delete':
        return Colors.deepOrange;
      case 'insert':
        return Colors.orange;
      case 'transpose':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _opLabel(String op) {
    switch (op) {
      case 'match':
        return 'to\'g\'ri';
      case 'substitute':
        return 'almashgan';
      case 'delete':
        return 'tushirib qoldirilgan';
      case 'insert':
        return 'ortiqcha';
      case 'transpose':
        return 'almashtirilgan';
      default:
        return op;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Group ops by position so we can show one tile per reference letter.
    final byPos = <int, List<Map<String, dynamic>>>{};
    for (final op in charOps) {
      final pos = (op['position'] as num?)?.toInt() ?? 0;
      byPos.putIfAbsent(pos, () => []).add(op);
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(refWord.length, (i) {
        final ops = byPos[i] ?? [];
        final isMatch = ops.length == 1 && ops.first['operation'] == 'match';
        final color = isMatch ? Colors.green : Colors.red;

        return Container(
          width: 56,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              Text(
                refWord[i],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              if (!isMatch) ...[
                const SizedBox(height: 2),
                Text(
                  '↓',
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
                Text(
                  ops
                      .map((o) =>
                          (o['spoken_char'] ?? '∅').toString())
                      .join('/'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                Text(
                  _opLabel(ops.first['operation'].toString()),
                  style: TextStyle(
                    fontSize: 9,
                    color: _opColor(ops.first['operation'].toString()),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.color,
    required this.label,
  });
  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Section card (matches existing styling) ─────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.child,
  });
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
