import 'package:flutter/material.dart';

import 'home_svg_icon.dart';
import '../../../core/theme/app_colors.dart';

/// Figma icon container — light blue rounded box (#DFEAFF, 13px radius).
class HomeIconBox extends StatelessWidget {
  const HomeIconBox({
    super.key,
    required this.iconAsset,
    this.width = 48,
    this.height = 47,
    this.iconSize = 24,
    this.borderRadius = 13,
    this.color,
    this.boxColor,
  });

  final String iconAsset;
  final double width;
  final double height;
  final double iconSize;
  final double borderRadius;
  final Color? color;
  final Color? boxColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: boxColor ?? AppColors.homeIconTint,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: HomeSvgIcon(
        asset: iconAsset,
        width: iconSize,
        height: iconSize,
        color: color,
      ),
    );
  }
}

/// Initials badge using the same Figma box styling as icon containers.
class HomeInitialsBox extends StatelessWidget {
  const HomeInitialsBox({
    super.key,
    required this.initials,
    this.width = 48,
    this.height = 47,
    this.borderRadius = 13,
    this.backgroundColor,
  });

  final String initials;
  final double width;
  final double height;
  final double borderRadius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.homeIconTint,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.homePrimary,
          height: 1.43,
          letterSpacing: -0.8,
        ),
      ),
    );
  }
}
