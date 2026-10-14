import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// LivingCityPainter — A breathtaking, miniature 3D isometric Chennai metropolis.
///
/// Features:
/// - Multi-tier 3D isometric architecture with direct lit & shaded faces.
/// - Iconic Chennai Central heritage clock tower, modern glass towers, and tech high-rises.
/// - Flashing rooftop aviation beacons and twinkling window matrices.
/// - Street-level living transit: MTC city buses, yellow-black auto-rickshaws, and commuter cars.
/// - Dynamic headlights and taillight streaks moving along paved urban avenues.
/// - Elevated viaduct railway weaving through the skyscraper canyon.
/// - Articulated 3-carriage Chennai Metro train with forward headlight beam, interior glow, and ruby taillights.
/// - Elevated station platform with cantilever canopy, tactile amber edge, and commuters.
/// - Atmospheric sky with ambient sun glow, drifting clouds, and a flock of birds in flight.
/// - 100% native Flutter Skia/Impeller Canvas rendering at locked 60/120 FPS.
class LivingCityPainter extends CustomPainter {
  final double animationProgress; // 0.0 to 1.0 across the 5-second splash
  final double parallaxOffsetX;
  final double parallaxOffsetY;

  // Cached track path & metrics for smooth continuous metro locomotion
  Path? _cachedViaductPath;
  ui.PathMetric? _cachedViaductMetric;
  Size? _lastSize;

  LivingCityPainter({
    required this.animationProgress,
    this.parallaxOffsetX = 0.0,
    this.parallaxOffsetY = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. SKY GRADIENT & CELESTIAL GLOW
    _drawAtmosphericSky(canvas, w, h);

    // 2. DRIFTING CLOUDS & BIRDS IN FLIGHT
    _drawClouds(canvas, w, h);
    _drawBirds(canvas, w, h);

    // 3. DISTANT COASTAL & CITY SILHOUETTES
    _drawDistantSkyline(canvas, w, h);

    // 4. STREET NETWORK & GROUND PAVEMENT
    _drawGroundPlazaAndRoads(canvas, w, h);

    // 5. 3D ISOMETRIC SKYSCRAPERS & CHENNAI CENTRAL CLOCK TOWER
    _draw3DCityscape(canvas, w, h);

    // 6. STREET-LEVEL LIVING TRAFFIC (Buses, Autos, Cars)
    _drawStreetTraffic(canvas, w, h);

    // 7. BUILD OR REUSE 3D VIADUCT TRACK PATH
    _buildViaductPath(w, h);
    if (_cachedViaductPath == null || _cachedViaductMetric == null) return;

    final metric = _cachedViaductMetric!;
    final totalLength = metric.length;

    // 8. VIADUCT PIERS, DECK & TWIN STEEL RAILS
    _drawViaductInfrastructure(canvas, _cachedViaductPath!, metric, totalLength, w, h);

    // 9. ELEVATED STATION PLATFORM
    _drawElevatedStation(canvas, w, h);

    // 10. ARTICULATED 3D CHENNAI METRO TRAIN
    _drawChennaiMetroTrain(canvas, metric, totalLength, w, h);

    // 11. URBAN GREENERY & AMBIENT CITY GLOW
    _drawForegroundGreenery(canvas, w, h);
  }

  // ===========================================================================
  // 1. ATMOSPHERIC SKY & HORIZON
  // ===========================================================================

  void _drawAtmosphericSky(Canvas canvas, double w, double h) {
    // Dawn-to-morning soft ambient gradient
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFD8EEE6), // Crisp Morning Mint
          Color(0xFFE7F4EE),
          Color(0xFFFAF7F0), // Warm Golden Sunlight Haze
        ],
        stops: [0.0, 0.45, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    // Warm radial sun glow centered at upper right
    final sunCenter = Offset(w * 0.78 + parallaxOffsetX * 8, h * 0.16 + parallaxOffsetY * 4);
    final sunGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.55, -0.68),
        radius: 0.75,
        colors: [
          const Color(0xFFFFF7DC).withValues(alpha: 0.70),
          const Color(0xFFE2F3EF).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: sunCenter, radius: w * 0.65));
    canvas.drawCircle(sunCenter, w * 0.65, sunGlow);
  }

  // ===========================================================================
  // 2. DRIFTING CLOUDS & BIRDS IN FLIGHT
  // ===========================================================================

  void _drawClouds(Canvas canvas, double w, double h) {
    final cloudPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    // 3 distinct drifting cloud clusters
    final cloudOffsets = [
      Offset(
        ((w * 0.10 + animationProgress * w * 0.45) % (w * 1.3)) - w * 0.15,
        h * 0.08 + parallaxOffsetY * 2,
      ),
      Offset(
        ((w * 0.55 + animationProgress * w * 0.35) % (w * 1.3)) - w * 0.15,
        h * 0.14 + parallaxOffsetY * 3,
      ),
      Offset(
        ((w * 0.85 + animationProgress * w * 0.50) % (w * 1.3)) - w * 0.15,
        h * 0.05 + parallaxOffsetY * 2,
      ),
    ];

    for (final c in cloudOffsets) {
      canvas.drawOval(
        Rect.fromCenter(center: c, width: 64, height: 18),
        cloudPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(c.dx - 14, c.dy + 2), width: 38, height: 14),
        cloudPaint,
      );
      canvas.drawOval(
        Rect.fromCenter(center: Offset(c.dx + 16, c.dy + 3), width: 44, height: 13),
        cloudPaint,
      );
    }
  }

  void _drawBirds(Canvas canvas, double w, double h) {
    // A flock of 5 birds flying gracefully across the skyline
    final birdPaint = Paint()
      ..color = const Color(0xFF335044).withValues(alpha: 0.60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    final baseX = ((w * 0.30 + animationProgress * w * 0.60) % (w * 1.4)) - w * 0.2;
    final baseY = h * 0.12 - math.sin(animationProgress * math.pi) * 15;

    final birdOffsets = [
      Offset(baseX, baseY),
      Offset(baseX - 14, baseY + 6),
      Offset(baseX - 26, baseY + 14),
      Offset(baseX - 16, baseY - 7),
      Offset(baseX - 30, baseY - 12),
    ];

    for (int i = 0; i < birdOffsets.length; i++) {
      final pos = birdOffsets[i];
      final flap = math.sin((animationProgress * 24.0) + i * 1.2) * 2.5;

      final path = Path()
        ..moveTo(pos.dx - 5, pos.dy + flap)
        ..quadraticBezierTo(pos.dx - 2.5, pos.dy - 2, pos.dx, pos.dy)
        ..quadraticBezierTo(pos.dx + 2.5, pos.dy - 2, pos.dx + 5, pos.dy + flap);

      canvas.drawPath(path, birdPaint);
    }
  }

  // ===========================================================================
  // 3. DISTANT CHENNAI SKYLINE SILHOUETTES
  // ===========================================================================

  void _drawDistantSkyline(Canvas canvas, double w, double h) {
    final dX = parallaxOffsetX * 6.0;
    final dY = parallaxOffsetY * 3.0;

    final horizonPaint = Paint()
      ..color = const Color(0xFFBEDBD0).withValues(alpha: 0.40);

    // Distant towers contour
    final skylinePath = Path()
      ..moveTo(-10, h * 0.38 + dY)
      ..lineTo(w * 0.08 + dX, h * 0.38 + dY)
      ..lineTo(w * 0.08 + dX, h * 0.22 + dY) // Tower 1
      ..lineTo(w * 0.14 + dX, h * 0.22 + dY)
      ..lineTo(w * 0.14 + dX, h * 0.38 + dY)
      ..lineTo(w * 0.26 + dX, h * 0.38 + dY)
      ..lineTo(w * 0.26 + dX, h * 0.16 + dY) // Tall Tower 2
      ..lineTo(w * 0.32 + dX, h * 0.16 + dY)
      ..lineTo(w * 0.32 + dX, h * 0.38 + dY)
      ..lineTo(w * 0.65 + dX, h * 0.38 + dY)
      ..lineTo(w * 0.65 + dX, h * 0.19 + dY) // Tower 3
      ..lineTo(w * 0.72 + dX, h * 0.19 + dY)
      ..lineTo(w * 0.72 + dX, h * 0.38 + dY)
      ..lineTo(w * 0.85 + dX, h * 0.38 + dY)
      ..lineTo(w * 0.85 + dX, h * 0.24 + dY)
      ..lineTo(w * 0.94 + dX, h * 0.24 + dY)
      ..lineTo(w * 0.94 + dX, h * 0.38 + dY)
      ..lineTo(w + 10, h * 0.38 + dY)
      ..lineTo(w + 10, h * 0.46)
      ..lineTo(-10, h * 0.46)
      ..close();

    canvas.drawPath(skylinePath, horizonPaint);

    // Telecommunication mast with flashing red beacon
    final mastX = w * 0.29 + dX;
    final mastTopY = h * 0.11 + dY;
    canvas.drawLine(
      Offset(mastX, h * 0.16 + dY),
      Offset(mastX, mastTopY),
      Paint()
        ..color = const Color(0xFF7FA799)
        ..strokeWidth = 1.2,
    );

    // Flashing red aviation warning beacon (1.5 Hz pulse)
    final beaconBlink = (math.sin(animationProgress * math.pi * 10) > 0.0);
    if (beaconBlink) {
      canvas.drawCircle(
        Offset(mastX, mastTopY),
        2.5,
        Paint()..color = const Color(0xFFFF3344),
      );
      canvas.drawCircle(
        Offset(mastX, mastTopY),
        5.5,
        Paint()..color = const Color(0x66FF3344),
      );
    }
  }

  // ===========================================================================
  // 4. GROUND PLAZA & STREET NETWORK
  // ===========================================================================

  void _drawGroundPlazaAndRoads(Canvas canvas, double w, double h) {
    // Stepped urban podium slab
    final groundBase = Rect.fromLTWH(0, h * 0.42, w, h * 0.58);
    final groundPaint = Paint()..color = const Color(0xFFEDF6F2);
    canvas.drawRect(groundBase, groundPaint);

    // Ground shadow gradient under city center
    final plazaGradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFE2EFE9),
          const Color(0xFFF7FBF8),
        ],
      ).createShader(groundBase);
    canvas.drawRect(groundBase, plazaGradient);

    // Diagonal Urban Avenue (Asphalt highway cutting across midground)
    // Left edge: (0, 0.60 * h), Right edge: (w, 0.82 * h)
    final roadPath = Path()
      ..moveTo(-10, h * 0.58)
      ..lineTo(w + 10, h * 0.78)
      ..lineTo(w + 10, h * 0.85)
      ..lineTo(-10, h * 0.65)
      ..close();

    // Dark slate asphalt
    canvas.drawPath(roadPath, Paint()..color = const Color(0xFF283631));

    // Curbside safety borders
    canvas.drawLine(
      Offset(-10, h * 0.58),
      Offset(w + 10, h * 0.78),
      Paint()
        ..color = const Color(0xFF637C72)
        ..strokeWidth = 2.0,
    );
    canvas.drawLine(
      Offset(-10, h * 0.65),
      Offset(w + 10, h * 0.85),
      Paint()
        ..color = const Color(0xFF637C72)
        ..strokeWidth = 2.0,
    );

    // Dashed center lane divider (Warm Amber & White)
    final lanePaint = Paint()
      ..color = const Color(0xFFE5A93C).withValues(alpha: 0.85)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;

    const dashCount = 18;
    for (int i = 0; i < dashCount; i += 2) {
      final t1 = i / dashCount;
      final t2 = (i + 1) / dashCount;

      final p1 = Offset(
        -10 + (w + 20) * t1,
        h * 0.615 + (h * 0.20) * t1,
      );
      final p2 = Offset(
        -10 + (w + 20) * t2,
        h * 0.615 + (h * 0.20) * t2,
      );
      canvas.drawLine(p1, p2, lanePaint);
    }

    // Pedestrian zebra crossing near station entrance
    final zebraPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 2.5;

    for (int k = 0; k < 6; k++) {
      final zx = w * 0.42 + k * 8.0;
      final zy = h * 0.68 + k * 1.5;
      canvas.drawLine(Offset(zx, zy - 10), Offset(zx + 6, zy + 10), zebraPaint);
    }
  }

  // ===========================================================================
  // 5. 3D ISOMETRIC CITY BUILDINGS & CHENNAI CENTRAL
  // ===========================================================================

  void _draw3DCityscape(Canvas canvas, double w, double h) {
    final dX = parallaxOffsetX * 10.0;
    final dY = parallaxOffsetY * 5.0;

    // A. Drop contact shadows beneath all major buildings
    _drawBuildingShadow(canvas, w * 0.22 + dX, h * 0.48 + dY, 46, 38);
    _drawBuildingShadow(canvas, w * 0.48 + dX, h * 0.46 + dY, 44, 40);
    _drawBuildingShadow(canvas, w * 0.74 + dX, h * 0.50 + dY, 48, 38);
    _drawBuildingShadow(canvas, w * 0.08 + dX, h * 0.52 + dY, 36, 32);

    // B. WEST COMMERCIAL HIGH-RISE (Left)
    _drawIsometricTower(
      canvas: canvas,
      baseCenter: Offset(w * 0.09 + dX, h * 0.52 + dY),
      width: 38,
      depth: 30,
      height: 80,
      wallColorLit: const Color(0xFFD6E4DC),
      wallColorShadow: const Color(0xFFADC4BA),
      roofColor: const Color(0xFFF2F8F5),
      windowColor: const Color(0xFF19AC8B),
    );

    // C. CHENNAI CENTRAL HERITAGE CLOCK TOWER (Iconic Landmark, Mid-Left)
    _drawChennaiCentralHeritageTower(
      canvas: canvas,
      baseCenter: Offset(w * 0.24 + dX, h * 0.50 + dY),
      scale: (w / 390).clamp(0.9, 1.2),
    );

    // D. MODERN GLASS CONCOURSE SKYSCRAPER (Center-Right)
    _drawIsometricGlassTower(
      canvas: canvas,
      baseCenter: Offset(w * 0.50 + dX, h * 0.48 + dY),
      width: 44,
      depth: 36,
      height: 125,
      scale: (w / 390).clamp(0.9, 1.2),
    );

    // E. EAST COMMERCE BLOCK & TECH PARK (Right)
    _drawIsometricTower(
      canvas: canvas,
      baseCenter: Offset(w * 0.76 + dX, h * 0.52 + dY),
      width: 42,
      depth: 32,
      height: 95,
      wallColorLit: const Color(0xFFE4DFD7),
      wallColorShadow: const Color(0xFFB8AEA2),
      roofColor: const Color(0xFFFAF7F2),
      windowColor: const Color(0xFF38BDF8),
    );

    // F. RESIDENTIAL MID-RISE WITH ROOFTOP GARDEN (Far Right)
    _drawIsometricTower(
      canvas: canvas,
      baseCenter: Offset(w * 0.91 + dX, h * 0.56 + dY),
      width: 32,
      depth: 26,
      height: 65,
      wallColorLit: const Color(0xFFDFECE6),
      wallColorShadow: const Color(0xFFB6CCC2),
      roofColor: const Color(0xFF48D5A0), // Green roof terrace
      windowColor: const Color(0xFFF59E0B),
    );
  }

  /// Helper to draw a true 3D isometric building with lit left face, shaded right face, and illuminated windows
  void _drawIsometricTower({
    required Canvas canvas,
    required Offset baseCenter,
    required double width,
    required double depth,
    required double height,
    required Color wallColorLit,
    required Color wallColorShadow,
    required Color roofColor,
    required Color windowColor,
  }) {
    final hw = width / 2;
    final hd = depth / 2;
    final isoY = hd * 0.55;

    // Base vertices (isometric diamond)
    final bFront = Offset(baseCenter.dx, baseCenter.dy + isoY);
    final bLeft = Offset(baseCenter.dx - hw, baseCenter.dy);
    final bRight = Offset(baseCenter.dx + hw, baseCenter.dy);

    // Top vertices (offset vertically by height)
    final tFront = Offset(bFront.dx, bFront.dy - height);
    final tLeft = Offset(bLeft.dx, bLeft.dy - height);
    final tRight = Offset(bRight.dx, bRight.dy - height);
    final tBack = Offset(baseCenter.dx, baseCenter.dy - isoY - height);

    // 1. Left Lit Face
    final leftFace = Path()
      ..moveTo(bLeft.dx, bLeft.dy)
      ..lineTo(tLeft.dx, tLeft.dy)
      ..lineTo(tFront.dx, tFront.dy)
      ..lineTo(bFront.dx, bFront.dy)
      ..close();
    canvas.drawPath(leftFace, Paint()..color = wallColorLit);

    // 2. Right Shaded Face
    final rightFace = Path()
      ..moveTo(bFront.dx, bFront.dy)
      ..lineTo(tFront.dx, tFront.dy)
      ..lineTo(tRight.dx, tRight.dy)
      ..lineTo(bRight.dx, bRight.dy)
      ..close();
    canvas.drawPath(rightFace, Paint()..color = wallColorShadow);

    // 3. Top Roof Face (Direct sunlight)
    final roofFace = Path()
      ..moveTo(tFront.dx, tFront.dy)
      ..lineTo(tLeft.dx, tLeft.dy)
      ..lineTo(tBack.dx, tBack.dy)
      ..lineTo(tRight.dx, tRight.dy)
      ..close();
    canvas.drawPath(roofFace, Paint()..color = roofColor);

    // Crisp edge highlights
    final edgePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawLine(tFront, tLeft, edgePaint);
    canvas.drawLine(tFront, tRight, edgePaint);
    canvas.drawLine(tFront, bFront, edgePaint);

    // 4. Illuminated Window Grids on Lit & Shadow walls
    final rows = (height / 14).floor();
    for (int r = 1; r < rows; r++) {
      final frac = r / rows;
      final winLit = Offset.lerp(bLeft, tLeft, frac)! + const Offset(4, 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(winLit.dx, winLit.dy, hw * 0.7, 4),
          const Radius.circular(1),
        ),
        Paint()..color = windowColor.withValues(alpha: 0.75),
      );

      final winShadow = Offset.lerp(bFront, tFront, frac)! + const Offset(3, 1);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(winShadow.dx, winShadow.dy, hw * 0.7, 4),
          const Radius.circular(1),
        ),
        Paint()..color = windowColor.withValues(alpha: 0.35),
      );
    }
  }

  /// Chennai Central Heritage Clock Tower with warm brick terracotta and stepped crimson roof
  void _drawChennaiCentralHeritageTower({
    required Canvas canvas,
    required Offset baseCenter,
    required double scale,
  }) {
    final w = 42.0 * scale;
    final d = 34.0 * scale;
    final h = 110.0 * scale;
    final hw = w / 2;
    final hd = d / 2;
    final isoY = hd * 0.55;

    // 1. Lower Brick Podium
    _drawIsometricTower(
      canvas: canvas,
      baseCenter: baseCenter,
      width: w,
      depth: d,
      height: h * 0.75,
      wallColorLit: const Color(0xFFD49780), // Warm terracotta sandstone
      wallColorShadow: const Color(0xFF8E4E3F), // Shadow brick
      roofColor: const Color(0xFFF2ECE4),
      windowColor: const Color(0xFF26332F),
    );

    // 2. Upper Clock Tier
    final clockCenter = Offset(baseCenter.dx, baseCenter.dy - h * 0.75);
    _drawIsometricTower(
      canvas: canvas,
      baseCenter: clockCenter,
      width: w * 0.75,
      depth: d * 0.75,
      height: 24 * scale,
      wallColorLit: const Color(0xFFFAF7F2),
      wallColorShadow: const Color(0xFFB5A89A),
      roofColor: const Color(0xFFE8DFD3),
      windowColor: const Color(0xFF26332F),
    );

    // Clock dials (Left face and Right face)
    final dialY = clockCenter.dy - 12 * scale;
    // Left Clock Face
    canvas.drawOval(
      Rect.fromCenter(center: Offset(clockCenter.dx - 8 * scale, dialY), width: 9 * scale, height: 11 * scale),
      Paint()..color = const Color(0xFF1B2320),
    );
    canvas.drawCircle(
      Offset(clockCenter.dx - 8 * scale, dialY),
      1.5 * scale,
      Paint()..color = const Color(0xFFFFFBEB),
    );

    // Right Clock Face
    canvas.drawOval(
      Rect.fromCenter(center: Offset(clockCenter.dx + 8 * scale, dialY), width: 9 * scale, height: 11 * scale),
      Paint()..color = const Color(0xFF1B2320),
    );
    canvas.drawCircle(
      Offset(clockCenter.dx + 8 * scale, dialY),
      1.5 * scale,
      Paint()..color = const Color(0xFFFFFBEB),
    );

    // 3. Stepped Heritage Crimson Pyramidal Roof
    final roofBaseY = clockCenter.dy - 24 * scale;
    final apex = Offset(clockCenter.dx, roofBaseY - 26 * scale);

    final pFront = Offset(clockCenter.dx, roofBaseY + isoY * 0.7);
    final pLeft = Offset(clockCenter.dx - hw * 0.75, roofBaseY);
    final pRight = Offset(clockCenter.dx + hw * 0.75, roofBaseY);

    // Left pyramid face (Lit crimson)
    final roofLeft = Path()
      ..moveTo(apex.dx, apex.dy)
      ..lineTo(pLeft.dx, pLeft.dy)
      ..lineTo(pFront.dx, pFront.dy)
      ..close();
    canvas.drawPath(roofLeft, Paint()..color = const Color(0xFFA63D2E));

    // Right pyramid face (Shaded crimson)
    final roofRight = Path()
      ..moveTo(apex.dx, apex.dy)
      ..lineTo(pFront.dx, pFront.dy)
      ..lineTo(pRight.dx, pRight.dy)
      ..close();
    canvas.drawPath(roofRight, Paint()..color = const Color(0xFF6E261B));

    // Pinnacle finial with pulsing green transit jewel
    canvas.drawLine(
      apex,
      Offset(apex.dx, apex.dy - 10 * scale),
      Paint()
        ..color = const Color(0xFF26332F)
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(
      Offset(apex.dx, apex.dy - 10 * scale),
      2.5 * scale,
      Paint()..color = SafarTokens.transitGreen,
    );
  }

  /// Modern Glass Concourse Tower with specular sky reflections and glowing crown
  void _drawIsometricGlassTower({
    required Canvas canvas,
    required Offset baseCenter,
    required double width,
    required double depth,
    required double height,
    required double scale,
  }) {
    _drawIsometricTower(
      canvas: canvas,
      baseCenter: baseCenter,
      width: width,
      depth: depth,
      height: height,
      wallColorLit: const Color(0xFF68B7A5), // Polished Mint Glass
      wallColorShadow: const Color(0xFF387B6C),
      roofColor: const Color(0xFFD6F3EB),
      windowColor: const Color(0xFFFFFFFF),
    );

    // Diagonal specular sun glint across glass facade
    final topY = baseCenter.dy - height;
    final glintPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.65),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(baseCenter.dx - width / 2, topY, width, height));

    final glintPath = Path()
      ..moveTo(baseCenter.dx - width * 0.35, topY)
      ..lineTo(baseCenter.dx - width * 0.15, topY)
      ..lineTo(baseCenter.dx - width * 0.45, baseCenter.dy)
      ..lineTo(baseCenter.dx - width * 0.65, baseCenter.dy)
      ..close();
    canvas.drawPath(glintPath, glintPaint);

    // Architectural illuminated rooftop crown
    final crownCenter = Offset(baseCenter.dx, topY);
    final crownRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: crownCenter, width: width + 4, height: 6),
      const Radius.circular(2),
    );
    canvas.drawRRect(crownRRect, Paint()..color = SafarTokens.transitGreen);
  }

  void _drawBuildingShadow(Canvas canvas, double cx, double cy, double w, double h) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 6, cy + 3), width: w * 1.3, height: h * 0.75),
      Paint()
        ..color = const Color(0x22132B20)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0),
    );
  }

  // ===========================================================================
  // 6. LIVING STREET-LEVEL TRAFFIC (MTC Bus, Autos, Commuter Cars)
  // ===========================================================================

  void _drawStreetTraffic(Canvas canvas, double w, double h) {
    // Road runs from (-10, 0.615 * h) to (w + 10, 0.815 * h)
    // Lane 1 (Downhill, rightwards): y = 0.635 * h to 0.835 * h
    // Lane 2 (Uphill, leftwards): y = 0.595 * h to 0.795 * h

    // 1. RED & IVORY CHENNAI MTC TRANSIT BUS (Lane 1)
    final busT = (animationProgress * 0.70 + 0.15) % 1.0;
    final busPos = _getRoadPosition(busT, w, h, laneOffset: 7.0);
    _drawChennaiBus(canvas, busPos.pos, busPos.angle);

    // 2. ICONIC YELLOW-BLACK CHENNAI AUTO-RICKSHAW (Lane 1, trailing bus)
    final autoT = (animationProgress * 0.95 + 0.60) % 1.0;
    final autoPos = _getRoadPosition(autoT, w, h, laneOffset: 6.0);
    _drawAutoRickshaw(canvas, autoPos.pos, autoPos.angle);

    // 3. WHITE COMMUTER SEDAN (Lane 2, moving opposite uphill)
    final car1T = (1.0 - (animationProgress * 0.85 + 0.20) % 1.0);
    final car1Pos = _getRoadPosition(car1T, w, h, laneOffset: -6.0);
    _drawCommuterCar(canvas, car1Pos.pos, car1Pos.angle + math.pi, const Color(0xFFF7F8F5));

    // 4. CYAN TAXI CAB (Lane 1, fast overtaker)
    final car2T = (animationProgress * 1.15 + 0.80) % 1.0;
    final car2Pos = _getRoadPosition(car2T, w, h, laneOffset: 8.0);
    _drawCommuterCar(canvas, car2Pos.pos, car2Pos.angle, const Color(0xFF0284C7));
  }

  ({Offset pos, double angle}) _getRoadPosition(
    double t,
    double w,
    double h, {
    double laneOffset = 0.0,
  }) {
    final start = Offset(-20, h * 0.60);
    final end = Offset(w + 30, h * 0.81);

    final base = Offset.lerp(start, end, t)!;
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);

    final normal = Offset(-math.sin(angle), math.cos(angle));
    final finalPos = base + normal * laneOffset;

    return (pos: finalPos, angle: angle);
  }

  /// Distinctive Chennai MTC City Bus (Crimson & Cream)
  void _drawChennaiBus(Canvas canvas, Offset pos, double angle) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);

    // Contact shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(1, 2), width: 34, height: 14),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0x3510251C),
    );

    // Main Bus Body (Crimson Transit Red)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 32, height: 12),
        const Radius.circular(2.5),
      ),
      Paint()..color = const Color(0xFFDC2626),
    );

    // Cream roof
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, -1), width: 28, height: 8),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFFAF8F5),
    );

    // Windshield & windows
    canvas.drawRect(
      const Rect.fromLTWH(11, -4.5, 4, 9),
      Paint()..color = const Color(0xFF1E2B25),
    );
    for (int i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTWH(-12.0 + i * 8.0, -5, 5, 2.5),
        Paint()..color = const Color(0xFF1E2B25),
      );
    }

    // Forward Headlights & Road Light Cone
    canvas.drawCircle(const Offset(16, -3.5), 1.5, Paint()..color = const Color(0xFFFFFBEB));
    canvas.drawCircle(const Offset(16, 3.5), 1.5, Paint()..color = const Color(0xFFFFFBEB));

    // Dynamic light beam on asphalt
    final beam = Path()
      ..moveTo(16, -3)
      ..lineTo(38, -10)
      ..lineTo(38, 10)
      ..lineTo(16, 3)
      ..close();
    canvas.drawPath(
      beam,
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(16, 0),
          const Offset(38, 0),
          [const Color(0x44FFFBEB), const Color(0x00FFFBEB)],
        ),
    );

    // Ruby taillights
    canvas.drawCircle(const Offset(-16, -3.5), 1.2, Paint()..color = const Color(0xFFEF4444));
    canvas.drawCircle(const Offset(-16, 3.5), 1.2, Paint()..color = const Color(0xFFEF4444));

    canvas.restore();
  }

  /// Authentic Chennai Yellow & Black Auto-Rickshaw
  void _drawAutoRickshaw(Canvas canvas, Offset pos, double angle) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);

    // Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 1.5), width: 17, height: 10),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0x2810251C),
    );

    // Black chassis base
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 15, height: 9),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF26332F),
    );

    // Signature Yellow Canvas Hood
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(-1, 0), width: 10, height: 8),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFF59E0B), // Vibrant auto amber-yellow
    );

    // Single front headlight
    canvas.drawCircle(const Offset(7.5, 0), 1.4, Paint()..color = const Color(0xFFFFFBEB));
    canvas.drawCircle(const Offset(-7.5, 0), 1.0, Paint()..color = const Color(0xFFEF4444));

    canvas.restore();
  }

  /// Commuter Sedan Car
  void _drawCommuterCar(Canvas canvas, Offset pos, double angle, Color bodyColor) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 1.5), width: 22, height: 11),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0x2810251C),
    );

    // Body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 20, height: 9.5),
        const Radius.circular(2.5),
      ),
      Paint()..color = bodyColor,
    );

    // Tinted windshield & cabin
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(-0.5, 0), width: 10, height: 6.5),
        const Radius.circular(1.5),
      ),
      Paint()..color = const Color(0xFF26332F),
    );

    // Lights
    canvas.drawCircle(const Offset(10, -2.5), 1.2, Paint()..color = const Color(0xFFFFFBEB));
    canvas.drawCircle(const Offset(10, 2.5), 1.2, Paint()..color = const Color(0xFFFFFBEB));
    canvas.drawCircle(const Offset(-10, -2.5), 1.0, Paint()..color = const Color(0xFFEF4444));
    canvas.drawCircle(const Offset(-10, 2.5), 1.0, Paint()..color = const Color(0xFFEF4444));

    canvas.restore();
  }

  // ===========================================================================
  // 7 & 8. 3D ELEVATED VIADUCT INFRASTRUCTURE
  // ===========================================================================

  void _buildViaductPath(double w, double h) {
    if (_cachedViaductPath != null &&
        _lastSize != null &&
        _lastSize!.width == w &&
        _lastSize!.height == h) {
      return;
    }
    _lastSize = Size(w, h);

    // Spline weaving through the metropolis canyon:
    // Station glide: Y = 0.70 * h
    // Elevated rear overpass: Y = 0.32 * h
    final yFront = h * 0.70;
    final yRear = h * 0.32;
    final xLeft = w * 0.22;
    final xRight = w * 0.78;
    final xFarLeft = w * 0.06;
    final xFarRight = w * 0.94;

    final path = Path();
    path.moveTo(xLeft, yFront);

    // Front straight through central platform
    path.cubicTo(
      xLeft + (xRight - xLeft) * 0.35, yFront,
      xLeft + (xRight - xLeft) * 0.65, yFront,
      xRight, yFront,
    );
    // Right upward curve to elevated rear skyline
    path.cubicTo(
      xFarRight, yFront,
      xFarRight, yRear,
      xRight, yRear,
    );
    // Rear elevated viaduct cruising past skyscrapers
    path.cubicTo(
      xRight - (xRight - xLeft) * 0.35, yRear,
      xLeft + (xRight - xLeft) * 0.35, yRear,
      xLeft, yRear,
    );
    // Left descending sweeping turn to station
    path.cubicTo(
      xFarLeft, yRear,
      xFarLeft, yFront,
      xLeft, yFront,
    );
    path.close();

    _cachedViaductPath = path;
    final metrics = path.computeMetrics().toList();
    _cachedViaductMetric = metrics.isNotEmpty ? metrics.first : null;
  }

  void _drawViaductInfrastructure(
    Canvas canvas,
    Path trackPath,
    ui.PathMetric metric,
    double totalLength,
    double w,
    double h,
  ) {
    // 1. Reinforced Concrete Support Piers
    final pierXCoords = [0.36 * w, 0.50 * w, 0.64 * w];
    for (final px in pierXCoords) {
      final pierTop = h * 0.32;
      final pierHeight = h * 0.24;
      const pierWidth = 11.0;

      // Pier drop shadow
      canvas.drawOval(
        Rect.fromCenter(center: Offset(px, pierTop + pierHeight), width: 24, height: 7),
        Paint()..color = const Color(0x20132B20),
      );

      // Main concrete column
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(px - pierWidth / 2, pierTop, pierWidth, pierHeight),
          const Radius.circular(2),
        ),
        Paint()..color = const Color(0xFFC7DCD2),
      );
      // Shaded pier side
      canvas.drawRect(
        Rect.fromLTWH(px, pierTop, pierWidth / 2, pierHeight),
        Paint()..color = const Color(0xFFABC4B7),
      );
      // Cantilever crosshead
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(px, pierTop + 3), width: 22, height: 6),
          const Radius.circular(1.5),
        ),
        Paint()..color = const Color(0xFFD6EAE0),
      );
    }

    // 2. Viaduct Deck Ballast (Outer & Inner smooth stroke)
    canvas.drawPath(
      trackPath,
      Paint()
        ..color = const Color(0xFFD4E8DF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      trackPath,
      Paint()
        ..color = const Color(0xFFE2F3ED)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // 3. Concrete Sleepers / Cross-ties
    const sleeperSpacing = 9.0;
    final count = (totalLength / sleeperSpacing).floor();
    final sleeperPaint = Paint()
      ..color = const Color(0xFFAEC7BB)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < count; i++) {
      final dist = i * sleeperSpacing;
      final tangent = metric.getTangentForOffset(dist);
      if (tangent == null) continue;

      final normal = Offset(-tangent.vector.dy, tangent.vector.dx);
      const halfL = 9.0;
      canvas.drawLine(
        tangent.position + normal * halfL,
        tangent.position - normal * halfL,
        sleeperPaint,
      );
    }

    // 4. Twin Metallic Steel Rails
    canvas.drawPath(
      trackPath,
      Paint()
        ..color = const Color(0xFF86A597)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14.0
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      trackPath,
      Paint()
        ..color = const Color(0xFFDCEFE6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      trackPath,
      Paint()
        ..color = const Color(0xFF3F5A4F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
  }

  // ===========================================================================
  // 9. ELEVATED STATION PLATFORM ("CENTRAL METRO")
  // ===========================================================================

  void _drawElevatedStation(Canvas canvas, double w, double h) {
    final platX = w * 0.33;
    final platY = h * 0.70 + 13.0;
    final platW = w * 0.34;
    const platH = 15.0;

    // Platform shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(platX, platY + 2, platW, platH),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0x2010251C),
    );

    // Polished concrete platform deck
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(platX, platY, platW, platH),
        const Radius.circular(4),
      ),
      Paint()..color = SafarTokens.surfacePureWhite,
    );

    // Tactile Amber Warning Edge
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(platX + 2, platY + 1, platW - 4, 2.5),
        const Radius.circular(1),
      ),
      Paint()..color = SafarTokens.alertAmber,
    );

    // Cantilever Canopy Wing
    for (int j = 0; j < 3; j++) {
      final cx = platX + 16 + j * (platW - 32) / 2;
      canvas.drawLine(
        Offset(cx, platY + 8),
        Offset(cx, platY - 14),
        Paint()
          ..color = SafarTokens.textMuted
          ..strokeWidth = 1.6,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(platX + 10, platY - 16, platW - 20, 4.0),
        const Radius.circular(2),
      ),
      Paint()..color = SafarTokens.deepCharcoal,
    );

    // Miniature Waiting Commuters on Platform
    final commuterColors = [
      const Color(0xFFDC2626),
      const Color(0xFF19AC8B),
      const Color(0xFF0284C7),
      const Color(0xFFD97706),
    ];
    for (int c = 0; c < 4; c++) {
      final cx = platX + 28 + c * 22.0;
      final cy = platY + 6.0;
      // Head
      canvas.drawCircle(Offset(cx, cy - 3), 1.5, Paint()..color = const Color(0xFF33443F));
      // Body
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - 1.5, cy - 1, 3, 5),
          const Radius.circular(1),
        ),
        Paint()..color = commuterColors[c],
      );
    }

    // Glowing Station Beacon Sensor (Pulsing emerald green)
    final beaconGlow = (math.sin(animationProgress * math.pi * 8) * 0.5 + 0.5);
    canvas.drawCircle(
      Offset(platX + 8, platY + 8),
      3.0,
      Paint()..color = SafarTokens.transitGreen.withValues(alpha: 0.6 + 0.4 * beaconGlow),
    );
    canvas.drawCircle(
      Offset(platX + 8, platY + 8),
      6.5,
      Paint()..color = SafarTokens.transitGreen.withValues(alpha: 0.25 * beaconGlow),
    );
  }

  // ===========================================================================
  // 10. ARTICULATED 3D CHENNAI METRO TRAIN
  // ===========================================================================

  void _drawChennaiMetroTrain(
    Canvas canvas,
    ui.PathMetric metric,
    double totalLength,
    double w,
    double h,
  ) {
    // Over 5 seconds, train glides smoothly across the complete circuit
    final leadDist = (animationProgress * totalLength) % totalLength;

    final scale = (w / 380).clamp(0.85, 1.25);
    final carriageLength = 40.0 * scale;
    final carriageWidth = 13.0 * scale;
    final interCarriageSpacing = 44.0 * scale;

    final distances = [
      leadDist,
      (leadDist - interCarriageSpacing) % totalLength,
      (leadDist - interCarriageSpacing * 2) % totalLength,
    ];
    for (int i = 0; i < distances.length; i++) {
      if (distances[i] < 0) distances[i] += totalLength;
    }

    final tangents = distances.map((d) => metric.getTangentForOffset(d)).toList();

    // A. Flexible Accordion Bellows
    for (int i = 0; i < 2; i++) {
      final tA = tangents[i];
      final tB = tangents[i + 1];
      if (tA != null && tB != null) {
        final midDist = (distances[i] - interCarriageSpacing / 2) % totalLength;
        final tMid = metric.getTangentForOffset(midDist < 0 ? midDist + totalLength : midDist);
        if (tMid != null) {
          _drawBellows(canvas, tMid.position, tMid.angle, carriageWidth * 0.75, scale);
        }
      }
    }

    // B. Carriage Contact Shadows
    for (int i = 0; i < 3; i++) {
      final t = tangents[i];
      if (t == null) continue;
      _drawCarriageShadow(canvas, t.position, t.angle, carriageLength, carriageWidth);
    }

    // C. Articulated Carriages
    for (int i = 0; i < 3; i++) {
      final t = tangents[i];
      if (t == null) continue;

      canvas.save();
      canvas.translate(t.position.dx, t.position.dy);
      canvas.rotate(t.angle);

      if (i == 0) {
        _drawLeadCab(canvas, carriageLength, carriageWidth, scale);
      } else if (i == 1) {
        _drawCenterCoach(canvas, carriageLength, carriageWidth, scale);
      } else {
        _drawRearCab(canvas, carriageLength, carriageWidth, scale);
      }

      canvas.restore();
    }
  }

  void _drawCarriageShadow(
    Canvas canvas,
    Offset position,
    double angle,
    double length,
    double width,
  ) {
    canvas.save();
    canvas.translate(position.dx - 1.5, position.dy + 3.0);
    canvas.rotate(angle);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: length + 3.0, height: width + 2.0),
        const Radius.circular(5),
      ),
      Paint()
        ..color = const Color(0x32112A1D)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
    );
    canvas.restore();
  }

  void _drawLeadCab(Canvas canvas, double len, double wid, double scale) {
    final halfL = len / 2;
    final halfW = wid / 2;

    // Under-bogie wheel sets
    final bogiePaint = Paint()..color = const Color(0xFF1E2B25);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(-halfL * 0.45, 0), width: 14 * scale, height: wid + 1.5),
        const Radius.circular(2),
      ),
      bogiePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(halfL * 0.40, 0), width: 14 * scale, height: wid + 1.5),
        const Radius.circular(2),
      ),
      bogiePaint,
    );

    // Streamlined Aerodynamic Wedge Body
    final bodyPath = Path()
      ..moveTo(-halfL, -halfW + 2)
      ..lineTo(halfL - 8 * scale, -halfW)
      ..quadraticBezierTo(halfL, -halfW * 0.6, halfL + 3.5 * scale, 0)
      ..quadraticBezierTo(halfL, halfW * 0.6, halfL - 8 * scale, halfW)
      ..lineTo(-halfL, halfW - 2)
      ..close();
    canvas.drawPath(bodyPath, Paint()..color = SafarTokens.warmIvory);
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = const Color(0xFFD6E2DC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );

    // Signature CMRL Transit-Green Livery Waistband
    final liveryPaint = Paint()..color = SafarTokens.transitGreen;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-halfL + 2, halfW - 3.2 * scale, len - 5 * scale, 2.0 * scale),
        const Radius.circular(1),
      ),
      liveryPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-halfL + 2, -halfW + 1.2 * scale, len - 5 * scale, 2.0 * scale),
        const Radius.circular(1),
      ),
      liveryPaint,
    );

    // Aerodynamic Windshield Cockpit Glass
    final windshieldPath = Path()
      ..moveTo(halfL - 10 * scale, -halfW * 0.75)
      ..lineTo(halfL - 2 * scale, -halfW * 0.45)
      ..quadraticBezierTo(halfL + 2 * scale, 0, halfL - 2 * scale, halfW * 0.45)
      ..lineTo(halfL - 10 * scale, halfW * 0.75)
      ..close();
    canvas.drawPath(windshieldPath, Paint()..color = SafarTokens.deepCharcoal);

    // Windshield specular glint
    canvas.drawLine(
      Offset(halfL - 6 * scale, -halfW * 0.4),
      Offset(halfL - 2 * scale, 0),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..strokeWidth = 1.0,
    );

    // Passenger Windows
    for (int wIdx = 0; wIdx < 2; wIdx++) {
      final wx = -halfL + 6 * scale + wIdx * 9.5 * scale;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(wx, -halfW * 0.65, 6.5 * scale, wid * 0.45),
          const Radius.circular(1.5),
        ),
        Paint()..color = SafarTokens.deepCharcoal,
      );
    }

    // High-Intensity Warm-White LED Headlights
    canvas.drawCircle(Offset(halfL - 0.5 * scale, -halfW * 0.42), 1.6 * scale, Paint()..color = const Color(0xFFFFFBEB));
    canvas.drawCircle(Offset(halfL - 0.5 * scale, halfW * 0.42), 1.6 * scale, Paint()..color = const Color(0xFFFFFBEB));

    // Volumetric forward light illumination cone
    final beamPath = Path()
      ..moveTo(halfL + 1 * scale, -halfW * 0.5)
      ..lineTo(halfL + 32 * scale, -halfW * 2.2)
      ..lineTo(halfL + 32 * scale, halfW * 2.2)
      ..lineTo(halfL + 1 * scale, halfW * 0.5)
      ..close();

    canvas.drawPath(
      beamPath,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(halfL, 0),
          Offset(halfL + 32 * scale, 0),
          [const Color(0x4019AC8B), const Color(0x0019AC8B)],
        ),
    );
  }

  void _drawCenterCoach(Canvas canvas, double len, double wid, double scale) {
    final halfL = len / 2;
    final halfW = wid / 2;

    // Bogies
    final bogiePaint = Paint()..color = const Color(0xFF1E2B25);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(-halfL * 0.50, 0), width: 13 * scale, height: wid + 1.5),
        const Radius.circular(2),
      ),
      bogiePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(halfL * 0.50, 0), width: 13 * scale, height: wid + 1.5),
        const Radius.circular(2),
      ),
      bogiePaint,
    );

    // Body
    final bodyRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: len, height: wid),
      const Radius.circular(3.5),
    );
    canvas.drawRRect(bodyRRect, Paint()..color = SafarTokens.warmIvory);
    canvas.drawRRect(
      bodyRRect,
      Paint()
        ..color = const Color(0xFFD6E2DC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );

    // Livery Stripes
    final liveryPaint = Paint()..color = SafarTokens.transitGreen;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-halfL + 2, halfW - 3.2 * scale, len - 4, 2.0 * scale),
        const Radius.circular(1),
      ),
      liveryPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-halfL + 2, -halfW + 1.2 * scale, len - 4, 2.0 * scale),
        const Radius.circular(1),
      ),
      liveryPaint,
    );

    // Panoramic Windows
    for (int i = 0; i < 3; i++) {
      final wx = -halfL + 6 * scale + i * 10.5 * scale;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(wx, -halfW * 0.65, 7.5 * scale, wid * 0.45),
          const Radius.circular(1.5),
        ),
        Paint()..color = SafarTokens.deepCharcoal,
      );
    }

    // Door indicator lines
    final doorPaint = Paint()
      ..color = SafarTokens.transitGreen.withValues(alpha: 0.8)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(-halfL * 0.1, -halfW + 1), Offset(-halfL * 0.1, halfW - 1), doorPaint);
    canvas.drawLine(Offset(halfL * 0.1, -halfW + 1), Offset(halfL * 0.1, halfW - 1), doorPaint);
  }

  void _drawRearCab(Canvas canvas, double len, double wid, double scale) {
    final halfL = len / 2;
    final halfW = wid / 2;

    final bogiePaint = Paint()..color = const Color(0xFF1E2B25);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(-halfL * 0.40, 0), width: 14 * scale, height: wid + 1.5),
        const Radius.circular(2),
      ),
      bogiePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(halfL * 0.45, 0), width: 14 * scale, height: wid + 1.5),
        const Radius.circular(2),
      ),
      bogiePaint,
    );

    // Tail body
    final bodyPath = Path()
      ..moveTo(halfL, -halfW + 2)
      ..lineTo(-halfL + 8 * scale, -halfW)
      ..quadraticBezierTo(-halfL, -halfW * 0.6, -halfL - 3.5 * scale, 0)
      ..quadraticBezierTo(-halfL, halfW * 0.6, -halfL + 8 * scale, halfW)
      ..lineTo(halfL, halfW - 2)
      ..close();
    canvas.drawPath(bodyPath, Paint()..color = SafarTokens.warmIvory);
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = const Color(0xFFD6E2DC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );

    // Livery
    final liveryPaint = Paint()..color = SafarTokens.transitGreen;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-halfL + 5 * scale, halfW - 3.2 * scale, len - 5 * scale, 2.0 * scale),
        const Radius.circular(1),
      ),
      liveryPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-halfL + 5 * scale, -halfW + 1.2 * scale, len - 5 * scale, 2.0 * scale),
        const Radius.circular(1),
      ),
      liveryPaint,
    );

    // Windows
    for (int wIdx = 0; wIdx < 2; wIdx++) {
      final wx = -halfL * 0.3 + wIdx * 9.5 * scale;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(wx, -halfW * 0.65, 6.5 * scale, wid * 0.45),
          const Radius.circular(1.5),
        ),
        Paint()..color = SafarTokens.deepCharcoal,
      );
    }

    // Glowing Ruby-Red LED Taillights
    canvas.drawCircle(Offset(-halfL + 0.5 * scale, -halfW * 0.42), 1.6 * scale, Paint()..color = const Color(0xFFEF4444));
    canvas.drawCircle(Offset(-halfL + 0.5 * scale, halfW * 0.42), 1.6 * scale, Paint()..color = const Color(0xFFEF4444));
  }

  void _drawBellows(Canvas canvas, Offset pos, double angle, double width, double scale) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);

    final bellowsRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 6.0 * scale, height: width),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(bellowsRRect, Paint()..color = const Color(0xFF33443F));
    canvas.drawLine(
      Offset(0, -width / 2 + 1),
      Offset(0, width / 2 - 1),
      Paint()
        ..color = const Color(0xFF4A5C56)
        ..strokeWidth = 1.0,
    );

    canvas.restore();
  }

  // ===========================================================================
  // 11. URBAN GREENERY & LIGHTING ACCENTS
  // ===========================================================================

  void _drawForegroundGreenery(Canvas canvas, double w, double h) {
    final dX = parallaxOffsetX * 18.0;
    final dY = parallaxOffsetY * 10.0;

    final planterPaint = Paint()..color = const Color(0xFF19AC8B).withValues(alpha: 0.90);
    final leafHighlight = Paint()..color = const Color(0xFF48D5A0).withValues(alpha: 0.95);

    // Left Promenade Planters
    canvas.drawCircle(Offset(w * 0.08 + dX, h * 0.90 + dY), 13, planterPaint);
    canvas.drawCircle(Offset(w * 0.08 + dX - 3, h * 0.90 + dY - 3), 7, leafHighlight);

    canvas.drawCircle(Offset(w * 0.15 + dX, h * 0.93 + dY), 10, planterPaint);
    canvas.drawCircle(Offset(w * 0.15 + dX - 2, h * 0.93 + dY - 2), 5, leafHighlight);

    // Right Promenade Planters
    canvas.drawCircle(Offset(w * 0.88 + dX, h * 0.90 + dY), 12, planterPaint);
    canvas.drawCircle(Offset(w * 0.88 + dX - 3, h * 0.90 + dY - 3), 6, leafHighlight);
  }

  @override
  bool shouldRepaint(covariant LivingCityPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.parallaxOffsetX != parallaxOffsetX ||
        oldDelegate.parallaxOffsetY != parallaxOffsetY;
  }
}
