import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Premium light + dark themes. Manrope stands in for Neue Haas Grotesk
/// (geometric, neutral grotesque) until the licensed face is bundled.
///
/// Dark mode (Liquid Glass redesign, docs/liquid-glass-redesign-prompt.md)
/// flips only the neutrals — brand colors, gradients, and CTAs are identical
/// in both themes. See AppColors' "Dark neutrals" / "Liquid Glass material
/// tokens" sections for the exact values.
abstract class AppTheme {
  static ThemeData get light => _build(
        brightness: Brightness.light,
        bg: AppColors.bg,
        surface: AppColors.surface,
        ink: AppColors.ink,
        line: AppColors.line,
        overlayStyle: SystemUiOverlayStyle.dark,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        bg: AppColors.bgDark,
        surface: AppColors.surfaceDark,
        ink: AppColors.inkDarkPrimary,
        line: AppColors.lineDark,
        overlayStyle: SystemUiOverlayStyle.light,
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required Color ink,
    required Color line,
    required SystemUiOverlayStyle overlayStyle,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppColors.wine,
        onPrimary: AppColors.white,
        secondary: AppColors.orange,
        onSecondary: AppColors.white,
        tertiary: AppColors.blue,
        surface: surface,
        onSurface: ink,
        error: AppColors.danger,
        onError: AppColors.white,
      ),
    );

    final text = GoogleFonts.manropeTextTheme(base.textTheme).apply(
      bodyColor: ink,
      displayColor: ink,
    );

    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: overlayStyle,
        foregroundColor: ink,
        titleTextStyle: text.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusCard),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.wine,
          foregroundColor: AppColors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(56),
          // Pill buttons (radiusButton is capsule-scale).
          shape: const StadiumBorder(),
          textStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.wine,
          minimumSize: const Size.fromHeight(56),
          side: const BorderSide(color: AppColors.wine, width: 1.4),
          // Pill buttons (radiusButton is capsule-scale).
          shape: const StadiumBorder(),
          textStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.wine, width: 1.6),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.wine100,
        labelStyle: text.labelLarge?.copyWith(color: AppColors.wine),
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),
      dividerTheme: DividerThemeData(color: line, thickness: 1),
    );
  }
}
