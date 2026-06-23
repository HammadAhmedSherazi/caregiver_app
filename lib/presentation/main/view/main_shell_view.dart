import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../home/cubit/home_cubit.dart';
import '../../home/cubit/home_state.dart';
import '../../home/view/home_tab_view.dart';
import '../../home/widgets/home_svg_icon.dart';
import '../../inbox/view/inbox_view.dart';
import '../../notifications/view/notifications_view.dart';
import '../../profile/view/profile_tab_view.dart';
import '../../schedule/view/schedule_tab_view.dart';
import '../../task/view/task_tab_view.dart';
import '../widgets/app_side_menu.dart';
import '../widgets/logout_dialog.dart';
import '../widgets/main_bottom_nav_bar.dart';

class MainShellView extends StatefulWidget {
  const MainShellView({super.key});

  @override
  State<MainShellView> createState() => _MainShellViewState();
}

class _MainShellViewState extends State<MainShellView> {
  MainTab _selectedTab = MainTab.home;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const NotificationsView(),
      ),
    );
  }

  void _openInbox() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const InboxView(),
      ),
    );
  }

  Future<void> _handleSideMenuSelection(SideMenuDestination destination) async {
    Navigator.of(context).pop();

    switch (destination) {
      case SideMenuDestination.dashboard:
        setState(() => _selectedTab = MainTab.home);
      case SideMenuDestination.schedule:
        setState(() => _selectedTab = MainTab.schedule);
      case SideMenuDestination.profile:
        setState(() => _selectedTab = MainTab.profile);
      case SideMenuDestination.task:
        setState(() => _selectedTab = MainTab.task);
      case SideMenuDestination.inbox:
        _openInbox();
      case SideMenuDestination.settings:
        _showPlaceholderSnack('Settings coming soon');
      case SideMenuDestination.privacy:
        _showPlaceholderSnack('Privacy & Policy coming soon');
      case SideMenuDestination.faq:
        _showPlaceholderSnack('FAQ coming soon');
      case SideMenuDestination.logout:
        break;
    }
  }

  Future<void> _confirmLogout() async {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Navigator.of(context).pop();
    }

    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;

    final confirmed = await LogoutDialog.show(context);
    if (confirmed == true && mounted) {
      await context.read<AuthCubit>().logout();
    }
  }

  void _showPlaceholderSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, homeState) {
        final isActiveShift =
            homeState.dashboard?.activeShift.isInProgress ?? false;
        final hideBottomNav = isActiveShift || homeState.isEndingShift;
        final caregiverName = homeState.dashboard?.caregiverName;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: AppColors.homeBackground,
          drawer: Drawer(
            width: MediaQuery.sizeOf(context).width * 0.94,
            backgroundColor: AppColors.homeHeader,
            shape: const RoundedRectangleBorder(),
            child: AppSideMenu(
              selectedTab: _selectedTab,
              subtitle: caregiverName ?? 'Caregiver Portal',
              onDestinationSelected: _handleSideMenuSelection,
              onLogoutTap: _confirmLogout,
            ),
          ),
          body: IndexedStack(
            index: _selectedTab.index,
            children: [
              HomeTabView(
                onOpenMenu: () => _scaffoldKey.currentState?.openDrawer(),
                onOpenNotifications: _openNotifications,
              ),
              ScheduleTabView(
                onBack: () => setState(() => _selectedTab = MainTab.home),
              ),
              const TaskTabView(),
              const ProfileTabView(),
            ],
          ),
          floatingActionButton: !isActiveShift && _selectedTab == MainTab.home
              ? FloatingActionButton(
                  onPressed: _openInbox,
                  backgroundColor: AppColors.homeAccent,
                  elevation: 8,
                  shape: const CircleBorder(),
                  child: const HomeSvgIcon(
                    asset: AppAssets.icHomeMessage,
                    width: 24,
                    height: 24,
                  ),
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          bottomNavigationBar: hideBottomNav
              ? null
              : MainBottomNavBar(
                  selectedTab: _selectedTab,
                  onTabSelected: (tab) => setState(() => _selectedTab = tab),
                ),
        );
      },
    );
  }
}
