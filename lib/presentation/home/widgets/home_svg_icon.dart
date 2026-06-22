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
    return SizedBox(
      width: width,
      height: height,
      child: SvgPicture.asset(
        asset,
        width: width,
        height: height,
        fit: BoxFit.contain,
        alignment: Alignment.center,
        colorFilter: color != null
            ? ColorFilter.mode(color!, BlendMode.srcIn)
            : null,
        placeholderBuilder: (_) => SizedBox(width: width, height: height),
      ),
    );
  }
}
