// lib/widgets/buddy_widget.dart
// The animated robot mascot. Switches between idle and happy states.
// Uses only Flutter primitives — no image assets required.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BuddyWidget extends StatefulWidget {
  const BuddyWidget({
    super.key,
    required this.isHappy,
    required this.isSpeaking,
  });

  final bool isHappy;
  final bool isSpeaking;

  @override
  State<BuddyWidget> createState() => _BuddyWidgetState();
}

class _BuddyWidgetState extends State<BuddyWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(BuddyWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Bounce faster when speaking
    if (widget.isSpeaking && !oldWidget.isSpeaking) {
      _bounceController.duration = const Duration(milliseconds: 350);
      _bounceController.repeat(reverse: true);
    } else if (!widget.isSpeaking) {
      _bounceController.duration = const Duration(milliseconds: 700);
      _bounceController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bounceController,
      builder: (context, child) {
        final bounce = _bounceController.value * 6.0;
        return Transform.translate(
          offset: Offset(0, -bounce),
          child: child,
        );
      },
      child: _buildRobot(),
    );
  }

  Widget _buildRobot() {
    final Color bodyColor =
        widget.isHappy ? const Color(0xFF4CAF50) : const Color(0xFF5C6BC0);
    final Color accentColor =
        widget.isHappy ? const Color(0xFFFFEB3B) : const Color(0xFF80CBC4);

    return SizedBox(
      width: 120,
      height: 130,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow effect when happy
          if (widget.isHappy)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.4),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),

          // Robot body
          CustomPaint(
            size: const Size(100, 120),
            painter: _RobotPainter(
              bodyColor: bodyColor,
              accentColor: accentColor,
              isHappy: widget.isHappy,
              isSpeaking: widget.isSpeaking,
            ),
          ),
        ],
      ),
    )
        .animate(target: widget.isHappy ? 1 : 0)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.1, 1.1),
          duration: 300.ms,
          curve: Curves.elasticOut,
        );
  }
}

/// Custom painter for the robot character.
class _RobotPainter extends CustomPainter {
  const _RobotPainter({
    required this.bodyColor,
    required this.accentColor,
    required this.isHappy,
    required this.isSpeaking,
  });

  final Color bodyColor;
  final Color accentColor;
  final bool isHappy;
  final bool isSpeaking;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // ── Head ──────────────────────────────────────────────────────────────
    final headRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(15, 0, 70, 60),
      const Radius.circular(18),
    );
    paint.color = bodyColor;
    canvas.drawRRect(headRect, paint);

    // Head shine
    paint.color = Colors.white.withOpacity(0.2);
    canvas.drawOval(Rect.fromLTWH(22, 8, 25, 12), paint);

    // ── Antenna ──────────────────────────────────────────────────────────
    paint.color = bodyColor.withOpacity(0.8);
    paint.strokeWidth = 3;
    paint.style = PaintingStyle.stroke;
    canvas.drawLine(const Offset(50, 0), const Offset(50, -12), paint);
    paint.style = PaintingStyle.fill;
    paint.color = accentColor;
    canvas.drawCircle(const Offset(50, -14), 5, paint);

    // ── Eyes ──────────────────────────────────────────────────────────────
    // Left eye
    paint.color = Colors.white;
    canvas.drawOval(Rect.fromLTWH(23, 16, 22, 18), paint);
    paint.color = isHappy ? const Color(0xFF1E88E5) : const Color(0xFF263238);
    canvas.drawCircle(const Offset(34, 25), 7, paint);
    paint.color = Colors.white;
    canvas.drawCircle(const Offset(37, 22), 3, paint);

    // Right eye
    paint.color = Colors.white;
    canvas.drawOval(Rect.fromLTWH(55, 16, 22, 18), paint);
    paint.color = isHappy ? const Color(0xFF1E88E5) : const Color(0xFF263238);
    canvas.drawCircle(const Offset(66, 25), 7, paint);
    paint.color = Colors.white;
    canvas.drawCircle(const Offset(69, 22), 3, paint);

    // ── Mouth ─────────────────────────────────────────────────────────────
    final mouthPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final mouthPath = Path();
    if (isHappy) {
      // Big smile
      mouthPath.moveTo(30, 46);
      mouthPath.quadraticBezierTo(50, 62, 70, 46);
    } else if (isSpeaking) {
      // Open mouth (speaking)
      mouthPath.moveTo(32, 46);
      mouthPath.quadraticBezierTo(50, 54, 68, 46);
    } else {
      // Neutral line
      mouthPath.moveTo(34, 48);
      mouthPath.lineTo(66, 48);
    }
    canvas.drawPath(mouthPath, mouthPaint);

    // ── Body ──────────────────────────────────────────────────────────────
    paint.style = PaintingStyle.fill;
    paint.color = bodyColor.withOpacity(0.85);
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(10, 66, 80, 50),
      const Radius.circular(14),
    );
    canvas.drawRRect(bodyRect, paint);

    // Chest panel
    paint.color = accentColor.withOpacity(0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(28, 74, 44, 28),
        const Radius.circular(8),
      ),
      paint,
    );

    // Chest button
    paint.color = accentColor;
    canvas.drawCircle(const Offset(50, 88), 8, paint);

    // ── Neck connector ────────────────────────────────────────────────────
    paint.color = bodyColor.withOpacity(0.7);
    canvas.drawRect(Rect.fromLTWH(38, 60, 24, 8), paint);
  }

  @override
  bool shouldRepaint(_RobotPainter oldDelegate) =>
      oldDelegate.isHappy != isHappy ||
      oldDelegate.isSpeaking != isSpeaking ||
      oldDelegate.bodyColor != bodyColor;
}
