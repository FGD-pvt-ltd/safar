import 'package:flutter/material.dart';

/// Safar Design System — Three-Layer Token Architecture
/// Conforming to design-system & ui-ux-pro-max skills
class SafarTokens {
  // ==========================================
  // 1. PRIMITIVE TOKENS (Chennai Transit Identity)
  // ==========================================

  // Official SAFAR Brand Palette
  static const Color softMint = Color(0xFFE2F3EF);
  static const Color transitGreen = Color(0xFF19AC8B);
  static const Color warmIvory = Color(0xFFF7F8F5);
  static const Color deepCharcoal = Color(0xFF26332F);
  static const Color mutedSage = Color(0xFFB8D4C7);
  static const Color alertAmber = Color(0xFFD99A36);

  // Emerald & Teal palette (aliases for backward compatibility)
  static const Color tealPrimary = transitGreen;
  static const Color tealDark = Color(0xFF13856B);
  static const Color tealDeep = Color(0xFF0F6652);
  static const Color tealLight = Color(0xFF48D5A0);
  static const Color tealGlow = Color(0x3319AC8B);

  // Neutrals & Backgrounds
  static const Color mintBackground = softMint;
  static const Color surfacePureWhite = Color(0xFFFFFFFF);
  static const Color surfaceGlassWhite = Color(0xF2FFFFFF);
  static const Color surfaceMutedWhite = warmIvory;

  // Typography
  static const Color textDark = deepCharcoal;
  static const Color textCharcoal = Color(0xFF33443F);
  static const Color textMuted = Color(
    0xFF5A7067,
  ); // High-contrast WCAG AA accessible
  static const Color textSubtle = Color(0xFF7E948C);

  // Transit Mode Accent Tokens
  static const Color modeMetro = Color(0xFF0284C7); // Chennai Metro Blue/Cyan
  static const Color modeSuburban = Color(0xFF16A34A); // Suburban Green
  static const Color modeMrts = Color(0xFFD97706); // MRTS Amber/Orange
  static const Color modeBus = Color(0xFFDC2626); // MTC Red
  static const Color modeWalk = Color(0xFF64748B); // Slate grey

  // Legacy Accents & Semantic Alerts
  static const Color accentSunAmber = alertAmber;
  static const Color accentSkyCyan = Color(0xFF38BDF8);
  static const Color accentCoral = Color(0xFFF43F5E);

  // Border & Dividers
  static const Color borderLight = Color(0x1F26332F);
  static const Color borderGlass = Color(0x66FFFFFF);

  // Spacing Scale
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
  static const double space64 = 64.0;

  // Radii
  static const double radiusS = 8.0;
  static const double radiusM = 16.0;
  static const double radiusL = 24.0;
  static const double radiusXL = 32.0;
  static const double radiusFull = 999.0;

  // ==========================================
  // 2. SEMANTIC TOKENS (Purpose aliases)
  // ==========================================
  static const Color primary = transitGreen;
  static const Color onPrimary = Colors.white;
  static const Color background = warmIvory;
  static const Color surface = surfacePureWhite;
  static const Color textPrimary = deepCharcoal;
  static const Color textSecondary = textMuted;
  static const Color ratingStar = alertAmber;

  // ==========================================
  // 3. COMPONENT TOKENS (Styles & Shadows)
  // ==========================================
  static const BoxShadow cardSoftShadow = BoxShadow(
    color: Color(0x0C122B1E),
    blurRadius: 24,
    offset: Offset(0, 10),
    spreadRadius: 0,
  );

  static const BoxShadow buttonGlow = BoxShadow(
    color: Color(0x401EB980),
    blurRadius: 20,
    offset: Offset(0, 8),
    spreadRadius: -2,
  );

  static const BoxShadow floating3DShadow = BoxShadow(
    color: Color(0x1F000000),
    blurRadius: 18,
    offset: Offset(0, 12),
    spreadRadius: -2,
  );
}
