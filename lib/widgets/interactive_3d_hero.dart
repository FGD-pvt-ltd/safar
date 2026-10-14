import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import 'glass_container.dart';
import 'metro_scene_painter.dart';

/// MetroHero / Interactive3DHero — Signature 2.5D Animated Chennai Metro Hero
///
/// Features:
/// - A continuous closed-loop railway track with C1 tangent continuity (no jumps).
/// - 3-carriage articulated metro train following track curve and tangents.
/// - Twin parallel steel rails and cross-ties matching the exact train trajectory.
/// - Contemporary cantilevered station platform with amber safety edge and beacon.
/// - Interactive 2.5D perspective tilt responding to touch pan and mouse hover.
/// - Seamless integration with SAFAR mint & ivory design language.
typedef MetroHero = Interactive3DHero;

class Interactive3DHero extends StatefulWidget {
  final double height;
  final VoidCallback? onExploreTap;
  final String locationLabel;
  final String locationBadge;
  final String weatherText;
  final bool showBadges;

  const Interactive3DHero({
    super.key,
    this.height = 420.0,
    this.onExploreTap,
    this.locationLabel = 'Chennai Central',
    this.locationBadge = 'CMRL Hub',
    this.weatherText = 'CMRL Metro • Normal Service',
    this.showBadges = false,
  });

  @override
  State<Interactive3DHero> createState() => _Interactive3DHeroState();
}

class _Interactive3DHeroState extends State<Interactive3DHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambientController;
  double _manualTiltX = 0.0;
  double _manualTiltY = 0.0;
  bool _isInteracting = false;

  @override
  void initState() {
    super.initState();
    // 8-second continuous ambient loop for regal, buttery-smooth metro glide
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    setState(() {
      _isInteracting = true;
      // Normalize to [-1.0, 1.0] range
      final dx = (details.localPosition.dx / size.width) * 2 - 1;
      final dy = (details.localPosition.dy / size.height) * 2 - 1;
      _manualTiltX = dx.clamp(-1.0, 1.0);
      _manualTiltY = dy.clamp(-1.0, 1.0);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isInteracting = false;
      _manualTiltX = 0.0;
      _manualTiltY = 0.0;
    });
  }

  void _onHover(PointerEvent event, Size size) {
    setState(() {
      final dx = (event.localPosition.dx / size.width) * 2 - 1;
      final dy = (event.localPosition.dy / size.height) * 2 - 1;
      _manualTiltX = dx.clamp(-1.0, 1.0);
      _manualTiltY = dy.clamp(-1.0, 1.0);
    });
  }

  void _onHoverExit(PointerEvent event) {
    setState(() {
      _manualTiltX = 0.0;
      _manualTiltY = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ambientController,
      builder: (context, child) {
        // Subtle ambient wave when not dragging
        final ambientProgress = _ambientController.value * 2 * math.pi;
        final ambientX = math.sin(ambientProgress) * 0.10;
        final ambientY = math.cos(ambientProgress * 0.8) * 0.06;

        final effectiveTiltX = _isInteracting ? _manualTiltX : ambientX;
        final effectiveTiltY = _isInteracting ? _manualTiltY : ambientY;

        // Perspective rotation angles (clamped to max ~6-7 degrees for elegance)
        final rotY = effectiveTiltX * 0.11; // tilt left/right
        final rotX = -effectiveTiltY * 0.09; // tilt up/down

        return LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, widget.height);

            return MouseRegion(
              onHover: (e) => _onHover(e, size),
              onExit: _onHoverExit,
              child: GestureDetector(
                onPanUpdate: (d) => _onPanUpdate(d, size),
                onPanEnd: _onPanEnd,
                child: Center(
                  child: Transform(
                    alignment: FractionalOffset.center,
                    transform: Matrix4.identity()
                      ..setEntry(
                        3,
                        2,
                        0.0012,
                      ) // Subtle perspective vanishing point
                      ..rotateX(rotX)
                      ..rotateY(rotY),
                    child: Container(
                      width: size.width,
                      height: size.height,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          SafarTokens.radiusXL,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0x16112A1D),
                            blurRadius: 28,
                            offset: Offset(
                              -effectiveTiltX * 10,
                              16 + effectiveTiltY * 8,
                            ),
                            spreadRadius: -4,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                          SafarTokens.radiusXL,
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // 1. SIGNATURE ROAMING METRO 2.5D CANVAS
                            RepaintBoundary(
                              child: CustomPaint(
                                size: size,
                                painter: MetroScenePainter(
                                  parallaxOffsetX: effectiveTiltX,
                                  parallaxOffsetY: effectiveTiltY,
                                  animationProgress: _ambientController.value,
                                ),
                              ),
                            ),

                            // 2. FLOATING 3D TRANSIT COMPASS BADGE (Top Right with Depth Plane)
                            if (widget.showBadges) ...[
                              Positioned(
                                top:
                                    (widget.height < 250 ? 10 : 20) -
                                    effectiveTiltY * 12,
                                right: 16 - effectiveTiltX * 14,
                                child: _FloatingTransitCompass(
                                  tiltX: effectiveTiltX,
                                  tiltY: effectiveTiltY,
                                  animProgress: _ambientController.value,
                                ),
                              ),

                              // 3. FLOATING DESTINATION ELEVATION PILL (Bottom Left with Depth Plane)
                              Positioned(
                                bottom:
                                    (widget.height < 250 ? 10 : 22) +
                                    effectiveTiltY * 14,
                                left: 14 + effectiveTiltX * 16,
                                child: _FloatingLocationTag(
                                  tiltX: effectiveTiltX,
                                  tiltY: effectiveTiltY,
                                  label: widget.locationLabel,
                                  badge: widget.locationBadge,
                                ),
                              ),

                              // 4. FLOATING 3D TRANSIT STATUS BADGE (Top Left)
                              Positioned(
                                top:
                                    (widget.height < 250 ? 10 : 22) -
                                    effectiveTiltY * 10,
                                left: 14 + effectiveTiltX * 12,
                                child: _FloatingWeatherBadge(
                                  tiltX: effectiveTiltX,
                                  tiltY: effectiveTiltY,
                                  weatherText: widget.weatherText,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Floating Transit Compass with rotating direction dial & green jewel indicator
class _FloatingTransitCompass extends StatelessWidget {
  final double tiltX;
  final double tiltY;
  final double animProgress;

  const _FloatingTransitCompass({
    required this.tiltX,
    required this.tiltY,
    required this.animProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..setTranslationRaw(tiltX * 8, tiltY * 6, 25.0),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF0F5F2)],
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.95),
            width: 1.8,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0x240D2317),
              blurRadius: 14,
              offset: Offset(-tiltX * 5, 5 + tiltY * 3),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Transit Track Compass Rim
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: SafarTokens.mutedSage.withValues(alpha: 0.5),
                  width: 1.0,
                ),
              ),
            ),
            // Rotating Transit Needle (Synchronized to metro cycle)
            Transform.rotate(
              angle: animProgress * 2 * math.pi,
              child: SizedBox(
                width: 4,
                height: 28,
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: SafarTokens.transitGreen,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: const BoxDecoration(
                          color: SafarTokens.deepCharcoal,
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Center Green Jewel Pin
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: SafarTokens.transitGreen,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x6019AC8B),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating location tag with transit hub indicator
class _FloatingLocationTag extends StatelessWidget {
  final double tiltX;
  final double tiltY;
  final String label;
  final String badge;

  const _FloatingLocationTag({
    required this.tiltX,
    required this.tiltY,
    required this.label,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..setTranslationRaw(tiltX * 9, tiltY * 7, 28.0),
      child: GlassContainer(
        blur: 14.0,
        opacity: 0.88,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        borderRadius: BorderRadius.circular(SafarTokens.radiusFull),
        shadows: [
          BoxShadow(
            color: const Color(0x1F0A1F13),
            blurRadius: 16,
            offset: Offset(-tiltX * 4, 6 + tiltY * 3),
          ),
        ],
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: SafarTokens.transitGreen,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x8019AC8B),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: SafarTokens.deepCharcoal,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: SafarTokens.transitGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: SafarTokens.transitGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Floating Transit Status Tag
class _FloatingWeatherBadge extends StatelessWidget {
  final double tiltX;
  final double tiltY;
  final String weatherText;

  const _FloatingWeatherBadge({
    required this.tiltX,
    required this.tiltY,
    required this.weatherText,
  });

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..setTranslationRaw(tiltX * 6, tiltY * 5, 20.0),
      child: GlassContainer(
        blur: 12.0,
        opacity: 0.85,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        borderRadius: BorderRadius.circular(SafarTokens.radiusFull),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.directions_subway_rounded,
              size: 13,
              color: SafarTokens.transitGreen,
            ),
            const SizedBox(width: 5),
            Text(
              weatherText,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: SafarTokens.deepCharcoal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
