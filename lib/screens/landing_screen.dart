import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../widgets/interactive_3d_hero.dart';
import '../widgets/tactile_cta_button.dart';

class LandingScreen extends StatefulWidget {
  final VoidCallback onGetStarted;

  const LandingScreen({super.key, required this.onGetStarted});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _badgeAnim;

  @override
  void initState() {
    super.initState();
    _badgeAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _badgeAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isCompact = mediaQuery.size.height < 700;

    return Scaffold(
      backgroundColor: SafarTokens.mintBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // 1. TOP PROGRESS DASHES (from reference design)
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 5,
                    decoration: BoxDecoration(
                      color: SafarTokens.tealPrimary,
                      borderRadius: BorderRadius.circular(
                        SafarTokens.radiusFull,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    width: 6,
                    height: 5,
                    decoration: BoxDecoration(
                      color: SafarTokens.tealPrimary.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(
                        SafarTokens.radiusFull,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    width: 6,
                    height: 5,
                    decoration: BoxDecoration(
                      color: SafarTokens.tealPrimary.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(
                        SafarTokens.radiusFull,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: isCompact ? 16 : 24),

              // 2. HEADLINE & 3D FLOATING CAMERA BADGE
              Text(
                "It's a Big World",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: SafarTokens.textMuted,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),

              Stack(
                clipBehavior: Clip.none,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Out There,\n',
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(
                                color: SafarTokens.textDark,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                        ),
                        TextSpan(
                          text: 'Go Explore',
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(
                                color: SafarTokens.textDark,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                              ),
                        ),
                      ],
                    ),
                  ),

                  // Floating 3D Travel Camera Badge
                  Positioned(
                    right: 32,
                    bottom: 4,
                    child: AnimatedBuilder(
                      animation: _badgeAnim,
                      builder: (context, child) {
                        final wave = math.sin(_badgeAnim.value * math.pi * 2);
                        return Transform(
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.001)
                            ..setTranslationRaw(0.0, wave * 6, 20.0)
                            ..rotateZ(wave * 0.08),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x200D2B1C),
                                  blurRadius: 16,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const _Camera3DIcon(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: isCompact ? 14 : 22),

              // 3. INTERACTIVE 3D PARALLAX HERO SCENE
              Expanded(
                child: Interactive3DHero(onExploreTap: widget.onGetStarted),
              ),

              SizedBox(height: isCompact ? 16 : 24),

              // 4. TACTILE CTA BUTTON
              TactileCtaButton(
                label: 'Get Started',
                onTap: widget.onGetStarted,
              ),

              const SizedBox(height: 12),

              // 5. PRIVACY POLICY
              Center(
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: SafarTokens.textMuted,
                  ),
                  child: const Text(
                    'Privacy Policy',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mini 3D-styled travel camera icon
class _Camera3DIcon extends StatelessWidget {
  const _Camera3DIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 28,
      decoration: BoxDecoration(
        color: const Color(0xFFE29B38),
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Camera top shutter bump
          Positioned(
            top: 2,
            right: 4,
            child: Container(
              width: 5,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFFC07C24),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          // Lens circle
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1E293B),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF38BDF8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
