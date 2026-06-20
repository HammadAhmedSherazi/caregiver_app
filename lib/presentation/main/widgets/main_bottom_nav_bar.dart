import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../home/widgets/home_svg_icon.dart';

enum MainTab { home, schedule, task, profile }

class MainBottomNavBar extends StatelessWidget {
  const MainBottomNavBar({
    super.key,
    required this.selectedTab,
    required this.onTabSelected,
  });

  final MainTab selectedTab;
  final ValueChanged<MainTab> onTabSelected;

  static const _items = [
    (tab: MainTab.home, icon: AppAssets.icHomeNavHome, label: 'Home'),
    (tab: MainTab.schedule, icon: AppAssets.icHomeNavSchedule, label: 'Schedule'),
    (tab: MainTab.task, icon: AppAssets.icHomeNavTask, label: 'Task'),
    (tab: MainTab.profile, icon: AppAssets.icHomeNavProfile, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(25, 0, 25, 16),
        child: Container(
          height: 81,
          decoration: BoxDecoration(
            color: AppColors.homeNavBar,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.homeCardShadow,
                blurRadius: 26,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _items.map((item) {
              final isSelected = selectedTab == item.tab;
              final opacity = isSelected ? 1.0 : 0.3;

              return Expanded(
                child: InkWell(
                  onTap: () => onTabSelected(item.tab),
                  borderRadius: BorderRadius.circular(16),
                  child: Opacity(
                    opacity: opacity,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        HomeSvgIcon(
                          asset: item.icon,
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(height: 7),
                        Text(
                          item.label,
                          style: AppTextStyles.homeNavLabel,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
