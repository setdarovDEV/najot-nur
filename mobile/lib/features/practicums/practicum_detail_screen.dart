import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/glass.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../models/practicum_models.dart';
import '../../providers/providers.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/deep_letter_analysis.dart';
import '../../shared/widgets/enrollment_lock.dart';
import '../../shared/widgets/voice_recorder.dart';

/// Practicum detail, Liquid Glass standalone pattern: floating glass back
/// chrome over ambient orbs, a wine gradient hero, glass cards for the
/// expert audio player / expert text and the voice-practice section.
/// Audio playback, recording submission and enrollment gating are unchanged.
class PracticumDetailScreen extends ConsumerStatefulWidget {
  const PracticumDetailScreen({super.key, required this.practicumId});
  final String practicumId;

  @override
  ConsumerState<PracticumDetailScreen> createState() =>
      _PracticumDetailScreenState();
}

class _PracticumDetailScreenState
    extends ConsumerState<PracticumDetailScreen> {
  final _scrollOffset = ValueNotifier<double>(0);

  @override
  void dispose() {
    _scrollOffset.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);

    final enrollment = ref.watch(enrollmentStatusProvider);
    final isLocked = enrollment.when(
      loading: () => false,
      error: (_, __) => false,
      data: (s) => !s.hasActiveEnrollment && !s.isStaff,
    );

    final async = ref.watch(practicumDetailProvider(widget.practicumId));

    return Scaffold(
      body: Stack(
        children: [
          const AmbientOrbs(),
          async.when(
            loading: () => const AppLoader(),
            error: (e, _) => ErrorView(message: l.errorPrefix(e.toString())),
            data: (p) => NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.axis == Axis.vertical) {
                  _scrollOffset.value = n.metrics.pixels;
                }
                return false;
              },
              child: _Body(
                practicum: p,
                practicumId: widget.practicumId,
                isLocked: isLocked,
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GlassTopChrome(
                offset: _scrollOffset, title: l.practicumsTitle),
          ),
        ],
      ),
    );
  }
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

class _Body extends ConsumerStatefulWidget {
  const _Body({
    required this.practicum,
    required this.practicumId,
    required this.isLocked,
  });
  final Practicum practicum;
  final String practicumId;
  final bool isLocked;

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
    final l = AppLocalizations.of(context);
    final p = widget.practicum;
    final hasAudio = p.expertAudioUrl != null;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final accent = dark ? AppColors.wine300 : AppColors.wine;
    final topInset = MediaQuery.of(context).padding.top;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, topInset + 12, 16, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GlassEntrance(
            child: Row(
              children: [
                _GlassBackButton(
                    onTap: () => Navigator.of(context).maybePop()),
                Expanded(
                  child: Text(
                    l.practicumsTitle,
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

          // ── Hero card (brand gradient, same in both modes) ──
          GlassEntrance(
            delay: GlassMotion.entranceStep,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.wineGradient,
                borderRadius: BorderRadius.circular(AppColors.radiusCard),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.wine.withValues(alpha: 0.30),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
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
                                  color:
                                      Colors.white.withValues(alpha: 0.8),
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
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          p.isFree ? 'Bepul' : 'Pullik',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
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
          ),

          const SizedBox(height: 14),

          // ── Audio player (glass) ──
          if (hasAudio) ...[
            GlassEntrance(
              delay: GlassMotion.entranceStep * 2,
              child: GlassContainer(
                borderRadius: AppColors.radiusTariffCard,
                withShadow: false,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: dark
                                ? AppColors.wine300.withValues(alpha: 0.16)
                                : AppColors.wine.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.record_voice_over_rounded,
                            color: accent,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Ekspert ovozi',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        GlassPressable(
                          onTap: _loading ? null : _togglePlay,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient:
                                  _playing ? AppColors.wineGradient : null,
                              color: _playing
                                  ? null
                                  : (dark
                                      ? AppColors.wine300
                                          .withValues(alpha: 0.16)
                                      : AppColors.wine
                                          .withValues(alpha: 0.10)),
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
                                ? Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: accent,
                                    ),
                                  )
                                : Icon(
                                    _playing
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color:
                                        _playing ? Colors.white : accent,
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
                                  overlayShape:
                                      const RoundSliderOverlayShape(
                                          overlayRadius: 14),
                                  activeTrackColor: accent,
                                  inactiveTrackColor:
                                      accent.withValues(alpha: 0.15),
                                  thumbColor: accent,
                                  overlayColor:
                                      accent.withValues(alpha: 0.15),
                                  trackHeight: 3,
                                ),
                                child: Slider(
                                  min: 0,
                                  max: _duration.inMilliseconds
                                      .toDouble()
                                      .clamp(1, double.infinity),
                                  value: _position.inMilliseconds
                                      .toDouble()
                                      .clamp(
                                          0,
                                          _duration.inMilliseconds
                                              .toDouble()),
                                  onChanged: (v) {
                                    _player?.seek(
                                        Duration(milliseconds: v.toInt()));
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _fmt(_position),
                                      style: TextStyle(
                                        color: mutedColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      _fmt(_duration),
                                      style: TextStyle(
                                        color: mutedColor,
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
            ),
            const SizedBox(height: 14),
          ],

          // ── Expert text (glass) ──
          if (p.expertText != null && p.expertText!.isNotEmpty) ...[
            GlassEntrance(
              delay: GlassMotion.entranceStep * 3,
              child: GlassContainer(
                borderRadius: AppColors.radiusTariffCard,
                withShadow: false,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.blue.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.format_quote_rounded,
                            color: AppColors.blue,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Ekspert matni',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.wine
                            .withValues(alpha: dark ? 0.14 : 0.05),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: SelectableText(
                        p.expertText!,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.7,
                          color: dark
                              ? AppColors.inkDarkPrimary
                                  .withValues(alpha: 0.86)
                              : AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── Voice practice section ──
          GlassEntrance(
            delay: GlassMotion.entranceStep * 4,
            child: p.expertText != null && p.expertText!.isNotEmpty
                ? (widget.isLocked
                    ? _LockedPracticeSection(practicum: p)
                    : _VoicePracticeSection(
                        practicum: p,
                        onSubmit: (filePath) async {
                          await ref
                              .read(practicumRepositoryProvider)
                              .submitVoice(widget.practicumId, filePath);
                          ref.invalidate(myPracticumSubmissionProvider(
                              widget.practicumId));
                        },
                        submissionAsync: ref.watch(
                            myPracticumSubmissionProvider(
                                widget.practicumId)),
                      ))
                : GlassContainer(
                    borderRadius: AppColors.radiusSegment,
                    withShadow: false,
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline_rounded,
                          color: accent,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Ekspert ovozini tinglab, matni bo'yicha o'zingiz mashq qiling.",
                            style: TextStyle(
                              color: accent,
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Section header row shared by the locked/unlocked practice cards.
class _PracticeHeader extends StatelessWidget {
  const _PracticeHeader({required this.locked});
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final accent = dark ? AppColors.wine300 : AppColors.wine;

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            gradient: locked ? null : AppColors.wineGradient,
            color: locked
                ? (dark
                    ? AppColors.wine300.withValues(alpha: 0.16)
                    : AppColors.wine.withValues(alpha: 0.10))
                : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.mic_rounded,
            color: locked ? accent : Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ovozli mashq',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15.5,
                color: textColor,
              ),
            ),
            Text(
              "Matnni o'qing — AI tahlil qiladi",
              style: TextStyle(color: mutedColor, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Locked Practice Section (non-enrolled preview) ───────────────────────────

class _LockedPracticeSection extends StatelessWidget {
  const _LockedPracticeSection({required this.practicum});
  final Practicum practicum;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final accent = dark ? AppColors.wine300 : AppColors.wine;

    return GlassContainer(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _PracticeHeader(locked: true),
          const SizedBox(height: 16),

          // AI preview cards (what they'd get)
          Row(
            children: [
              const _PreviewMetric(
                icon: Icons.stars_rounded,
                label: 'Umumiy ball',
                value: '—/100',
                color: AppColors.wine,
              ),
              const SizedBox(width: 10),
              const _PreviewMetric(
                icon: Icons.track_changes_rounded,
                label: 'Aniqlik',
                value: '—%',
                color: AppColors.blue,
              ),
              const SizedBox(width: 10),
              const _PreviewMetric(
                icon: Icons.spellcheck_rounded,
                label: "Xato so'zlar",
                value: '—',
                color: AppColors.orange,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // AI analysis preview blurred hint
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.wine.withValues(alpha: dark ? 0.14 : 0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 16, color: accent),
                    const SizedBox(width: 6),
                    Text(
                      "AI tahlil ko'rinishi:",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const _BlurredLine(width: double.infinity),
                const SizedBox(height: 6),
                const _BlurredLine(width: 220),
                const SizedBox(height: 6),
                const _BlurredLine(width: 180),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    _BlurredChip(),
                    SizedBox(width: 8),
                    _BlurredChip(width: 80),
                    SizedBox(width: 8),
                    _BlurredChip(width: 60),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Lock icon + message
          Icon(Icons.lock_rounded, size: 36, color: accent),
          const SizedBox(height: 10),
          Text(
            'Ovoz yozish va AI tahlil olish\nuchun kurs sotib oling',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: textColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Kurs egalari:\n• Ovoz yozib topshiradi\n• AI talaffuz tahlilini oladi\n• So'z va fonem xatolarini ko'radi\n• Ekspert ovozi bilan solishtiriladi",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: mutedColor,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 20),

          // CTA button — gradient (glass CTA idiom)
          GlassPressable(
            onTap: () => context.go('/home'),
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: AppColors.wineGradient,
                borderRadius: BorderRadius.circular(AppColors.radiusButton),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.wine.withValues(alpha: 0.30),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.school_outlined, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Kurs sotib olish',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewMetric extends StatelessWidget {
  const _PreviewMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: dark ? 0.14 : 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color.withValues(alpha: 0.6)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: color.withValues(alpha: 0.5),
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: mutedColor, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlurredLine extends StatelessWidget {
  const _BlurredLine({this.width = double.infinity});
  final double width;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = dark ? AppColors.mutedDark : AppColors.muted;
    return Container(
      width: width,
      height: 10,
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

class _BlurredChip extends StatelessWidget {
  const _BlurredChip({this.width = 100});
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.wine.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    final bodyColor = dark
        ? AppColors.inkDarkPrimary.withValues(alpha: 0.82)
        : AppColors.inkSoft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassContainer(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _PracticeHeader(locked: false),
              const SizedBox(height: 14),
              VoiceRecorder(
                onSubmit: onSubmit,
                referenceText: practicum.expertText,
              ),
            ],
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
                  Row(
                    children: [
                      Icon(Icons.history_rounded,
                          size: 18, color: mutedColor),
                      const SizedBox(width: 6),
                      Text(
                        'Oxirgi natija',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: bodyColor,
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
