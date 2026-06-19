import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';

/// Reusable auth/onboarding gradient background from Figma.
/// Fills the screen and layers decorative glow blobs.
/// The dashed curve line is optional and shown only on onboarding.
class AuthGradientBackground extends StatelessWidget {
  const AuthGradientBackground({
    super.key,
    this.child,
    this.showCurveLine = false,
  });

  final Widget? child;
  final bool showCurveLine;

  static const double _curveAspectRatio = 542 / 430;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: AppColors.authBackground),
        _AuthGradientDecorations(showCurveLine: showCurveLine),
        ?child,
      ],
    );
  }
}

class _AuthGradientDecorations extends StatelessWidget {
  const _AuthGradientDecorations({required this.showCurveLine});

  final bool showCurveLine;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final curveWidth = width;
        final curveHeight = curveWidth * AuthGradientBackground._curveAspectRatio;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            _GlowBlob(
              left: width * -0.253,
              top: height * -0.22,
              width: width * 0.967,
              height: height * 0.379,
              color: AppColors.authGlowTop,
            ),
            if (showCurveLine)
              Positioned(
                left: 0,
                top: 0,
                width: curveWidth,
                height: curveHeight,
                child: SvgPicture.asset(
                  AppAssets.curveLine,
                  fit: BoxFit.fill,
                ),
              ),
            _GlowBlob(
              left: width * -0.602,
              top: height * 0.738,
              width: width * 1.405,
              height: height * 0.55,
              color: AppColors.authGlowBottom,
            ),
          ],
        );
      },
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.color,
  });

  final double left;
  final double top;
  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color,
                color.withValues(alpha: 0.35),
                color.withValues(alpha: 0),
              ],
              stops: const [0, 0.55, 1],
            ),
          ),
        ),
      ),
    );
  }
}
