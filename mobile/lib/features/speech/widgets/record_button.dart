import 'dart:async';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../core/theme/app_colors.dart';

/// Animated microphone control that records real audio (TZ §5.3).
///
/// Tap to start: requests the mic permission, then captures 16 kHz mono AAC to
/// a temp file. Tap again to stop: returns the file path via [onStop] (or
/// `null` if recording failed / no permission). [onTick] reports elapsed
/// seconds so the caller can show / send the duration.
class RecordButton extends StatefulWidget {
  const RecordButton({super.key, required this.onStop, this.onTick});

  /// Called when recording stops, with the recorded file path (null on error).
  final ValueChanged<String?> onStop;
  final ValueChanged<int>? onTick;

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  final AudioRecorder _recorder = AudioRecorder();
  Timer? _timer;
  bool _recording = false;
  bool _busy = false;
  int _seconds = 0;

  @override
  void dispose() {
    _pulse.dispose();
    _timer?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_busy) return;
    if (_recording) {
      await _stop();
    } else {
      await _start();
    }
  }

  Future<void> _start() async {
    setState(() => _busy = true);
    try {
      if (!await _recorder.hasPermission()) {
        _showError('Mikrofon uchun ruxsat berilmadi.');
        return;
      }
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/notiqai_${DateTime.now().millisecondsSinceEpoch}.m4a';
      // 16 kHz mono — matches the STT minimum (TZ §3.1.1) and keeps files small.
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: path,
      );
      setState(() {
        _recording = true;
        _seconds = 0;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _seconds++);
        widget.onTick?.call(_seconds);
      });
    } catch (e) {
      _showError('Yozishni boshlab bo\'lmadi: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stop() async {
    setState(() => _busy = true);
    _timer?.cancel();
    String? path;
    try {
      path = await _recorder.stop();
    } catch (_) {
      path = null;
    }
    if (mounted) setState(() => _recording = false);
    widget.onStop(path);
    if (mounted) setState(() => _busy = false);
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  String get _label {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = dark ? AppColors.mutedDark : AppColors.muted;
    return Column(
      children: [
        GestureDetector(
          onTap: _toggle,
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (_, child) {
              final scale = _recording ? 1 + _pulse.value * 0.12 : 1.0;
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                gradient: _recording ? null : AppColors.wineGradient,
                color: _recording ? AppColors.danger : null,
                shape: BoxShape.circle,
                border: Border.all(
                  color: dark
                      ? AppColors.glassHighlightDark
                      : AppColors.glassHighlightLight,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_recording ? AppColors.danger : AppColors.wine)
                        .withValues(alpha: 0.40),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: _busy
                  ? const Padding(
                      padding: EdgeInsets.all(28),
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.6),
                    )
                  : Icon(
                      _recording ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _recording ? _label : 'Yozishni boshlash uchun bosing',
          style: TextStyle(
            color: _recording ? AppColors.danger : mutedColor,
            fontWeight: FontWeight.w700,
            fontVariations: const [FontVariation('wght', 700)],
          ),
        ),
      ],
    );
  }
}
