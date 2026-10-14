import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/tokens.dart';

/// MetroScenePainter — Exceptional 2.5D miniature Chennai Metro scene.
///
/// Features:
/// - Closed-loop railway track with C1 tangent continuity (zero jump at boundary).
/// - Exact arc-length distance mapping and tangent vector alignment.
/// - 3-carriage articulated metro train:
///   * Lead aero cab with headlights and forward track illumination beam.
///   * Center coach with panoramic windows and commuter door indicators.
///   * Rear coach with ruby taillights.
///   * Flexible accordion bellows between carriages.
/// - Directional soft contact shadows anchored to the track.
/// - Twin parallel steel rails, sleepers (ties), and ballast embankment.
/// - Modern elevated viaduct section on concrete piers.
/// - Contemporary cantilevered station platform with amber safety edge and beacon.
/// - Minimalist geometric Chennai architecture & restrained urban greenery.
class MetroScenePainter extends CustomPainter {
  final double parallaxOffsetX;
  final double parallaxOffsetY;
  final double animationProgress;

  // Cached path geometry for performance
  Path? _cachedTrackPath;
  ui.PathMetric? _cachedPathMetric;
  Size? _lastSize;

  MetroScenePainter({
    this.parallaxOffsetX = 0.0,
    this.parallaxOffsetY = 0.0,
    this.animationProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. AMBIENT SKY & BACKGROUND GRADIENT
    _drawSkyBackground(canvas, w, h);

    // 2. PARALLAX CITY SKYLINE (Distant Chennai silhouettes)
    _drawDistantSkyline(canvas, w, h);

    // 3. ELEVATED VIADUCT PIERS (Supporting rear track stretch)
    _drawViaductPiers(canvas, w, h);

    // 4. RAILWAY TRACK GEOMETRY (Shared mathematical path)
    _buildOrUpdateTrackPath(w, h);
    if (_cachedTrackPath == null || _cachedPathMetric == null) return;

    final trackPath = _cachedTrackPath!;
    final metric = _cachedPathMetric!;
    final totalLength = metric.length;

    // 5. DRAW TRACK BED, SLEEPERS & TWIN STEEL RAILS
    _drawTrackInfrastructure(canvas, trackPath, metric, totalLength);

    // 6. MODERN STATION PLATFORM (Foreground)
    _drawStationPlatform(canvas, w, h);

    // 7. ROAMING METRO TRAIN (3 connected carriages)
    _drawMetroTrain(canvas, metric, totalLength, w, h);

    // 8. FOREGROUND URBAN GREENERY & LIGHTING ACCENTS
    _drawForegroundAccents(canvas, w, h);
  }

  /// 1. Calm, premium ambient mint-to-ivory gradient backdrop
  void _drawSkyBackground(Canvas canvas, double w, double h) {
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFE2F3EF), // Soft Mint
          Color(0xFFEDF7F4),
          Color(0xFFF7F8F5), // Warm Ivory
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), skyPaint);

    // Very soft ambient sun glow
    final sunGlow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.45, -0.6),
        radius: 0.85,
        colors: [
          const Color(0xFFFFFBEB).withValues(alpha: 0.65),
          const Color(0xFFE2F3EF).withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), sunGlow);
  }

  /// 2. Minimalist geometric Chennai skyline silhouettes (Central tower & glass concourse)
  void _drawDistantSkyline(Canvas canvas, double w, double h) {
    final dX = parallaxOffsetX * 6.0;
    final dY = parallaxOffsetY * 3.0;

    final skylinePaint = Paint()
      ..color = const Color(0xFFB8D4C7).withValues(alpha: 0.45);
    final shadowBuildingPaint = Paint()
      ..color = const Color(0xFFA6C5B7).withValues(alpha: 0.50);

    // Left modern transit tower block
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.10 + dX, h * 0.12 + dY, w * 0.11, h * 0.28),
        const Radius.circular(4),
      ),
      skylinePaint,
    );
    // Shadow side of tower
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.17 + dX, h * 0.12 + dY, w * 0.04, h * 0.28),
        const Radius.circular(4),
      ),
      shadowBuildingPaint,
    );

    // Iconic Chennai Central dome & clock tower contour (stylized geometric)
    final centralTower = Path()
      ..moveTo(w * 0.44 + dX, h * 0.32 + dY)
      ..lineTo(w * 0.44 + dX, h * 0.10 + dY)
      ..lineTo(w * 0.465 + dX, h * 0.06 + dY) // Pinnacle
      ..lineTo(w * 0.49 + dX, h * 0.10 + dY)
      ..lineTo(w * 0.49 + dX, h * 0.32 + dY)
      ..close();
    canvas.drawPath(centralTower, skylinePaint);

    // Domed pavilions next to Central tower
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w * 0.41 + dX, h * 0.26 + dY),
        width: w * 0.07,
        height: h * 0.14,
      ),
      math.pi,
      math.pi,
      true,
      shadowBuildingPaint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w * 0.52 + dX, h * 0.26 + dY),
        width: w * 0.07,
        height: h * 0.14,
      ),
      math.pi,
      math.pi,
      true,
      shadowBuildingPaint,
    );

    // Right contemporary glass concourse
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.72 + dX, h * 0.15 + dY, w * 0.16, h * 0.22),
        const Radius.circular(6),
      ),
      skylinePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.81 + dX, h * 0.15 + dY, w * 0.07, h * 0.22),
        const Radius.circular(4),
      ),
      shadowBuildingPaint,
    );
  }

  /// 3. Viaduct support piers beneath the elevated rear rail stretch
  void _drawViaductPiers(Canvas canvas, double w, double h) {
    final pierPaint = Paint()..color = const Color(0xFFC7DCD2);
    final pierShadowPaint = Paint()..color = const Color(0xFFB0C9BD);

    // Three architectural concrete pylons along the rear track (Y ≈ 0.28H)
    final pierXCoords = [0.38 * w, 0.50 * w, 0.62 * w];
    for (final px in pierXCoords) {
      final pierTop = h * 0.27;
      final pierHeight = h * 0.32;
      const pierWidth = 10.0;

      // Drop shadow on ground
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(px, pierTop + pierHeight),
          width: 22,
          height: 7,
        ),
        Paint()..color = const Color(0x18122B1E),
      );

      // Main column
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(px - pierWidth / 2, pierTop, pierWidth, pierHeight),
          const Radius.circular(2),
        ),
        pierPaint,
      );
      // Pylon cantilever head
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(px - 10, pierTop, 20, 5),
          const Radius.circular(2),
        ),
        pierShadowPaint,
      );
      // Shaded side
      canvas.drawRect(
        Rect.fromLTWH(px, pierTop, pierWidth / 2, pierHeight),
        pierShadowPaint,
      );
    }
  }

  /// 4. Construct a smooth, mathematically closed loop path with C1 continuity
  void _buildOrUpdateTrackPath(double w, double h) {
    if (_cachedTrackPath != null &&
        _lastSize != null &&
        _lastSize!.width == w &&
        _lastSize!.height == h) {
      return;
    }

    _lastSize = Size(w, h);

    // Key Path Coordinates (carefully tuned for 2.5D perspective)
    // Front straight section: Y = 0.74 * h (Near plane)
    // Rear elevated section: Y = 0.27 * h (Far plane)
    final yFront = h * 0.74;
    final yRear = h * 0.27;
    final xLeft = w * 0.24;
    final xRight = w * 0.76;
    final xFarLeft = w * 0.08;
    final xFarRight = w * 0.92;

    final path = Path();

    // Start at beginning of front station straightaway
    path.moveTo(xLeft, yFront);

    // 1. FRONT STRAIGHTAWAY: Smooth glide through the station
    path.cubicTo(
      xLeft + (xRight - xLeft) * 0.35,
      yFront,
      xLeft + (xRight - xLeft) * 0.65,
      yFront,
      xRight,
      yFront,
    );

    // 2. RIGHT BANKING TURN: Sweeping upward curve to elevated rear
    // Tangent at xRight is horizontal right (angle 0). Outgoing control point continues purely horizontal right.
    path.cubicTo(
      xFarRight,
      yFront, // C2a continues tangent
      xFarRight,
      yRear, // C2b enters top smoothly
      xRight,
      yRear, // P2
    );

    // 3. REAR ELEVATED VIADUCT: Moving right-to-left across city skyline
    // Tangent at xRight is horizontal left (angle pi). Outgoing control point continues purely horizontal left.
    path.cubicTo(
      xRight - (xRight - xLeft) * 0.35,
      yRear,
      xLeft + (xRight - xLeft) * 0.35,
      yRear,
      xLeft,
      yRear,
    );

    // 4. LEFT DESCENDING RETURN: Sweeping downward curve to front platform
    // Tangent at xLeft is horizontal left (angle pi). Outgoing control point continues purely horizontal left.
    path.cubicTo(
      xFarLeft,
      yRear, // C4a continues tangent
      xFarLeft,
      yFront, // C4b arrives horizontally
      xLeft,
      yFront, // Closes loop at initial point!
    );

    path.close();

    _cachedTrackPath = path;
    final metrics = path.computeMetrics().toList();
    _cachedPathMetric = metrics.isNotEmpty ? metrics.first : null;
  }

  /// 5. Draw track bed embankment, cross-ties (sleepers), and twin parallel steel rails
  void _drawTrackInfrastructure(
    Canvas canvas,
    Path trackPath,
    ui.PathMetric metric,
    double totalLength,
  ) {
    // A. Track Bed / Ballast Embankment (Continuous smooth contour)
    final ballastPaint = Paint()
      ..color = const Color(0xFFD6EAE1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(trackPath, ballastPaint);

    final ballastInner = Paint()
      ..color = const Color(0xFFE2F3EF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(trackPath, ballastInner);

    // B. Sleepers / Ties (Sampled orthogonally along track path)
    const sleeperSpacing = 9.0;
    final sleeperCount = (totalLength / sleeperSpacing).floor();
    final sleeperPaint = Paint()
      ..color = const Color(0xFFB0C9BD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < sleeperCount; i++) {
      final dist = i * sleeperSpacing;
      final tangent = metric.getTangentForOffset(dist);
      if (tangent == null) continue;

      final pos = tangent.position;
      final normal = Offset(
        -tangent.vector.dy,
        tangent.vector.dx,
      ); // 90° normal

      const halfLen = 9.5;
      final p1 = pos + normal * halfLen;
      final p2 = pos - normal * halfLen;
      canvas.drawLine(p1, p2, sleeperPaint);
    }

    // C. Twin Metallic Steel Rails (Parallel offset paths)
    // Base rail bed shadow
    final railBedShadow = Paint()
      ..color = const Color(0xFF86A597)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(trackPath, railBedShadow);

    // Ballast center gap between twin rails
    final ballastGap = Paint()
      ..color = const Color(0xFFDCEFE6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(trackPath, ballastGap);

    // Steel rail head highlights (Crisp metallic edge)
    final steelHighlight = Paint()
      ..color = const Color(0xFF425D52)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(trackPath, steelHighlight);
  }

  /// 6. Sleek Modern Station Platform (Central Station Node)
  void _drawStationPlatform(Canvas canvas, double w, double h) {
    final platX = w * 0.34;
    final platY = h * 0.74 + 13.0; // Directly parallel to front track
    final platW = w * 0.32;
    const platH = 14.0;

    // Platform Base Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(platX, platY + 2, platW, platH),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0x18122B1E),
    );

    // Platform Slab (Warm Ivory & Polished concrete)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(platX, platY, platW, platH),
        const Radius.circular(4),
      ),
      Paint()..color = SafarTokens.surfacePureWhite,
    );

    // Alert Amber Tactile Safety Edge Strip
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(platX + 2, platY + 1, platW - 4, 2.5),
        const Radius.circular(1),
      ),
      Paint()..color = SafarTokens.alertAmber,
    );

    // Miniature Station Canopy (Slim architectural cantilever)
    final canopyPaint = Paint()..color = SafarTokens.deepCharcoal;
    // 3 slim canopy pylon supports
    for (int j = 0; j < 3; j++) {
      final cx = platX + 16 + j * (platW - 32) / 2;
      canvas.drawLine(
        Offset(cx, platY + 8),
        Offset(cx, platY - 14),
        Paint()
          ..color = SafarTokens.textMuted
          ..strokeWidth = 1.5,
      );
    }
    // Canopy roof wing
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(platX + 10, platY - 16, platW - 20, 3.5),
        const Radius.circular(2),
      ),
      canopyPaint,
    );

    // Station Name Badge "CENTRAL METRO"
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(platX + platW / 2 - 20, platY + 5, 40, 6),
        const Radius.circular(2),
      ),
      Paint()..color = SafarTokens.softMint,
    );

    // Ambient Station Beacon / Approach Sensor (Pulses as train glides past)
    final beaconGlow = (math.sin(animationProgress * math.pi * 4) * 0.5 + 0.5);
    canvas.drawCircle(
      Offset(platX + 8, platY + 7),
      2.5,
      Paint()
        ..color = SafarTokens.transitGreen.withValues(
          alpha: 0.6 + 0.4 * beaconGlow,
        ),
    );
  }

  /// 7. Draw the multi-carriage metro train with physical connection and independent turning
  void _drawMetroTrain(
    Canvas canvas,
    ui.PathMetric metric,
    double totalLength,
    double w,
    double h,
  ) {
    // Constant speed distance along track
    final leadDistance = (animationProgress * totalLength) % totalLength;

    // Dimensions for mobile-scale metro carriages
    final scale = (w / 380).clamp(0.85, 1.25);
    final carriageLength = 40.0 * scale;
    final carriageWidth = 13.0 * scale;
    final interCarriageSpacing = 44.0 * scale; // Center-to-center distance

    // Draw in order: Accordion Bellows first, then Carriages
    // Carriage 0: Lead Cab (Aerodynamic front)
    // Carriage 1: Center Coach (Panoramic windows)
    // Carriage 2: Rear Cab (Aerodynamic tail)

    final distances = [
      leadDistance,
      (leadDistance - interCarriageSpacing) % totalLength,
      (leadDistance - interCarriageSpacing * 2) % totalLength,
    ];

    // Normalize negative distances
    for (int i = 0; i < distances.length; i++) {
      if (distances[i] < 0) distances[i] += totalLength;
    }

    final tangents = distances
        .map((d) => metric.getTangentForOffset(d))
        .toList();

    // A. Draw Flexible Accordion Bellows (Gangways) between carriages
    for (int i = 0; i < 2; i++) {
      final tA = tangents[i];
      final tB = tangents[i + 1];
      if (tA != null && tB != null) {
        final midDist = (distances[i] - interCarriageSpacing / 2) % totalLength;
        final tMid = metric.getTangentForOffset(
          midDist < 0 ? midDist + totalLength : midDist,
        );
        if (tMid != null) {
          _drawBellows(
            canvas,
            tMid.position,
            tMid.angle,
            carriageWidth * 0.75,
            scale,
          );
        }
      }
    }

    // B. Draw Contact Shadows for each carriage
    for (int i = 0; i < 3; i++) {
      final tangent = tangents[i];
      if (tangent == null) continue;
      _drawCarriageShadow(
        canvas,
        tangent.position,
        tangent.angle,
        carriageLength,
        carriageWidth,
      );
    }

    // C. Draw Carriages with local coordinates & heading
    for (int i = 0; i < 3; i++) {
      final tangent = tangents[i];
      if (tangent == null) continue;

      canvas.save();
      canvas.translate(tangent.position.dx, tangent.position.dy);
      canvas.rotate(tangent.angle);

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

  /// Carriage Contact Shadow (Directional ambient shadow)
  void _drawCarriageShadow(
    Canvas canvas,
    Offset position,
    double angle,
    double length,
    double width,
  ) {
    canvas.save();
    // Offset shadow slightly down-right for sunlight effect
    canvas.translate(position.dx - 1.5, position.dy + 3.0);
    canvas.rotate(angle);

    final shadowPaint = Paint()
      ..color = const Color(0x30112A1D)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: length + 3.0,
          height: width + 2.0,
        ),
        const Radius.circular(5),
      ),
      shadowPaint,
    );

    canvas.restore();
  }

  /// Lead Engine Carriage: Sleek aerodynamic bullet nose, cockpit glass, LED headlights
  void _drawLeadCab(Canvas canvas, double len, double wid, double scale) {
    final halfL = len / 2;
    final halfW = wid / 2;

    // 1. Under-bogie track wheels
    final bogiePaint = Paint()..color = const Color(0xFF1E2B25);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-halfL * 0.45, 0),
          width: 14 * scale,
          height: wid + 1.5,
        ),
        const Radius.circular(2),
      ),
      bogiePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(halfL * 0.40, 0),
          width: 14 * scale,
          height: wid + 1.5,
        ),
        const Radius.circular(2),
      ),
      bogiePaint,
    );

    // 2. Aerodynamic Body (Warm Ivory with tapered nose)
    final bodyPath = Path()
      ..moveTo(-halfL, -halfW + 2)
      ..lineTo(halfL - 8 * scale, -halfW)
      ..quadraticBezierTo(
        halfL,
        -halfW * 0.6,
        halfL + 3 * scale,
        0,
      ) // Streamlined nose tip
      ..quadraticBezierTo(halfL, halfW * 0.6, halfL - 8 * scale, halfW)
      ..lineTo(-halfL, halfW - 2)
      ..close();

    canvas.drawPath(bodyPath, Paint()..color = SafarTokens.warmIvory);

    // Body outline & ambient depth
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = const Color(0xFFD6E2DC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );

    // 3. Transit Green Livery Stripe along lower flank
    final liveryPaint = Paint()..color = SafarTokens.transitGreen;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          -halfL + 2,
          halfW - 3.2 * scale,
          len - 5 * scale,
          2.0 * scale,
        ),
        const Radius.circular(1),
      ),
      liveryPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          -halfL + 2,
          -halfW + 1.2 * scale,
          len - 5 * scale,
          2.0 * scale,
        ),
        const Radius.circular(1),
      ),
      liveryPaint,
    );

    // 4. Cockpit Windshield (Flush Deep Charcoal)
    final windshieldPath = Path()
      ..moveTo(halfL - 10 * scale, -halfW * 0.75)
      ..lineTo(halfL - 2 * scale, -halfW * 0.45)
      ..quadraticBezierTo(
        halfL + 1.5 * scale,
        0,
        halfL - 2 * scale,
        halfW * 0.45,
      )
      ..lineTo(halfL - 10 * scale, halfW * 0.75)
      ..close();

    canvas.drawPath(windshieldPath, Paint()..color = SafarTokens.deepCharcoal);

    // Windshield glass glint
    canvas.drawLine(
      Offset(halfL - 6 * scale, -halfW * 0.4),
      Offset(halfL - 2 * scale, 0),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.5)
        ..strokeWidth = 1.0,
    );

    // 5. Passenger Side Windows
    final windowPaint = Paint()..color = SafarTokens.deepCharcoal;
    for (int wIdx = 0; wIdx < 2; wIdx++) {
      final wx = -halfL + 6 * scale + wIdx * 9.5 * scale;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(wx, -halfW * 0.65, 6.5 * scale, wid * 0.45),
          const Radius.circular(1.5),
        ),
        windowPaint,
      );
    }

    // 6. Aerodynamic Rooftop AC pod
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-halfL * 0.2, 0),
          width: 14 * scale,
          height: wid * 0.55,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFE4ECE8),
    );

    // 7. Twin Warm-White LED Headlights
    final headlightPaint = Paint()..color = const Color(0xFFFFFBEB);
    canvas.drawCircle(
      Offset(halfL - 0.5 * scale, -halfW * 0.42),
      1.6 * scale,
      headlightPaint,
    );
    canvas.drawCircle(
      Offset(halfL - 0.5 * scale, halfW * 0.42),
      1.6 * scale,
      headlightPaint,
    );

    // Forward light beam on tracks
    final beamPath = Path()
      ..moveTo(halfL + 1 * scale, -halfW * 0.5)
      ..lineTo(halfL + 28 * scale, -halfW * 1.8)
      ..lineTo(halfL + 28 * scale, halfW * 1.8)
      ..lineTo(halfL + 1 * scale, halfW * 0.5)
      ..close();

    final beamPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(halfL, 0),
        Offset(halfL + 28 * scale, 0),
        [const Color(0x3519AC8B), const Color(0x0019AC8B)],
      );
    canvas.drawPath(beamPath, beamPaint);
  }

  /// Center Passenger Coach: Symmetrical streamlined body, panoramic windows, doors
  void _drawCenterCoach(Canvas canvas, double len, double wid, double scale) {
    final halfL = len / 2;
    final halfW = wid / 2;

    // 1. Under-bogie track wheels
    final bogiePaint = Paint()..color = const Color(0xFF1E2B25);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-halfL * 0.50, 0),
          width: 13 * scale,
          height: wid + 1.5,
        ),
        const Radius.circular(2),
      ),
      bogiePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(halfL * 0.50, 0),
          width: 13 * scale,
          height: wid + 1.5,
        ),
        const Radius.circular(2),
      ),
      bogiePaint,
    );

    // 2. Streamlined Car Body
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

    // 3. Transit Green Livery Stripes
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

    // 4. Panoramic Passenger Windows & Commuter Door Seams
    final windowPaint = Paint()..color = SafarTokens.deepCharcoal;
    const windowCount = 3;
    for (int i = 0; i < windowCount; i++) {
      final wx = -halfL + 6 * scale + i * 10.5 * scale;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(wx, -halfW * 0.65, 7.5 * scale, wid * 0.45),
          const Radius.circular(1.5),
        ),
        windowPaint,
      );
    }

    // Door indicator line
    final doorPaint = Paint()
      ..color = SafarTokens.transitGreen.withValues(alpha: 0.8)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(-halfL * 0.1, -halfW + 1),
      Offset(-halfL * 0.1, halfW - 1),
      doorPaint,
    );
    canvas.drawLine(
      Offset(halfL * 0.1, -halfW + 1),
      Offset(halfL * 0.1, halfW - 1),
      doorPaint,
    );

    // 5. Roof AC fairing
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: 16 * scale,
          height: wid * 0.55,
        ),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFE4ECE8),
    );
  }

  /// Rear Cab: Streamlined aerodynamic tail, ruby-red LED taillights
  void _drawRearCab(Canvas canvas, double len, double wid, double scale) {
    final halfL = len / 2;
    final halfW = wid / 2;

    // 1. Bogies
    final bogiePaint = Paint()..color = const Color(0xFF1E2B25);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-halfL * 0.40, 0),
          width: 14 * scale,
          height: wid + 1.5,
        ),
        const Radius.circular(2),
      ),
      bogiePaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(halfL * 0.45, 0),
          width: 14 * scale,
          height: wid + 1.5,
        ),
        const Radius.circular(2),
      ),
      bogiePaint,
    );

    // 2. Streamlined Body (Tapered tail at the back)
    final bodyPath = Path()
      ..moveTo(halfL, -halfW + 2)
      ..lineTo(-halfL + 8 * scale, -halfW)
      ..quadraticBezierTo(
        -halfL,
        -halfW * 0.6,
        -halfL - 3 * scale,
        0,
      ) // Tail tip
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

    // 3. Transit Green Livery Stripes
    final liveryPaint = Paint()..color = SafarTokens.transitGreen;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          -halfL + 5 * scale,
          halfW - 3.2 * scale,
          len - 5 * scale,
          2.0 * scale,
        ),
        const Radius.circular(1),
      ),
      liveryPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          -halfL + 5 * scale,
          -halfW + 1.2 * scale,
          len - 5 * scale,
          2.0 * scale,
        ),
        const Radius.circular(1),
      ),
      liveryPaint,
    );

    // 4. Windows
    final windowPaint = Paint()..color = SafarTokens.deepCharcoal;
    for (int wIdx = 0; wIdx < 2; wIdx++) {
      final wx = -halfL * 0.3 + wIdx * 9.5 * scale;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(wx, -halfW * 0.65, 6.5 * scale, wid * 0.45),
          const Radius.circular(1.5),
        ),
        windowPaint,
      );
    }

    // 5. Twin Ruby-Red LED Taillights
    final taillightPaint = Paint()..color = const Color(0xFFEF4444);
    canvas.drawCircle(
      Offset(-halfL + 0.5 * scale, -halfW * 0.42),
      1.5 * scale,
      taillightPaint,
    );
    canvas.drawCircle(
      Offset(-halfL + 0.5 * scale, halfW * 0.42),
      1.5 * scale,
      taillightPaint,
    );
  }

  /// Flexible Accordion Bellows / Gangway connection between carriages
  void _drawBellows(
    Canvas canvas,
    Offset pos,
    double angle,
    double width,
    double scale,
  ) {
    canvas.save();
    canvas.translate(pos.dx, pos.dy);
    canvas.rotate(angle);

    final bellowsPaint = Paint()..color = const Color(0xFF33443F);
    final bellowsRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 6.0 * scale, height: width),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(bellowsRRect, bellowsPaint);

    // Accordion fold line
    canvas.drawLine(
      Offset(0, -width / 2 + 1),
      Offset(0, width / 2 - 1),
      Paint()
        ..color = const Color(0xFF4A5C56)
        ..strokeWidth = 1.0,
    );

    canvas.restore();
  }

  /// 8. Foreground urban planters and subtle greenery accents
  void _drawForegroundAccents(Canvas canvas, double w, double h) {
    final dX = parallaxOffsetX * 18.0;
    final dY = parallaxOffsetY * 10.0;

    // Corner urban planter on bottom-left
    final planterPaint = Paint()
      ..color = const Color(0xFF19AC8B).withValues(alpha: 0.85);
    final planterLight = Paint()
      ..color = const Color(0xFF48D5A0).withValues(alpha: 0.90);

    canvas.drawCircle(Offset(w * 0.08 + dX, h * 0.88 + dY), 12, planterPaint);
    canvas.drawCircle(
      Offset(w * 0.08 + dX - 3, h * 0.88 + dY - 3),
      7,
      planterLight,
    );

    canvas.drawCircle(Offset(w * 0.14 + dX, h * 0.92 + dY), 9, planterPaint);
    canvas.drawCircle(
      Offset(w * 0.14 + dX - 2, h * 0.92 + dY - 2),
      5,
      planterLight,
    );

    // Corner urban planter on bottom-right
    canvas.drawCircle(Offset(w * 0.90 + dX, h * 0.88 + dY), 11, planterPaint);
    canvas.drawCircle(
      Offset(w * 0.90 + dX - 3, h * 0.88 + dY - 3),
      6,
      planterLight,
    );
  }

  @override
  bool shouldRepaint(covariant MetroScenePainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.parallaxOffsetX != parallaxOffsetX ||
        oldDelegate.parallaxOffsetY != parallaxOffsetY;
  }
}
