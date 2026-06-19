import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/constants/app_assets.dart';

/// Reusable forward arrow icon for auth CTA buttons (Figma).
class AuthForwardIcon extends StatelessWidget {
  const AuthForwardIcon({
    super.key,
    this.size = 24,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      AppAssets.arrowForward,
      width: size,
      height: size,
    );
  }
}
