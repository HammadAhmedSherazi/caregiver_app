import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Loads home SVG assets with flutter_svg-compatible settings.
class HomeSvgIcon extends StatelessWidget {
  const HomeSvgIcon({
    super.key,
    required this.asset,
    this.width = 24,
    this.height = 24,
    this.color,
  });

  final String asset;
  final double width;
  final double height;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: width,
      height: height,
      fit: BoxFit.contain,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
      placeholderBuilder: (_) => SizedBox(width: width, height: height),
    );
  }
}

/// Circular profile avatar from Figma export.
class HomeProfileAvatar extends StatelessWidget {
  const HomeProfileAvatar({
    super.key,
    required this.asset,
    this.size = 50,
    this.fallbackInitial = 'M',
  });

  final String asset;
  final double size;
  final String fallbackInitial;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            color: const Color(0xFF76A3FF),
            alignment: Alignment.center,
            child: Text(
              fallbackInitial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          );
        },
      ),
    );
  }
}
