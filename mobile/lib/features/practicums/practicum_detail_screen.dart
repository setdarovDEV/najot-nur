import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/practicum_models.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/deep_letter_analysis.dart';
import '../../shared/widgets/voice_recorder.dart';

class PracticumDetailScreen extends ConsumerWidget {
  const PracticumDetailScreen({super.key, required this.practicumId});
  final String practicumId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final async = ref.watch(practicumDetailProvider(practicumId));

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(l.practicumsTitle),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l.errorPrefix(e.toString()))),
        data: (p) => _Body(practicum: p, practicumId: practicumId),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.practicum, required this.practicumId});
  final Practicum practicum;
  final String practicumId;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  AudioPlayer? _player;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _loading = false;
  StreamSubscription? _posSub;
  StreamSubscription? _durSub;
  StreamSubscription? _stateSub;

  String get _fullAudioUrl {
    final url = widget.practicum.expertAudioUrl;
    if (url == null) return '';
    if (url.startsWith('http')) return url;
    return '${AppConstants.apiUrl}$url';
  }

  Future<void> _initPlayer() async {
    if (_player != null) return;
    final url = _fullAudioUrl;
    if (url.isEmpty) return;
    setState(() => _loading = true);
    try {
      final p = AudioPlayer();
      await p.setUrl(url);
      _posSub = p.positionStream.listen((pos) {
        if (mounted) setState(() => _position = pos);
      });
      _durSub = p.durationStream.listen((dur) {
        if (mounted && dur != null) setState(() => _duration = dur);
      });
      _stateSub = p.playerStateStream.listen((s) {
        if (mounted) {
          setState(() => _playing = s.playing);
          if (s.processingState == ProcessingState.completed) {
            setState(() {
              _playing = false;
              _position = Duration.zero;
            });
            p.seek(Duration.zero);
          }
        }
      });
      setState(() {
        _player = p;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _togglePlay() async {
    if (_player == null) {
      await _initPlayer();
    }
    final p = _player;
    if (p == null) return;
    if (_playing) {
      await p.pause();
    } else {
      await p.play();
    }
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _durSub?.cancel();
    _stateSub?.cancel();
    _player?.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.practicum;
    final hasAudio = p.expertAudioUrl != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.wine,
                  AppColors.wine.withValues(alpha: 0.75),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.wine.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.headphones_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (p.category != null)
                            Text(
                              p.category!,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          Text(
                            p.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        p.isFree ? 'Bepul' : 'Pullik',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (p.description != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    p.description!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Audio player
          if (hasAudio)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.wine.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.record_voice_over_rounded,
                          color: AppColors.wine,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Ekspert ovozi',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _loading ? null : _togglePlay,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: _playing
                                ? AppColors.wine
                                : AppColors.wine.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            boxShadow: _playing
                                ? [
                                    BoxShadow(
                                      color: AppColors.wine
                                          .withValues(alpha: 0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : null,
                          ),
                          child: _loading
                              ? const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.wine,
                                  ),
                                )
                              : Icon(
                                  _playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: _playing
                                      ? Colors.white
                                      : AppColors.wine,
                                  size: 28,
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SliderTheme(
                              data: SliderThemeData(
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 6),
                                overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 14),
                                activeTrackColor: AppColors.wine,
                                inactiveTrackColor:
                                    AppColors.wine.withValues(alpha: 0.15),
                                thumbColor: AppColors.wine,
                                overlayColor:
                                    AppColors.wine.withValues(alpha: 0.15),
                                trackHeight: 3,
                              ),
                              child: Slider(
                                min: 0,
                                max: _duration.inMilliseconds.toDouble().clamp(
                                    1, double.infinity),
                                value: _position.inMilliseconds
                                    .toDouble()
                                    .clamp(0,
                                        _duration.inMilliseconds.toDouble()),
                                onChanged: (v) {
                                  _player?.seek(
                                      Duration(milliseconds: v.toInt()));
                                },
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _fmt(_position),
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    _fmt(_duration),
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          if (hasAudio) const SizedBox(height: 16),

          // Expert text
          if (p.expertText != null && p.expertText!.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.format_quote_rounded,
                          color: Colors.blue,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Ekspert matni',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: SelectableText(
                      p.expertText!,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.7,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Voice practice section (only when reference text exists)
          if (p.expertText != null && p.expertText!.isNotEmpty)
            _VoicePracticeSection(
              practicum: p,
              onSubmit: (filePath) async {
                await ref
                    .read(practicumRepositoryProvider)
                    .submitVoice(widget.practicumId, filePath);
                ref.invalidate(myPracticumSubmissionProvider(widget.practicumId));
              },
              submissionAsync:
                  ref.watch(myPracticumSubmissionProvider(widget.practicumId)),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.wine.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.wine.withValues(alpha: 0.15),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: AppColors.wine,
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ekspert ovozini tinglab, matni bo\'yicha o\'zingiz mashq qiling.',
                      style: TextStyle(
                        color: AppColors.wine,
                        fontSize: 13,
                        height: 1.5,
                      ),
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

// ── Voice Practice Section ───────────────────────────────────────────────────

class _VoicePracticeSection extends StatelessWidget {
  const _VoicePracticeSection({
    required this.practicum,
    required this.onSubmit,
    required this.submissionAsync,
  });
  final Practicum practicum;
  final OnSubmitRecording onSubmit;
  final AsyncValue<PracticumSubmission?> submissionAsync;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.wine.withValues(alpha: 0.08),
                AppColors.wine.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: AppColors.wine.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.wine,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.mic_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ovozli mashq',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    'Matnni o\'qing — AI tahlil qiladi',
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            border: Border(
              left: BorderSide(color: AppColors.wine.withValues(alpha: 0.15)),
              right: BorderSide(color: AppColors.wine.withValues(alpha: 0.15)),
              bottom: BorderSide(color: AppColors.wine.withValues(alpha: 0.15)),
            ),
          ),
          child: VoiceRecorder(
            onSubmit: onSubmit,
            referenceText: practicum.expertText,
          ),
        ),

        // Previous submission result
        submissionAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.wine),
              ),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (sub) {
            if (sub == null || !sub.isDone) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.history_rounded,
                          size: 18, color: AppColors.muted),
                      SizedBox(width: 6),
                      Text(
                        'Oxirgi natija',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  VoiceAnalysisResult(submission: sub),
                  const SizedBox(height: 16),
                  DeepLetterAnalysis(
                    expertAudioUrl: practicum.expertAudioUrl,
                    userAudioUrl: sub.audioUrl,
                    referenceText: practicum.expertText,
                    transcript: sub.transcript,
                    wordAnalysis: sub.wordAnalysis ?? const [],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
