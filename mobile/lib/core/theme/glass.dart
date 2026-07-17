import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

/// Liquid Glass material + motion primitives (docs/liquid-glass-redesign-prompt.md,
/// implementation spec in the "Liquid Glass Redesign" mockup batch).
///
/// Performance: a real `BackdropFilter` per surface melts the GPU when a
/// list has a dozen cards (device heat + battery drain). Only the `chrome`
/// tier — the few floating surfaces content actually scrolls behind (nav
/// bar, top chrome, bottom sheets) — pays for a live blur. `card` surfaces
/// fake the frosted look with a more opaque fill + rim highlight, which is
/// visually indistinguishable for a card sitting on the page background.

enum GlassTier { card, chrome }

/// A translucent, blurred surface with a light-catching rim and hairline
/// stroke — the base building block for every glass card/sheet/bar.
class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = AppColors.radiusCard,
    this.tier = GlassTier.card,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.withShadow = true,
    this.alignment,
    this.blurOverride,
  });

  final Widget child;
  final double borderRadius;
  final GlassTier tier;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final bool withShadow;
  final AlignmentGeometry? alignment;
  final double? blurOverride;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final highlight =
        dark ? AppColors.glassHighlightDark : AppColors.glassHighlightLight;
    final stroke = dark ? AppColors.glassStrokeDark : AppColors.glassStrokeLight;
    final shadowColor =
        dark ? AppColors.glassShadowDark : AppColors.glassShadowLight;
    final isChrome = tier == GlassTier.chrome;
    // Cards use a denser fill so they read "frosted" without a live blur.
    final fill = isChrome
        ? (dark ? AppColors.glassFillDark : AppColors.glassFillLight)
        : (dark ? AppColors.cardFillDark : AppColors.cardFillLight);

    final shape = ContinuousRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: BorderSide(color: stroke, width: 0.5),
    );

    Widget surface = Container(
      alignment: alignment,
      padding: padding,
      decoration: ShapeDecoration(
        shape: shape,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.alphaBlend(highlight, fill), fill],
          stops: const [0.0, 0.35],
        ),
      ),
      child: child,
    );

    if (isChrome) {
      // Only chrome pays for a real backdrop blur.
      surface = ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurOverride ?? AppColors.glassBlurChrome,
            sigmaY: blurOverride ?? AppColors.glassBlurChrome,
          ),
          child: surface,
        ),
      );
    }

    return RepaintBoundary(
      child: Container(
        margin: margin,
        width: width,
        height: height,
        decoration: withShadow
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              )
            : null,
        child: surface,
      ),
    );
  }
}

/// Adds the "press in / spring release" feel to any glass or solid control:
/// scales down on touch-down, springs back past 1.0 on release.
class GlassPressable extends StatefulWidget {
  const GlassPressable({
    super.key,
    required this.child,
    this.onTap,
    this.haptic = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool haptic;

  @override
  State<GlassPressable> createState() => _GlassPressableState();
}

class _GlassPressableState extends State<GlassPressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: GlassMotion.pressOut,
    value: 0,
  );
  late final Animation<double> _scale =
      Tween<double>(begin: 1.0, end: 0.97).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pressIn(_) {
    if (widget.onTap == null) return;
    if (widget.haptic) HapticFeedback.lightImpact();
    _controller.animateTo(1.0,
        duration: GlassMotion.pressIn, curve: Curves.easeOut);
  }

  void _release([_]) {
    if (widget.onTap == null) return;
    _controller.animateTo(0.0,
        duration: GlassMotion.pressOut, curve: GlassMotion.pressOutCurve);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: _pressIn,
      onTapUp: _release,
      onTapCancel: _release,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}

/// Shared motion constants so every screen springs/eases/staggers the same
/// way instead of hand-rolled durations scattered per widget.
abstract class GlassMotion {
  static const pressIn = Duration(milliseconds: 120);
  static const pressOut = Duration(milliseconds: 260);
  static const tabMorph = Duration(milliseconds: 320);
  static const sheetPresent = Duration(milliseconds: 420);
  static const scrimBlurIn = Duration(milliseconds: 300);
  static const entranceStagger = Duration(milliseconds: 340);
  static const entranceStep = Duration(milliseconds: 55);
  static const successPop = Duration(milliseconds: 500);
  static const successStroke = Duration(milliseconds: 450);
  static const successStrokeDelay = Duration(milliseconds: 300);
  static const errorShake = Duration(milliseconds: 400);
  static const stepFade = Duration(milliseconds: 260);
  static const stepSlide = Duration(milliseconds: 320);

  static const pressOutCurve = Cubic(0.34, 1.56, 0.64, 1.0); // ≈ easeOutBack
  static const entranceCurve = Cubic(0.2, 0.9, 0.3, 1.15);
  static const stepSlideCurve = Cubic(0.3, 1.25, 0.45, 1.0);
  static const tabMorphCurve = pressOutCurve;

  /// Bottom-sheet presentation spring: mass 1, stiffness 380, damping 26.
  static const sheetSpring = SpringDescription(mass: 1, stiffness: 380, damping: 26);

  /// Scroll-reactive chrome: blur ramps 0→heavy over the first 90px of scroll.
  static double scrollReactiveBlur(double scrollOffset) {
    final t = (scrollOffset / 90).clamp(0.0, 1.0);
    return AppColors.glassBlurChrome * t;
  }
}

/// Staggered entrance: fade + rise (18px) + settle past 1.0, matching the
/// mockups' `rise` keyframe. Give list/grid items an increasing [delay]
/// (multiples of [GlassMotion.entranceStep]) for the cascade effect.
class GlassEntrance extends StatefulWidget {
  const GlassEntrance({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  State<GlassEntrance> createState() => _GlassEntranceState();
}

class _GlassEntranceState extends State<GlassEntrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: GlassMotion.entranceStagger,
  );
  late final CurvedAnimation _curve =
      CurvedAnimation(parent: _controller, curve: GlassMotion.entranceCurve);

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) {
        final t = _curve.value;
        return Opacity(
          opacity: t.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - t)),
            child: Transform.scale(scale: 0.98 + 0.02 * t, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Floating top chrome that fades/blurs in as content scrolls beneath it —
/// the `--k` ramp from the mockups. Overlay it (Stack) above the scrollable
/// and feed it the scroll offset via [offset].
class GlassTopChrome extends StatelessWidget {
  const GlassTopChrome({super.key, required this.offset, required this.title});

  final ValueListenable<double> offset;
  final String title;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fill = dark ? AppColors.glassFillDark : AppColors.glassFillLight;
    final stroke = dark ? AppColors.glassStrokeDark : AppColors.glassStrokeLight;
    final textColor = dark ? AppColors.inkDarkPrimary : AppColors.ink;
    final topInset = MediaQuery.of(context).padding.top;

    // The blur sigma is fixed; only the layer's opacity tracks the scroll.
    // Re-blurring with a new sigma every scrolled pixel forces a full
    // backdrop re-render per frame — a large part of the original jank.
    final bar = ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppColors.glassBlurChrome,
          sigmaY: AppColors.glassBlurChrome,
        ),
        child: Container(
          height: topInset + 44,
          padding: EdgeInsets.only(top: topInset),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: fill,
            border: Border(
              bottom: BorderSide(color: stroke, width: 0.5),
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              color: textColor,
            ),
          ),
        ),
      ),
    );

    return ValueListenableBuilder<double>(
      valueListenable: offset,
      builder: (context, value, child) {
        final k = (value / 90).clamp(0.0, 1.0);
        if (k == 0) return const SizedBox.shrink();
        return IgnorePointer(child: Opacity(opacity: k, child: child));
      },
      child: RepaintBoundary(child: bar),
    );
  }
}

/// Frosted bottom-sheet body (mockup 1c): top-rounded glass chrome with a
/// drag handle. Use inside `showModalBottomSheet(backgroundColor:
/// Colors.transparent, barrierColor: AppColors.sheetScrim, ...)`.
class GlassSheet extends StatelessWidget {
  const GlassSheet({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fill = dark
        ? AppColors.wineInk.withValues(alpha: 0.82)
        : Colors.white.withValues(alpha: 0.78);
    final topBorder = dark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.white.withValues(alpha: 0.8);
    final handleColor = dark
        ? Colors.white.withValues(alpha: 0.25)
        : AppColors.ink.withValues(alpha: 0.15);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppColors.radiusSheet),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: AppColors.glassBlurChrome,
          sigmaY: AppColors.glassBlurChrome,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: fill,
            border: Border(top: BorderSide(color: topBorder, width: 0.5)),
          ),
          padding: padding ?? const EdgeInsets.fromLTRB(18, 10, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: handleColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// The soft, drifting color orbs the mockups place behind every screen's
/// content — brand blue/orange/wine radial glows, heavily blurred. Put this
/// as the bottom layer of a Stack, under the scrollable.
class AmbientOrbs extends StatelessWidget {
  const AmbientOrbs({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    // Dark mode keeps the same hues, slightly dimmer so text stays readable.
    final strength = dark ? 0.7 : 1.0;
    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: Stack(
            children: [
            _orb(
              top: 340, left: -70, size: 230,
              color: AppColors.blue.withValues(alpha: 0.35 * strength),
            ),
            _orb(
              top: 560, right: -60, size: 250,
              color: AppColors.orange.withValues(alpha: 0.30 * strength),
            ),
            _orb(
              top: 700, left: 40, size: 200,
              color: AppColors.wine.withValues(alpha: 0.22 * strength),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _orb({
    double? top,
    double? left,
    double? right,
    required double size,
    required Color color,
  }) {
    // A soft-stopped radial gradient reads the same as the mockups'
    // blur(30px) orbs without paying for an ImageFilter every frame.
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: Container(
        width: size * 1.3,
        height: size * 1.3,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
            stops: const [0.0, 0.85],
          ),
        ),
      ),
    );
  }
}
