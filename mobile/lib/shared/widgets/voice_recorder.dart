/// Reusable voice recording widget.
///
/// Shows a large record button, animated waveform indicator while recording,
/// playback preview after recording, and an upload/submit callback.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../core/theme/app_colors.dart';

/// Called with the local file path of the recording when the user taps Submit.
typedef OnSubmitRecording = Future<void> Function(String filePath);

class VoiceRecorder extends StatefulWidget {
  const VoiceRecorder({
    super.key,
    required this.onSubmit,
    this.maxSeconds = 120,
    this.referenceText,
  });

  final OnSubmitRecording onSubmit;
  final int maxSeconds;
  final String? referenceText;

  @override
  State<VoiceRecorder> createState() => _VoiceRecorderState();
}

enum _RecorderPhase { idle, recording, preview, submitting, done }

class _VoiceRecorderState extends State<VoiceRecorder>
    with TickerProviderStateMixin {
  final _recorder = AudioRecorder();
  AudioPlayer? _player;

  _RecorderPhase _phase = _RecorderPhase.idle;
  String? _filePath;
  int _elapsed = 0;
  Timer? _timer;
  bool _playerPlaying = false;
  String? _error;

  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _timer?.cancel();
    _pulseCtrl.dispose();
    _recorder.dispose();
    _player?.dispose();
    super.dispose();
  }

  Future<String> _outputPath() async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/practicum_recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
  }

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      setState(() => _error = 'Mikrofon ruxsati berilmagan. Sozlamalardan ruxsat bering.');
      return;
    }
    final path = await _outputPath();
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: path,
    );
    _elapsed = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed++);
      if (_elapsed >= widget.maxSeconds) _stopRecording();
    });
    setState(() {
      _phase = _RecorderPhase.recording;
      _filePath = path;
      _error = null;
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    await _recorder.stop();
    setState(() => _phase = _RecorderPhase.preview);
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    if (_filePath == null) return;
    final p = AudioPlayer();
    await p.setFilePath(_filePath!);
    p.playerStateStream.listen((s) {
      if (!mounted) return;
      setState(() => _playerPlaying = s.playing);
      if (s.processingState == ProcessingState.completed) {
        setState(() => _playerPlaying = false);
        p.seek(Duration.zero);
      }
    });
    setState(() => _player = p);
  }

  Future<void> _togglePlayback() async {
    final p = _player;
    if (p == null) return;
    if (_playerPlaying) {
      await p.pause();
    } else {
      await p.play();
    }
  }

  Future<void> _submit() async {
    if (_filePath == null) return;
    setState(() {
      _phase = _RecorderPhase.submitting;
      _error = null;
    });
    try {
      await widget.onSubmit(_filePath!);
      if (mounted) setState(() => _phase = _RecorderPhase.done);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _phase = _RecorderPhase.preview;
        });
      }
    }
  }

  void _reset() {
    _player?.dispose();
    _player = null;
    setState(() {
      _phase = _RecorderPhase.idle;
      _filePath = null;
      _elapsed = 0;
      _error = null;
    });
  }

  String _fmt(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.referenceText != null) ...[
          _ReferenceTextCard(text: widget.referenceText!),
          const SizedBox(height: 16),
        ],
        _buildRecorderCard(),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildRecorderCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: switch (_phase) {
        _RecorderPhase.idle => _IdleView(onStart: _startRecording),
        _RecorderPhase.recording => _RecordingView(
            elapsed: _elapsed,
            maxSeconds: widget.maxSeconds,
            pulseCtrl: _pulseCtrl,
            onStop: _stopRecording,
            fmt: _fmt,
          ),
        _RecorderPhase.preview => _PreviewView(
            elapsed: _elapsed,
            isPlaying: _playerPlaying,
            onTogglePlay: _togglePlayback,
            onRetry: _reset,
            onSubmit: _submit,
            fmt: _fmt,
          ),
        _RecorderPhase.submitting => const _SubmittingView(),
        _RecorderPhase.done => const _DoneView(),
      },
    );
  }
}

// ── Sub-views ─────────────────────────────────────────────────────────────────

class _IdleView extends StatelessWidget {
  const _IdleView({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onStart,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.wine,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.wine.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.mic_rounded, color: Colors.white, size: 38),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Yozishni boshlash uchun tugmani bosing',
          style: TextStyle(
            color: AppColors.inkSoft,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const Text(
          'O\'zbek tilida aniq va ravshan gapiring',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _RecordingView extends StatelessWidget {
  const _RecordingView({
    required this.elapsed,
    required this.maxSeconds,
    required this.pulseCtrl,
    required this.onStop,
    required this.fmt,
  });
  final int elapsed;
  final int maxSeconds;
  final AnimationController pulseCtrl;
  final VoidCallback onStop;
  final String Function(int) fmt;

  @override
  Widget build(BuildContext context) {
    final progress = elapsed / maxSeconds;
    return Column(
      children: [
        AnimatedBuilder(
          animation: pulseCtrl,
          builder: (_, __) {
            final scale = 1.0 + pulseCtrl.value * 0.18;
            return Transform.scale(
              scale: scale,
              child: GestureDetector(
                onTap: onStop,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.4),
                        blurRadius: 24,
                        spreadRadius: 4 * pulseCtrl.value,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.stop_rounded,
                      color: Colors.white, size: 38),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Text(
          fmt(elapsed),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Colors.red,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.line,
          color: Colors.red.shade600,
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
        const SizedBox(height: 8),
        Text(
          'Yozish davom etmoqda — to\'xtatish uchun bosing',
          style: TextStyle(color: Colors.red.shade400, fontSize: 12),
        ),
      ],
    );
  }
}

class _PreviewView extends StatelessWidget {
  const _PreviewView({
    required this.elapsed,
    required this.isPlaying,
    required this.onTogglePlay,
    required this.onRetry,
    required this.onSubmit,
    required this.fmt,
  });
  final int elapsed;
  final bool isPlaying;
  final VoidCallback onTogglePlay;
  final VoidCallback onRetry;
  final VoidCallback onSubmit;
  final String Function(int) fmt;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: onTogglePlay,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: AppColors.wine,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Yozilgan ovoz',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      fmt(elapsed),
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 22),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Qayta yoz'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.inkSoft,
                  side: const BorderSide(color: AppColors.line),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: onSubmit,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: const Text('Tahlil qilish'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.wine,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SubmittingView extends StatelessWidget {
  const _SubmittingView();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: 8),
        CircularProgressIndicator(color: AppColors.wine),
        SizedBox(height: 16),
        Text(
          'AI tahlil qilmoqda...',
          style: TextStyle(
            color: AppColors.inkSoft,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Bu bir necha soniya olishi mumkin',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _DoneView extends StatelessWidget {
  const _DoneView();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Icon(Icons.check_circle_rounded, color: AppColors.success, size: 54),
        SizedBox(height: 12),
        Text(
          'Ovoz tahlilga yuborildi!',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: AppColors.success,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Natija quyida ko\'rinadi',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
      ],
    );
  }
}

// ── Reference text card ───────────────────────────────────────────────────────

class _ReferenceTextCard extends StatefulWidget {
  const _ReferenceTextCard({required this.text});
  final String text;

  @override
  State<_ReferenceTextCard> createState() => _ReferenceTextCardState();
}

class _ReferenceTextCardState extends State<_ReferenceTextCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
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
                  color: Colors.blue.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.format_quote_rounded,
                    color: Colors.blue, size: 16),
              ),
              const SizedBox(width: 8),
              const Text(
                'O\'qish uchun matn',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: Text(
              widget.text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: AppColors.ink,
              ),
            ),
            secondChild: Text(
              widget.text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? 'Yig\'ish ↑' : 'To\'liq ko\'rish ↓',
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Analysis result display ───────────────────────────────────────────────────

/// Shows the full AI analysis result after submission.
class VoiceAnalysisResult extends StatelessWidget {
  const VoiceAnalysisResult({super.key, required this.submission});
  final dynamic submission; // PracticumSubmission or similar with same fields

  @override
  Widget build(BuildContext context) {
    final score = submission.overallScore ?? 0;
    final accuracy = submission.accuracyScore ?? 0;
    final summary = submission.summary ?? '';
    final wordAnalysis = (submission.wordAnalysis as List?) ?? [];
    final charStats = (submission.charStats as Map<String, dynamic>?) ?? {};
    final phonemeTips = ((charStats['phoneme_tips'] as List?) ?? [])
        .cast<Map<String, dynamic>>();
    final minimalPairs = ((charStats['minimal_pairs'] as List?) ?? [])
        .map((e) => e.toString())
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Score card
        _ScoreCard(score: score, accuracy: accuracy),
        const SizedBox(height: 16),

        // Summary
        if (summary.isNotEmpty) ...[
          _SectionCard(
            icon: Icons.summarize_rounded,
            iconColor: Colors.indigo,
            title: 'Umumiy tahlil',
            child: Text(
              summary,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: AppColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Word-level analysis (highlighted words)
        if (wordAnalysis.isNotEmpty) ...[
          _SectionCard(
            icon: Icons.abc_rounded,
            iconColor: Colors.orange,
            title: 'So\'z tahlili',
            child: _WordAnalysisView(wordAnalysis: wordAnalysis),
          ),
          const SizedBox(height: 12),
        ],

        // Phoneme tips from AI
        if (phonemeTips.isNotEmpty) ...[
          _SectionCard(
            icon: Icons.lightbulb_rounded,
            iconColor: AppColors.wine,
            title: 'Fonem mashqlari',
            child: _PhonemeTipsView(tips: phonemeTips),
          ),
          const SizedBox(height: 12),
        ],

        // Minimal pairs
        if (minimalPairs.isNotEmpty) ...[
          _SectionCard(
            icon: Icons.compare_rounded,
            iconColor: Colors.green,
            title: 'Minimal juftliklar',
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: minimalPairs
                  .map((p) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          p,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.score, required this.accuracy});
  final int score;
  final int accuracy;

  Color get _scoreColor {
    if (score >= 85) return AppColors.success;
    if (score >= 65) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_scoreColor, _scoreColor.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _scoreColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Umumiy ball',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$score%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Aniqlik',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$accuracy%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
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

class _WordAnalysisView extends StatelessWidget {
  const _WordAnalysisView({required this.wordAnalysis});
  final List wordAnalysis;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: wordAnalysis.map((raw) {
        final wa = raw as Map<String, dynamic>;
        final isCorrect = wa['is_correct'] as bool? ?? true;
        final word = wa['reference_word'] as String? ?? '';
        final score = wa['word_score'] as int? ?? 100;
        final comment = wa['ai_comment'] as String?;

        final color = isCorrect
            ? Colors.green
            : score >= 70
                ? Colors.orange
                : Colors.red;

        return Tooltip(
          message: comment ?? (isCorrect ? 'To\'g\'ri' : 'Xato'),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  word,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.85),
                  ),
                ),
                if (!isCorrect) ...[
                  const SizedBox(width: 4),
                  Text(
                    '$score%',
                    style: TextStyle(
                      fontSize: 11,
                      color: color.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PhonemeTipsView extends StatelessWidget {
  const _PhonemeTipsView({required this.tips});
  final List<Map<String, dynamic>> tips;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: tips.map((tip) {
        final char = tip['char'] as String? ?? '';
        final tipText = tip['tip'] as String? ?? '';
        final tongue = tip['tongue_position'] as String?;
        final words = ((tip['practice_words'] as List?) ?? [])
            .map((e) => e.toString())
            .toList();

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.wine.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.wine.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.wine,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          char,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tipText,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                if (tongue != null && tongue.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 13, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          tongue,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (words.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: words
                        .map((w) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: AppColors.line),
                              ),
                              child: Text(
                                w,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
