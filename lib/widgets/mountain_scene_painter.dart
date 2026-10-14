import 'package:flutter/material.dart';

class MountainScenePainter extends CustomPainter {
  final double parallaxOffsetX;
  final double parallaxOffsetY;
  final double animationProgress;

  MountainScenePainter({
    this.parallaxOffsetX = 0.0,
    this.parallaxOffsetY = 0.0,
    this.animationProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. SKY GRADIENT
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE2F3EB), Color(0xFFEEF8F3), Color(0xFFF9FCFA)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    // Subtle sun flare glow
    final sunGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.4, -0.5),
        radius: 0.8,
        colors: [
          const Color(0xFFFFF7ED).withValues(alpha: 0.8),
          const Color(0xFFE0F2FE).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), sunGlow);

    // 2. DISTANT PEAKS (Deepest Layer - moves least with parallax)
    final dX1 = parallaxOffsetX * 6.0;
    final dY1 = parallaxOffsetY * 4.0;

    final distantPeakPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFA5C5B8), Color(0xFFD4E7DE)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final distantPath = Path()
      ..moveTo(0, h * 0.45)
      ..lineTo(w * 0.25 + dX1, h * 0.22 + dY1)
      ..lineTo(w * 0.5 + dX1, h * 0.38 + dY1)
      ..lineTo(w * 0.75 + dX1, h * 0.18 + dY1)
      ..lineTo(w * 0.95 + dX1, h * 0.32 + dY1)
      ..lineTo(w, h * 0.40)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(distantPath, distantPeakPaint);

    // 3. MIDGROUND DRAMATIC ALPINE CRAGS (Mid Layer)
    final dX2 = parallaxOffsetX * 14.0;
    final dY2 = parallaxOffsetY * 9.0;

    // Mountain 1: Left dramatic cliff
    final leftPeakLight = Path()
      ..moveTo(0, h * 0.15)
      ..lineTo(w * 0.35 + dX2, h * 0.48 + dY2)
      ..lineTo(0, h * 0.65)
      ..close();
    canvas.drawPath(leftPeakLight, Paint()..color = const Color(0xFF869F94));

    final leftPeakFacet = Path()
      ..moveTo(0, h * 0.15)
      ..lineTo(w * 0.2 + dX2, h * 0.35 + dY2)
      ..lineTo(0, h * 0.42)
      ..close();
    canvas.drawPath(leftPeakFacet, Paint()..color = const Color(0xFF6E867B));

    // Mountain 2: Right grand peak (like Passo Rolle / Dolomites)
    final rightPeakPath = Path()
      ..moveTo(w * 0.45 + dX2, h * 0.6)
      ..lineTo(w * 0.82 + dX2, h * 0.25 + dY2)
      ..lineTo(w, h * 0.45)
      ..lineTo(w, h * 0.75)
      ..lineTo(w * 0.6 + dX2, h * 0.7)
      ..close();
    canvas.drawPath(rightPeakPath, Paint()..color = const Color(0xFF758D81));

    // Right peak dark shadow facet
    final rightPeakShadow = Path()
      ..moveTo(w * 0.82 + dX2, h * 0.25 + dY2)
      ..lineTo(w, h * 0.45)
      ..lineTo(w * 0.88 + dX2, h * 0.55 + dY2)
      ..close();
    canvas.drawPath(rightPeakShadow, Paint()..color = const Color(0xFF5A7266));

    // 4. FOREGROUND VALLEY & MEADOW (Green ridge)
    final dX3 = parallaxOffsetX * 24.0;
    final dY3 = parallaxOffsetY * 15.0;

    final meadowPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF65906B), Color(0xFF385E42), Color(0xFF1F3D27)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    final meadowPath = Path()
      ..moveTo(0, h * 0.62)
      ..lineTo(w * 0.38 + dX3, h * 0.72 + dY3)
      ..lineTo(w * 0.75 + dX3, h * 0.68 + dY3)
      ..lineTo(w, h * 0.76)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(meadowPath, meadowPaint);

    // Geometric rock facets on left foreground
    final rockLedge = Path()
      ..moveTo(0, h * 0.45)
      ..lineTo(w * 0.28 + dX3, h * 0.68 + dY3)
      ..lineTo(w * 0.18 + dX3, h * 0.85 + dY3)
      ..lineTo(0, h * 0.95)
      ..close();
    canvas.drawPath(rockLedge, Paint()..color = const Color(0xFF4A6856));

    final rockFacetDark = Path()
      ..moveTo(0, h * 0.55)
      ..lineTo(w * 0.15 + dX3, h * 0.68 + dY3)
      ..lineTo(0, h * 0.78)
      ..close();
    canvas.drawPath(rockFacetDark, Paint()..color = const Color(0xFF32493C));

    // 5. THE ADVENTURER / HIKER (Foreground Focus)
    _drawAdventurer(canvas, size, dX3, dY3);
  }

  void _drawAdventurer(Canvas canvas, Size size, double dX, double dY) {
    final w = size.width;
    final h = size.height;

    // Anchor coordinates for adventurer on ridge
    final cx = w * 0.68 + dX;
    final cy = h * 0.66 + dY;
    final scale = (w / 380).clamp(0.85, 1.3);

    // Hiker shadow on grass
    final shadowPaint = Paint()..color = const Color(0x33102416);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + 4, cy + 98 * scale),
        width: 60 * scale,
        height: 16 * scale,
      ),
      shadowPaint,
    );

    // Legs & Hiking Boots
    final legsPaint = Paint()..color = const Color(0xFF152A20);
    // Left leg
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 16 * scale, cy + 38 * scale, 12 * scale, 58 * scale),
        Radius.circular(4 * scale),
      ),
      legsPaint,
    );
    // Right leg
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + 4 * scale, cy + 38 * scale, 12 * scale, 58 * scale),
        Radius.circular(4 * scale),
      ),
      legsPaint,
    );
    // Boots
    final bootsPaint = Paint()..color = const Color(0xFF0F1E16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 20 * scale, cy + 88 * scale, 18 * scale, 12 * scale),
        Radius.circular(4 * scale),
      ),
      bootsPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + 4 * scale, cy + 88 * scale, 18 * scale, 12 * scale),
        Radius.circular(4 * scale),
      ),
      bootsPaint,
    );

    // Coat / Jacket (Deep Evergreen / Teal)
    final coatPaint = Paint()..color = const Color(0xFF1B4D3E);
    final coatPath = Path()
      ..moveTo(cx - 24 * scale, cy - 10 * scale)
      ..lineTo(cx + 20 * scale, cy - 10 * scale)
      ..lineTo(cx + 24 * scale, cy + 44 * scale)
      ..lineTo(cx - 24 * scale, cy + 44 * scale)
      ..close();
    canvas.drawPath(coatPath, coatPaint);

    // Backpack (Mustard / Golden Yellow with straps)
    final backpackPaint = Paint()..color = const Color(0xFFD99026);
    final backpackRollPaint = Paint()..color = const Color(0xFFB57416);
    // Main pack body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 22 * scale, cy - 24 * scale, 34 * scale, 50 * scale),
        Radius.circular(8 * scale),
      ),
      backpackPaint,
    );
    // Top bedroll
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 26 * scale, cy - 34 * scale, 42 * scale, 12 * scale),
        Radius.circular(6 * scale),
      ),
      backpackRollPaint,
    );
    // Pack pockets & details
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 16 * scale, cy - 4 * scale, 22 * scale, 22 * scale),
        Radius.circular(4 * scale),
      ),
      Paint()..color = const Color(0xFFBF7A1B),
    );

    // Head, Cap & Arm looking out
    // Head / Neck
    canvas.drawCircle(
      Offset(cx - 2 * scale, cy - 36 * scale),
      14 * scale,
      Paint()..color = const Color(0xFFF3C59D),
    );
    // Forest Cap / Beanie
    final capPath = Path()
      ..addArc(
        Rect.fromCircle(
          center: Offset(cx - 2 * scale, cy - 40 * scale),
          radius: 14 * scale,
        ),
        3.14,
        3.14,
      )
      ..lineTo(cx + 18 * scale, cy - 38 * scale)
      ..lineTo(cx - 18 * scale, cy - 38 * scale)
      ..close();
    canvas.drawPath(capPath, Paint()..color = const Color(0xFF17382B));

    // Raised arm holding binoculars/shading eyes (looking into the vast distance)
    final armPath = Path()
      ..moveTo(cx - 4 * scale, cy - 6 * scale)
      ..lineTo(cx + 18 * scale, cy - 30 * scale)
      ..lineTo(cx + 8 * scale, cy - 36 * scale)
      ..lineTo(cx - 12 * scale, cy - 14 * scale)
      ..close();
    canvas.drawPath(armPath, coatPaint);
    // Hand
    canvas.drawCircle(
      Offset(cx + 12 * scale, cy - 34 * scale),
      6 * scale,
      Paint()..color = const Color(0xFFF3C59D),
    );
  }

  @override
  bool shouldRepaint(covariant MountainScenePainter oldDelegate) {
    return oldDelegate.parallaxOffsetX != parallaxOffsetX ||
        oldDelegate.parallaxOffsetY != parallaxOffsetY ||
        oldDelegate.animationProgress != animationProgress;
  }
}
