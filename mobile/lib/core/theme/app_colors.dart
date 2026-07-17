import 'package:flutter/material.dart';

/// Najot Nur brand palette (from docs/NN aydentika.pdf).
abstract class AppColors {
  // ───── Brand ─────
  static const wine = Color(0xFF8A1538); // primary
  static const wineDark = Color(0xFF5E0E25);
  static const wineDeep = Color(0xFF3F0918);
  static const orange = Color(0xFFFF5C39); // accent
  static const blue = Color(0xFF5BC2E7); // accent
  static const white = Color(0xFFFFFFFF);

  // ───── Wine tints ─────
  static const wine100 = Color(0xFFF6E7EC);
  static const wine200 = Color(0xFFE9C4D0);
  static const wine300 = Color(0xFFD79CAF);

  // ───── Neutrals ─────
  static const ink = Color(0xFF1C1416);
  static const inkSoft = Color(0xFF4A4044);
  static const muted = Color(0xFF8B8186);
  static const line = Color(0xFFECE6E8);
  static const bg = Color(0xFFFBF8F9);
  static const surface = Color(0xFFFFFFFF);

  // ───── Semantic ─────
  static const success = Color(0xFF1FA971);
  static const danger = Color(0xFFE5484D); // mispronounced word highlight
  static const warning = Color(0xFFF5A524);

  // ───── Gradients ─────
  static const wineGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [wine, wineDark],
  );

  static const heroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [wine, wineDeep],
  );

  // ───── Dark neutrals (Liquid Glass redesign, docs/liquid-glass-redesign-prompt.md) ─────
  // Per the implementation spec: dark mode flips only the neutrals — fill
  // white → wineInk, text ink → wine100, accent → wine300. Brand colors,
  // gradients, and CTAs above stay identical in both modes.
  static const wineInk = Color(0xFF20161A); // dark "surface" neutral
  static const bgDark = Color(0xFF17100F); // (slightly deeper than wineInk)
  static const surfaceDark = wineInk;
  static const inkDarkPrimary = wine100; // #F6E7EC — primary text on dark
  static const mutedDark = wine300; // #D79CAF — secondary text/icons on dark
  static const lineDark = Color(0x1AFFFFFF); // white @ 10%
  static const accentDark = wine300; // active icon/indicator tint on dark

  // ───── Liquid Glass material tokens ─────
  // Blur sigma: cards use the lighter tier, chrome/sheets (nav bar, bottom
  // sheets) use the heavier tier. "subtle"/"heavy" are the clamp range used
  // by scroll-reactive chrome (see GlassMotion).
  static const glassBlurCard = 16.0;
  static const glassBlurCardSubtle = 8.0;
  static const glassBlurCardHeavy = 24.0;
  static const glassBlurChrome = 24.0;
  static const glassBlurChromeSubtle = 12.0;
  static const glassBlurChromeHeavy = 36.0;

  static const glassFillLight = Color(0x8CFFFFFF); // white @ 55%
  static const glassFillDark = Color(0x8C20161A); // wineInk @ 55%
  // Card-tier fill: denser, since cards render WITHOUT a live BackdropFilter
  // (perf) and need more body to read as frosted over the ambient orbs.
  static const cardFillLight = Color(0xD9FFFFFF); // white @ 85%
  static const cardFillDark = Color(0xD920161A); // wineInk @ 85%
  static const glassHighlightLight = Color(0xBFFFFFFF); // white @ 75% (rim)
  static const glassHighlightDark = Color(0x33FFFFFF); // white @ 20% (rim)
  static const glassStrokeLight = Color(0x17000000); // ink-ish @ 9%
  static const glassStrokeDark = Color(0x1AFFFFFF); // white @ 10%
  static const glassShadowLight = Color(0x1A3F0918); // wineDeep @ 10%
  static const glassShadowDark = Color(0x4D000000); // black @ 30%
  static const sheetScrim = Color(0x4D3F0918); // wineDeep @ 30%

  // ───── Corner radius scale ─────
  static const radiusHero = 36.0;
  static const radiusSheet = 34.0;
  static const radiusCard = 28.0;
  static const radiusTariffCard = 24.0;
  static const radiusButton = 20.0;
  static const radiusSegment = 16.0;
}
