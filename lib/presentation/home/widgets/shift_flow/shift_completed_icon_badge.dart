import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../home_svg_icon.dart';

class ShiftCompletedIconBadge extends StatelessWidget {
  const ShiftCompletedIconBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 99,
      height: 99,
      decoration: BoxDecoration(
        color: AppColors.homePrimary,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: const HomeSvgIcon(
        asset: AppAssets.icHomeShiftCompletedTick,
        width: 70,
        height: 70,
      ),
    );
  }
}
