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
}
