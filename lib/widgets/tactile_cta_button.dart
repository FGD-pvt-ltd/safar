import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class TactileCtaButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final double height;
  final IconData icon;

  const TactileCtaButton({
    super.key,
    required this.label,
    required this.onTap,
    this.height = 58.0,
    this.icon = Icons.arrow_forward_rounded,
  });

  @override
  State<TactileCtaButton> createState() => _TactileCtaButtonState();
}

class _TactileCtaButtonState extends State<TactileCtaButton> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final scale = _isPressed ? 0.96 : (_isHovered ? 1.02 : 1.0);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) {
          setState(() => _isPressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF26C289),
                  Color(0xFF1EB980),
                  Color(0xFF159765),
                ],
              ),
              borderRadius: BorderRadius.circular(SafarTokens.radiusFull),
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFF1EB980,
                  ).withValues(alpha: _isHovered ? 0.45 : 0.32),
                  blurRadius: _isHovered ? 26 : 18,
                  offset: const Offset(0, 8),
                  spreadRadius: _isHovered ? 1 : -1,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Subtle top edge highlight for tactile depth
                Positioned(
                  top: 1,
                  left: 20,
                  right: 20,
                  height: 1.5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Button Content: Label + Sliding Arrow
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 10),
                      AnimatedSlide(
                        offset: Offset(
                          _isHovered || _isPressed ? 0.25 : 0.0,
                          0.0,
                        ),
                        duration: const Duration(milliseconds: 160),
                        curve: Curves.easeOutCubic,
                        child: Icon(widget.icon, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
