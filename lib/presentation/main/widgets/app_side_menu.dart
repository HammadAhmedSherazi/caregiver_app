import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../../home/widgets/home_svg_icon.dart';
import '../../widgets/user_avatar.dart';
import '../widgets/main_bottom_nav_bar.dart';

enum SideMenuDestination {
  dashboard,
  schedule,
  profile,
  task,
  inbox,
  settings,
  privacy,
  faq,
  logout,
}

/// Figma node `1:3088` — side navigation drawer.
class AppSideMenu extends StatelessWidget {
  const AppSideMenu({
    super.key,
    required this.selectedTab,
    required this.onDestinationSelected,
    required this.onLogoutTap,
    this.appTitle = 'ERP Caregiver',
    this.subtitle = 'Caregiver Portal',
  });

  final MainTab selectedTab;
  final ValueChanged<SideMenuDestination> onDestinationSelected;
  final VoidCallback onLogoutTap;
  final String appTitle;
  final String subtitle;

  static const _headerHeight = 261.0;
  static const _panelOverlap = 90.0;

  static const _mainItems = [
    (
      destination: SideMenuDestination.dashboard,
      tab: MainTab.home,
      icon: AppAssets.icHomeNavHome,
      label: 'Dashboard',
    ),
    (
      destination: SideMenuDestination.schedule,
      tab: MainTab.schedule,
      icon: AppAssets.icHomeNavSchedule,
      label: 'Schedule',
    ),
    (
      destination: SideMenuDestination.profile,
      tab: MainTab.profile,
      icon: AppAssets.icHomeNavProfile,
      label: 'Profile',
    ),
    (
      destination: SideMenuDestination.task,
      tab: MainTab.task,
      icon: AppAssets.icHomeNavTask,
      label: 'Task',
    ),
    (
      destination: SideMenuDestination.inbox,
      tab: null,
      icon: AppAssets.icHomeBell,
      label: 'Inbox',
    ),
  ];

  static const _supportItems = [
    (
      destination: SideMenuDestination.settings,
      icon: AppAssets.icHomeInfo,
      label: 'Settings',
    ),
    (
      destination: SideMenuDestination.privacy,
      icon: AppAssets.icHomeCarePlan,
      label: 'Privacy & Policy',
    ),
    (
      destination: SideMenuDestination.faq,
      icon: AppAssets.icHomeInfo,
      label: 'FAQ',
    ),
    (
      destination: SideMenuDestination.logout,
      icon: AppAssets.icLogout,
      label: 'Logout',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.homeHeader,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: _headerHeight,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appTitle,
                            style: context.responsiveStyle(
                              AppTextStyles.homeWelcome,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: context.responsiveStyle(
                              AppTextStyles.homeDate,
                            ),
                          ),
                        ],
                      ),
                    ),
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, authState) {
                        final user = authState.user;
                        return UserAvatar(
                          imageUrl: user?.avatarUrl,
                          name: user?.name ?? subtitle,
                          size: 50,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -_panelOverlap),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
                  children: [
                    _SectionLabel(label: 'MAIN'),
                    const SizedBox(height: 8),
                    ..._mainItems.map(
                      (item) => _MenuItemTile(
                        icon: item.icon,
                        label: item.label,
                        isActive: item.tab != null && item.tab == selectedTab,
                        onTap: () => onDestinationSelected(item.destination),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SectionLabel(label: 'DETAILS & SUPPORT'),
                    const SizedBox(height: 8),
                    ..._supportItems.map(
                      (item) => _MenuItemTile(
                        icon: item.icon,
                        label: item.label,
                        isActive: false,
                        onTap: () {
                          if (item.destination == SideMenuDestination.logout) {
                            onLogoutTap();
                            return;
                          }
                          onDestinationSelected(item.destination);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Text(
        label,
        style: context.responsiveStyle(
          AppTextStyles.homeNavLabel.copyWith(
            fontSize: 12,
            letterSpacing: 1.2,
            color: AppColors.homeMutedText,
          ),
        ),
      ),
    );
  }
}

class _MenuItemTile extends StatelessWidget {
  const _MenuItemTile({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  static const _itemHeight = 62.0;

  @override
  Widget build(BuildContext context) {
    final textStyle = context.responsiveStyle(
      AppTextStyles.titleMedium.copyWith(
        fontWeight: FontWeight.w500,
        color: isActive ? AppColors.authOnGradient : AppColors.homeDarkText,
      ),
    );

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          HomeSvgIcon(
            asset: icon,
            width: 20,
            height: 20,
            color: isActive ? AppColors.authOnGradient : AppColors.homeDarkText,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: textStyle),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: _itemHeight,
            child: isActive
                ? DecoratedBox(
                    decoration: const BoxDecoration(
                      color: AppColors.homeNavBar,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 4,
                          height: _itemHeight,
                          color: AppColors.homeNavBar,
                        ),
                        Expanded(child: content),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      Container(
                        width: 4,
                        height: _itemHeight,
                        color: AppColors.homeDarkText,
                      ),
                      Expanded(child: content),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
