import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/sun_times.dart';

class SunArcWidget extends StatelessWidget {
  final double sunAngle;
  final bool isLoading;
  final TimePeriod timePeriod;

  const SunArcWidget({
    super.key,
    required this.sunAngle,
    required this.isLoading,
    required this.timePeriod,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: SunArcPainter(
        sunAngle: sunAngle,
        arcColor: timePeriod == TimePeriod.night
            ? Colors.white24
            : Colors.white.withOpacity(0.6),
        showSun: !isLoading,
      ),
      size: const Size(double.infinity, 180),
    );
  }
}

class SunArcPainter extends CustomPainter {
  final double sunAngle;
  final Color arcColor;
  final bool showSun;

  SunArcPainter({
    required this.sunAngle,
    required this.arcColor,
    required this.showSun,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 20);
    final radius = size.width / 2 - 20;

    final arcPaint = Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      math.pi,
      math.pi,
      false,
      arcPaint,
    );

    if (!showSun) return;

    final sunX = center.dx - radius * math.cos(sunAngle);
    final sunY = center.dy - radius * math.sin(sunAngle);

    final glowPaint = Paint()
      ..color = Colors.orange.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(sunX, sunY), 16, glowPaint);

    final sunPaint = Paint()..color = Colors.orangeAccent;
    canvas.drawCircle(Offset(sunX, sunY), 10, sunPaint);

    final highlightPaint = Paint()..color = Colors.yellow;
    canvas.drawCircle(Offset(sunX - 2, sunY - 2), 5, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant SunArcPainter oldDelegate) {
    return oldDelegate.sunAngle != sunAngle ||
        oldDelegate.arcColor != arcColor ||
        oldDelegate.showSun != showSun;
  }
}