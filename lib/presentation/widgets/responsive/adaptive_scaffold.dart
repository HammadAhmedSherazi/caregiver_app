import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_breakpoints.dart';
import '../../../core/responsive/responsive_helper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'responsive_layout.dart';

/// Generic app shell — AppBar on mobile, NavigationRail on tablet/large.
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.selectedIndex = 0,
    this.destinations = const [],
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final int selectedIndex;
  final List<ShellNavItem> destinations;

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      mobile: _buildMobile,
      tablet: _buildRail,
      expanded: _buildRail,
    );
  }

  Widget _buildMobile(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: AppTextStyles.titleLarge),
        actions: actions,
      ),
      body: body,
    );
  }

  Widget _buildRail(BuildContext context) {
    final isExpanded = ResponsiveHelper.isExpanded(context);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: isExpanded,
            selectedIndex: selectedIndex,
            labelType: isExpanded
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.selected,
            backgroundColor: AppColors.sidebar,
            indicatorColor: AppColors.primary,
            selectedIconTheme: const IconThemeData(color: Colors.white),
            unselectedIconTheme: const IconThemeData(color: AppColors.textOnDark),
            selectedLabelTextStyle: const TextStyle(color: Colors.white),
            unselectedLabelTextStyle: const TextStyle(color: AppColors.textOnDark),
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary,
                    child: const Icon(
                      Icons.volunteer_activism,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  if (isExpanded) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Caregiver',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textOnDark,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            destinations: destinations
                .map(
                  (d) => NavigationRailDestination(
                    icon: d.icon,
                    selectedIcon: d.selectedIcon ?? d.icon,
                    label: Text(d.label),
                  ),
                )
                .toList(),
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  color: AppColors.surface,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(title, style: AppTextStyles.headlineSmall),
                      ),
                      ...?actions,
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: ResponsiveBreakpoints.gridMaxWidth,
                      ),
                      child: body,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ShellNavItem {
  const ShellNavItem({
    required this.icon,
    required this.label,
    this.selectedIcon,
  });

  final Widget icon;
  final Widget? selectedIcon;
  final String label;
}
