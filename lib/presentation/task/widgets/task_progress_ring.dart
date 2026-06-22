import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Figma nodes `1:2831` (track) + `1:2832` (value arc).
class TaskProgressRing extends StatelessWidget {
  const TaskProgressRing({
    super.key,
    required this.progress,
    this.size = 145,
    this.strokeWidth = 17,
  });

  final double progress;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _TaskProgressRingPainter(
        progress: progress.clamp(0.0, 1.0),
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _TaskProgressRingPainter extends CustomPainter {
  _TaskProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
  });

  final double progress;
  final double strokeWidth;

  static const _startAngle = -math.pi / 2;
  static const _sweepAngle = math.pi * 1.55;
  static const _trackRotation = 143.02 * math.pi / 180;
  static const _valueRotation = -65.62 * math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final trackRadius = (size.shortestSide - strokeWidth) / 2 * 0.9;
    final valueRadius = (size.shortestSide - strokeWidth) / 2;

    _drawTrackArc(
      canvas,
      center,
      trackRadius,
    );

    if (progress > 0) {
      _drawValueArc(
        canvas,
        center,
        valueRadius,
      );
    }
  }

  void _drawTrackArc(Canvas canvas, Offset center, double radius) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..color = const Color(0xFFE8EFFE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_trackRotation);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawArc(rect, _startAngle, _sweepAngle, false, paint);
    canvas.restore();
  }

  void _drawValueArc(Canvas canvas, Offset center, double radius) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    final progressSweep = _sweepAngle * progress;
    final arcEnd = _startAngle + progressSweep;

    final paint = Paint()
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
          Color(0xFFC5D9FF),
          Color(0xFF76A3FF),
        ],
        stops: const [0.0, 0.38, 1.0],
      ).createShader(rect);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(_valueRotation);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawArc(rect, _startAngle, progressSweep, false, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _TaskProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
