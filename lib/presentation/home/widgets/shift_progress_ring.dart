import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Figma node `1:761` — shift countdown ring with gradient progress arc.
class ShiftProgressRing extends StatelessWidget {
  const ShiftProgressRing({
    super.key,
    required this.progress,
    required this.size,
    this.strokeWidth,
  });

  final double progress;
  final double size;
  final double? strokeWidth;

  @override
  Widget build(BuildContext context) {
    final stroke = strokeWidth ?? (size * 0.106).clamp(10.0, 14.0);

    return Transform.rotate(
      angle: _figmaValueRotation,
      child: CustomPaint(
        size: Size.square(size),
        painter: _ShiftProgressRingPainter(
          progress: progress.clamp(0.0, 1.0),
          strokeWidth: stroke,
        ),
      ),
    );
  }

  /// Figma value arc rotation (`Ellipse 3150`).
  static const _figmaValueRotation = -65.62 * math.pi / 180;
}

class _ShiftProgressRingPainter extends CustomPainter {
  _ShiftProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
  });

  final double progress;
  final double strokeWidth;

  static const _startAngle = -math.pi / 2;
  static const _sweepAngle = math.pi * 1.55;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = AppColors.homeProgressTrack
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, _startAngle, _sweepAngle, false, trackPaint);

    if (progress <= 0) {
      return;
    }

    final progressSweep = _sweepAngle * progress;
    final arcEnd = _startAngle + progressSweep;

    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        begin: Alignment(
          math.cos(_startAngle),
          math.sin(_startAngle),
        ),
        end: Alignment(
          math.cos(arcEnd),
          math.sin(arcEnd),
        ),
        colors: const [
          AppColors.homeProgressGradientEnd,
          Color(0xFFB8D0FF),
          AppColors.homeAccent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(rect);

    canvas.drawArc(rect, _startAngle, progressSweep, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _ShiftProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
