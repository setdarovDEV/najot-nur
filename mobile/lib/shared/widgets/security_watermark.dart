import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/security_service.dart';

/// Diagonally-tiled watermark that shows the current security watermark
/// (phone-tail + rotating tag). The text comes from the [SecurityService]
/// and is refreshed whenever the server returns a new value.
///
/// We keep the watermark extremely faint (10% opacity) so it doesn't
/// interfere with the UI but is impossible to crop out — the same string
/// repeats across the entire viewport at a 30° angle, so a partial crop
/// always shows at least one full token.
class SecurityWatermark extends ConsumerStatefulWidget {
  const SecurityWatermark({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<SecurityWatermark> createState() => _SecurityWatermarkState();
}

class _SecurityWatermarkState extends ConsumerState<SecurityWatermark> {
  Timer? _ticker;
  String _stamp = '';

  @override
  void initState() {
    super.initState();
    _stamp = _formatStamp(DateTime.now());
    _ticker = Timer.periodic(
      const Duration(seconds: 30),
      (_) => setState(() => _stamp = _formatStamp(DateTime.now())),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String _formatStamp(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} '
        '${two(t.hour)}:${two(t.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(securityStatusProvider).valueOrNull;
    final wm = status?.watermarkText ?? '';
    if (wm.isEmpty) return widget.child;
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _WatermarkPainter(
                text: wm,
                stamp: _stamp,
                color: Colors.black.withValues(alpha: 0.06),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WatermarkPainter extends CustomPainter {
  _WatermarkPainter({
    required this.text,
    required this.stamp,
    required this.color,
  });

  final String text;
  final String stamp;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: text,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const TextSpan(text: '   '),
          TextSpan(
            text: stamp,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Diagonal layout: paint the same row at 30° angle, then tile it across
    // the screen with 2× spacing so cropping leaves at least one token
    // visible.
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(-math.pi / 6);
    final dx = tp.width + 80;
    final dy = tp.height + 60;
    for (double y = -size.height; y < size.height; y += dy) {
      double x = -size.width;
      // Stagger every other row so vertical alignment doesn't let the user
      // crop a single horizontal band.
      if (((y / dy).round() & 1) == 1) x -= dx / 2;
      while (x < size.width) {
        tp.paint(canvas, Offset(x, y));
        x += dx;
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WatermarkPainter old) =>
      old.text != text || old.stamp != stamp || old.color != color;
}
