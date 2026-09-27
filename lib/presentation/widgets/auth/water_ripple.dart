import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Concentric rings that spread out from the centre like a drop hitting still
/// water. Each wave is a bright crest followed by a fainter trough ring, and
/// waves are staggered so the surface is never still.
///
/// Fills its parent and paints around the parent's centre; waves are not
/// clipped to the parent, so place it with `Positioned.fill` inside a Stack
/// and let an ancestor clip. Honours the platform "reduce motion" setting by
/// drawing a still frame.
class WaterRipple extends StatefulWidget {
  const WaterRipple({
    super.key,
    this.size = 250,
    this.waves = 3,
    this.period = const Duration(milliseconds: 4200),
    this.color = Colors.white,
  });

  /// Diameter of a wave at its resting size; waves grow from 0.55× to 1.55×.
  final double size;
  final int waves;
  final Duration period;
  final Color color;

  @override
  State<WaterRipple> createState() => _WaterRippleState();
}

class _WaterRippleState extends State<WaterRipple>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.period);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller
        ..stop()
        ..value = 0.35;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _RipplePainter(
            progress: _controller,
            waves: widget.waves,
            baseRadius: widget.size / 2,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}

class _RipplePainter extends CustomPainter {
  _RipplePainter({
    required this.progress,
    required this.waves,
    required this.baseRadius,
    required this.color,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final int waves;
  final double baseRadius;
  final Color color;

  static const _grow = Curves.easeOutCubic;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);

    for (var i = 0; i < waves; i++) {
      final t = (progress.value + i / waves) % 1.0;
      _paintWave(canvas, center, t);
    }

    // The moment a new wave is born, the surface at the centre flashes
    // briefly, like the splash of the drop itself.
    final birth = (progress.value * waves) % 1.0;
    if (birth < 0.18) {
      final k = 1 - birth / 0.18;
      canvas.drawCircle(
        center,
        baseRadius * (0.35 + 0.2 * (1 - k)),
        Paint()
          ..shader = RadialGradient(
            colors: [
              color.withValues(alpha: 0.14 * k),
              color.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(center: center, radius: baseRadius * 0.55),
          ),
      );
    }
  }

  void _paintWave(Canvas canvas, Offset center, double t) {
    final radius = baseRadius * (0.55 + _grow.transform(t));

    // Fade in quickly, then die away as the wave spreads out and loses energy.
    final fadeIn = (t / 0.15).clamp(0.0, 1.0);
    final fadeOut = math.pow(1 - t, 1.4).toDouble();
    final alpha = fadeIn * fadeOut;
    if (alpha <= 0.01) return;

    // Crests get thinner as they travel outwards.
    final thickness = 1.8 - 1.0 * t;

    // Soft glow band behind the crest.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10 * (1 - t) + 4
        ..color = color.withValues(alpha: 0.05 * alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Leading crest.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness
        ..color = color.withValues(alpha: 0.34 * alpha),
    );

    // Trailing trough, a little behind the crest and fainter.
    canvas.drawCircle(
      center,
      radius * (0.86 + 0.04 * t),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness * 0.6
        ..color = color.withValues(alpha: 0.16 * alpha),
    );
  }

  @override
  bool shouldRepaint(covariant _RipplePainter oldDelegate) =>
      oldDelegate.waves != waves ||
      oldDelegate.baseRadius != baseRadius ||
      oldDelegate.color != color;
}
