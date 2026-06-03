import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// ZIP — Modern Game Design System
/// Philosophy: Vibrant, engaging, smooth animations, addictive feel
class AppTheme {
  AppTheme._();

  // ── Modern Game Palette ────────────────────────────────────────────────────
  static const Color deepPurple   = Color(0xFF1A0B2E);   // deep background
  static const Color richPurple   = Color(0xFF2D1B4E);   // card background
  static const Color vibrantPurple = Color(0xFF6C3AFF);  // primary accent
  static const Color neonPink     = Color(0xFFFF006E);   // secondary accent
  static const Color electricBlue = Color(0xFF00D9FF);   // tertiary accent
  static const Color neonGreen    = Color(0xFF39FF14);   // success
  static const Color warmOrange   = Color(0xFFFF8C42);   // warning/hint
  
  static const Color canvas       = Color(0xFF0F0A1E);   // main background
  static const Color ink          = Color(0xFFFFFFFF);   // white text
  static const Color inkMid       = Color(0xFFE0E0E0);
  static const Color inkLight     = Color(0xFFB0B0B0);
  static const Color inkFaint     = Color(0xFF6B6B6B);
  static const Color accent       = vibrantPurple;
  static const Color accentLight  = Color(0xFF9D7FFF);
  static const Color surface      = richPurple;
  static const Color border       = Color(0xFF3D2B5E);
  static const Color successGreen = neonGreen;
  static const Color errorRed     = neonPink;
  static const Color gold         = Color(0xFFFFD700);

  // ── Backward-compat aliases (game components use these) ───────────────────
  static const Color primaryNeon      = vibrantPurple;
  static const Color secondaryNeon    = neonPink;
  static const Color backgroundDark   = canvas;
  static const Color backgroundLight  = richPurple;
  static const Color primaryBlue      = electricBlue;
  static const Color surfaceDark      = richPurple;
  static const Color surfaceWhite     = surface;
  static const Color surfaceGray      = border;
  static const Color surfaceLight     = border;
  static const Color textPrimary      = ink;
  static const Color textSecondary    = inkMid;
  static const Color textTertiary     = inkLight;
  static const Color success          = successGreen;
  static const Color error            = errorRed;
  static const Color warning          = warmOrange;

  // Vibrant gradients for modern game feel
  static const LinearGradient neonGradient = LinearGradient(
    colors: [vibrantPurple, neonPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient blueGradient = LinearGradient(
    colors: [electricBlue, vibrantPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient successGradient = LinearGradient(
    colors: [neonGreen, Color(0xFF00FF88)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glow effects for addictive UI
  static BoxShadow glowPurple = BoxShadow(
    color: vibrantPurple.withValues(alpha: 0.5),
    blurRadius: 20,
    spreadRadius: 2,
  );
  
  static BoxShadow glowPink = BoxShadow(
    color: neonPink.withValues(alpha: 0.4),
    blurRadius: 20,
    spreadRadius: 2,
  );
  
  static BoxShadow glowBlue = BoxShadow(
    color: electricBlue.withValues(alpha: 0.3),
    blurRadius: 15,
    spreadRadius: 1,
  );

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
      brightness: Brightness.dark,
      scaffoldBackgroundColor: canvas,
      colorScheme: const ColorScheme.dark(
        primary: vibrantPurple,
        secondary: neonPink,
        tertiary: electricBlue,
        error: errorRed,
        surface: richPurple,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.poppins(
          fontSize: 56, fontWeight: FontWeight.w900,
          color: ink, letterSpacing: -2.5, height: 1.0,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 42, fontWeight: FontWeight.w800,
          color: ink, letterSpacing: -1.8, height: 1.05,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 32, fontWeight: FontWeight.w700,
          color: ink, letterSpacing: -1.0, height: 1.1,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 24, fontWeight: FontWeight.w700,
          color: ink, letterSpacing: -0.5,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 20, fontWeight: FontWeight.w600,
          color: ink, letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w600, color: ink,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.w600, color: ink,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16, fontWeight: FontWeight.normal, color: inkMid, height: 1.6,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.normal, color: inkLight, height: 1.5,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 12, fontWeight: FontWeight.normal, color: inkFaint, height: 1.4,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 14, fontWeight: FontWeight.w700,
          color: ink, letterSpacing: 0.5,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18, fontWeight: FontWeight.w700, color: ink,
        ),
        iconTheme: const IconThemeData(color: ink, size: 24),
        actionsIconTheme: const IconThemeData(color: ink, size: 22),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: vibrantPurple,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: const BorderSide(color: border, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: vibrantPurple, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(fontSize: 14, color: inkLight),
        hintStyle: GoogleFonts.poppins(fontSize: 14, color: inkFaint),
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
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border, width: 2),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? vibrantPurple : inkFaint,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) 
              ? vibrantPurple.withValues(alpha: 0.4) 
              : border,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }
}
