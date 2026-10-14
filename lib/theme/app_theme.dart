import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

class SafarTheme {
  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.plusJakartaSansTextTheme().apply(
      bodyColor: SafarTokens.textDark,
      displayColor: SafarTokens.textDark,
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: SafarTokens.background,
      colorScheme: ColorScheme.light(
        primary: SafarTokens.primary,
        onPrimary: SafarTokens.onPrimary,
        secondary: SafarTokens.mutedSage,
        surface: SafarTokens.surface,
        onSurface: SafarTokens.deepCharcoal,
        error: SafarTokens.accentCoral,
      ),
      textTheme: textTheme.copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.2,
          color: SafarTokens.textDark,
          height: 1.15,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.8,
          color: SafarTokens.textDark,
          height: 1.2,
        ),
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: SafarTokens.textDark,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: SafarTokens.textDark,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: SafarTokens.textDark,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: SafarTokens.textCharcoal,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: SafarTokens.textMuted,
          height: 1.4,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
