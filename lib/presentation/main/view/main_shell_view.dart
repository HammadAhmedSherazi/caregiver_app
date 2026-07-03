import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../../home/cubit/home_cubit.dart';
import '../../widgets/get_request_view.dart';
import '../../home/cubit/home_state.dart';
import '../../home/view/home_tab_view.dart';
import '../../home/widgets/home_svg_icon.dart';
import '../../inbox/view/inbox_view.dart';
import '../../notifications/view/notifications_view.dart';
import '../../profile/view/profile_tab_view.dart';
import '../../schedule/view/schedule_tab_view.dart';
import '../../task/view/task_tab_view.dart';
import '../main_tab_loader.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      reloadMainTab(context, MainTab.home);
    });
  }

  void _selectTab(MainTab tab) {
    setState(() => _selectedTab = tab);
    reloadMainTab(context, tab);
  }

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
        _selectTab(MainTab.home);
      case SideMenuDestination.schedule:
        _selectTab(MainTab.schedule);
      case SideMenuDestination.profile:
        _selectTab(MainTab.profile);
      case SideMenuDestination.task:
        _selectTab(MainTab.task);
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

    await LogoutDialog.show(context);
  }

  void _showPlaceholderSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PostActionListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          current.errorMessage != null &&
          current.errorMessage != previous.errorMessage &&
          (previous.isSubmitting || current.isSubmitting),
      errorMessage: (state) => state.errorMessage,
      onClearError: () => context.read<AuthCubit>().clearActionError(),
      child: BlocBuilder<HomeCubit, HomeState>(
      builder: (context, homeState) {
        final hideBottomNav =
            homeState.showActiveShiftScreen || homeState.isEndingShift;
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
                onBack: () => _selectTab(MainTab.home),
              ),
              const TaskTabView(),
              const ProfileTabView(),
            ],
          ),
          floatingActionButton: !homeState.showActiveShiftScreen &&
                  _selectedTab == MainTab.home
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
                  onTabSelected: _selectTab,
                ),
        );
      },
    ),
    );
  }
}
