import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utils/app_colors.dart';

/// Animated rotating upload button for the bottom navigation
class AnimatedUploadButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isUploading;

  const AnimatedUploadButton({
    super.key,
    required this.onPressed,
    this.isUploading = false,
  });

  @override
  State<AnimatedUploadButton> createState() => _AnimatedUploadButtonState();
}

class _AnimatedUploadButtonState extends State<AnimatedUploadButton>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _glowController;

  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // Rotation animation - continuous spinning
    _rotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotationController, curve: Curves.linear),
    );

    // Pulse animation - breathing effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Glow animation - pulsing glow
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _rotationAnimation,
          _pulseAnimation,
          _glowAnimation,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.accentGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentBright.withOpacity(
                      _glowAnimation.value,
                    ),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                  BoxShadow(
                    color: AppColors.accentBright.withOpacity(
                      _glowAnimation.value * 0.5,
                    ),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Rotating outer ring
                  Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryDark.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: CustomPaint(
                        painter: _ArcPainter(
                          color: AppColors.primaryDark,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  ),

                  // Inner circle with icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryDark,
                      border: Border.all(
                        color: AppColors.accentBright.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      widget.isUploading ? Icons.cloud_upload : Icons.add,
                      color: AppColors.accentBright,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter for the rotating arc effect
class _ArcPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _ArcPainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw three arcs at different positions
    for (int i = 0; i < 3; i++) {
      final startAngle = (i * 2 * math.pi / 3);
      const sweepAngle = math.pi / 3;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
