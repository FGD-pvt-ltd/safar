import 'dart:async';
import 'package:flutter/material.dart';
import 'package:three_js/three_js.dart' as three;
import '../theme/tokens.dart';

/// 3D Proof of Concept Screen
/// Validates genuine 3D rendering with three_js on Android:
/// - Real 3D world coordinates (X, Y, Z)
/// - PerspectiveCamera with field of view and depth
/// - Directional and Ambient lighting
/// - Volumetric 3D BoxGeometry with Phong/Lambert material
/// - Continuous 3D rotation along multiple axes
class Poc3DScreen extends StatefulWidget {
  final VoidCallback onContinue;

  const Poc3DScreen({super.key, required this.onContinue});

  @override
  State<Poc3DScreen> createState() => _Poc3DScreenState();
}

class _Poc3DScreenState extends State<Poc3DScreen> {
  late three.ThreeJS threeJs;
  three.Mesh? cube;
  three.Mesh? ground;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    threeJs = three.ThreeJS(
      settings: three.Settings(
        clearColor: 0xE2F3EF, // Mint background
        clearAlpha: 1.0,
        antialias: true,
      ),
      onSetupComplete: () {
        if (mounted) {
          setState(() {
            _isReady = true;
          });
        }
      },
      setup: _setupScene,
    );
  }

  Future<void> _setupScene() async {
    // 1. Perspective Camera with real 3D depth
    threeJs.camera = three.PerspectiveCamera(
      45,
      threeJs.width / threeJs.height,
      0.1,
      1000,
    );
    threeJs.camera.position.setValues(3.5, 4.0, 5.0);

    // 2. 3D Scene
    threeJs.scene = three.Scene();

    // 3. Ambient & Directional Lights
    final ambientLight = three.AmbientLight(0xffffff, 0.7);
    threeJs.scene.add(ambientLight);

    final dirLight = three.DirectionalLight(0xffffff, 0.9);
    dirLight.position.setValues(6.0, 10.0, 5.0);
    threeJs.scene.add(dirLight);

    // 4. Ground plane (X-Z plane at Y = -1.0)
    final groundGeo = three.BoxGeometry(8.0, 0.2, 8.0);
    final groundMat = three.MeshLambertMaterial.fromMap({
      'color': 0xF7F8F5, // Warm Ivory
    });
    ground = three.Mesh(groundGeo, groundMat);
    ground!.position.setValues(0, -1.0, 0);
    threeJs.scene.add(ground);

    // 5. 3D Volumetric Cube with Transit Green material
    final cubeGeo = three.BoxGeometry(1.6, 1.6, 1.6);
    final cubeMat = three.MeshPhongMaterial.fromMap({
      'color': 0x19AC8B, // SAFAR Transit Green
      'specular': 0x444444,
      'shininess': 30,
    });
    cube = three.Mesh(cubeGeo, cubeMat);
    cube!.position.setValues(0, 0.5, 0);
    threeJs.scene.add(cube);

    // 6. Camera lookAt origin
    threeJs.camera.lookAt(three.Vector3(0, 0, 0));

    // 7. Continuous 3D animation loop
    threeJs.addAnimationEvent((dt) {
      if (cube != null) {
        cube!.rotation.x += 0.015;
        cube!.rotation.y += 0.02;
        cube!.rotation.z += 0.008;
      }
    });
  }

  @override
  void dispose() {
    threeJs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SafarTokens.mintBackground,
      body: Stack(
        children: [
          // 3D Canvas
          Positioned.fill(child: threeJs.build()),

          // Header Overlay
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: SafarTokens.deepCharcoal.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: SafarTokens.softMint,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.view_in_ar_rounded,
                      color: SafarTokens.transitGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'SAFAR 3D Engine PoC',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: SafarTokens.deepCharcoal,
                          ),
                        ),
                        Text(
                          _isReady
                              ? 'Hardware OpenGL ES active'
                              : 'Initializing 3D renderer...',
                          style: TextStyle(
                            fontSize: 12,
                            color: _isReady
                                ? SafarTokens.transitGreen
                                : SafarTokens.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Action
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: ElevatedButton(
              onPressed: widget.onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: SafarTokens.transitGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Proceed to Full 3D Scene',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
