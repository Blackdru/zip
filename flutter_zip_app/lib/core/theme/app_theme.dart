import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// ZIP — Design System
/// Philosophy: editorial, minimal. One accent, strong type, no clutter.
class AppTheme {
  AppTheme._();

  // ── Palette ────────────────────────────────────────────────────────────────
  static const Color canvas       = Color(0xFFFAF9F7);   // warm off-white
  static const Color ink          = Color(0xFF111111);   // near-black
  static const Color inkMid       = Color(0xFF444444);
  static const Color inkLight     = Color(0xFF888888);
  static const Color inkFaint     = Color(0xFFCCCCCC);
  static const Color accent       = Color(0xFFE8500A);   // vivid coral-orange
  static const Color accentLight  = Color(0xFFFFF0EA);
  static const Color surface      = Color(0xFFFFFFFF);
  static const Color border       = Color(0xFFE8E4DF);
  static const Color successGreen = Color(0xFF1A7A4A);
  static const Color errorRed     = Color(0xFFCC2200);
  static const Color gold         = Color(0xFFB8860B);

  // ── Backward-compat aliases (game components use these) ───────────────────
  static const Color primaryNeon      = accent;
  static const Color secondaryNeon    = Color(0xFF6C3AFF);
  static const Color backgroundDark   = canvas;
  static const Color backgroundLight  = canvas;
  static const Color primaryBlue      = Color(0xFF2563EB);
  static const Color surfaceDark      = surface;
  static const Color surfaceWhite     = surface;
  static const Color surfaceGray      = border;
  static const Color surfaceLight     = border;
  static const Color textPrimary      = ink;
  static const Color textSecondary    = inkMid;
  static const Color textTertiary     = inkLight;
  static const Color success          = successGreen;
  static const Color error            = errorRed;
  static const Color warning          = Color(0xFFB45309);

  // Gradient kept for components that reference it
  static const LinearGradient neonGradient = LinearGradient(
    colors: [accent, Color(0xFFFF8C42)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient blueGradient = neonGradient;

  // ── Border radius ──────────────────────────────────────────────────────────
  static const double radiusSmall  = 6.0;
  static const double radiusMedium = 10.0;
  static const double radiusLarge  = 14.0;
  static const double radiusXLarge = 20.0;

  // ── Spacing ────────────────────────────────────────────────────────────────
  static const double spacing4  = 4.0;
  static const double spacing8  = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing48 = 48.0;

  // ── Theme ──────────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: canvas,
      colorScheme: const ColorScheme.light(
        primary: accent,
        secondary: ink,
        error: errorRed,
        onSecondary: Colors.white,
        onSurface: ink,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          fontSize: 52, fontWeight: FontWeight.w800,
          color: ink, letterSpacing: -2.0, height: 1.0,
        ),
        displayMedium: GoogleFonts.inter(
          fontSize: 38, fontWeight: FontWeight.w700,
          color: ink, letterSpacing: -1.5, height: 1.05,
        ),
        displaySmall: GoogleFonts.inter(
          fontSize: 28, fontWeight: FontWeight.w700,
          color: ink, letterSpacing: -0.8, height: 1.1,
        ),
        headlineMedium: GoogleFonts.inter(
          fontSize: 22, fontWeight: FontWeight.w600,
          color: ink, letterSpacing: -0.4,
        ),
        headlineSmall: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w600,
          color: ink, letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600, color: ink,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w500, color: ink,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.normal, color: ink, height: 1.55,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.normal, color: inkMid, height: 1.5,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.normal, color: inkLight, height: 1.4,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: ink, letterSpacing: 0.3,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17, fontWeight: FontWeight.w600, color: ink,
        ),
        iconTheme: const IconThemeData(color: ink, size: 22),
        actionsIconTheme: const IconThemeData(color: ink, size: 22),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ink,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.2),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: const BorderSide(color: border, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ink, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorRed, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(fontSize: 14, color: inkLight),
        hintStyle: GoogleFonts.inter(fontSize: 14, color: inkFaint),
        prefixIconColor: inkLight,
        suffixIconColor: inkLight,
      ),
      dividerTheme: const DividerThemeData(
        color: border, thickness: 1, space: 0,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accent : inkFaint,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? accentLight : const Color(0xFFF0EDE9),
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }
}
