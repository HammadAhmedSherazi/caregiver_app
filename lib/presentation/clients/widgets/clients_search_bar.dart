import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../home/widgets/home_svg_icon.dart';

/// Figma node `1:2202` — clients search field.
class ClientsSearchBar extends StatelessWidget {
  const ClientsSearchBar({
    super.key,
    required this.controller,
    this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 19),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: AppColors.homeCardShadow,
            blurRadius: 26,
            offset: Offset(0, 24),
          ),
        ],
      ),
      child: Row(
        children: [
          const HomeSvgIcon(
            asset: AppAssets.icSearchTwotone,
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: context.responsiveStyle(AppTextStyles.homeCardSubtitle),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search Clients',
                hintStyle: context.responsiveStyle(
                  AppTextStyles.homeCardSubtitle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
