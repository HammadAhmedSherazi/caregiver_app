import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../home/cubit/home_cubit.dart';
import '../../home/cubit/home_state.dart';
import '../../home/view/home_tab_view.dart';
import '../../home/widgets/home_svg_icon.dart';
import '../../profile/view/profile_tab_view.dart';
import '../../schedule/view/schedule_tab_view.dart';
import '../../task/view/task_tab_view.dart';
import '../widgets/main_bottom_nav_bar.dart';

class MainShellView extends StatefulWidget {
  const MainShellView({super.key});

  @override
  State<MainShellView> createState() => _MainShellViewState();
}

class _MainShellViewState extends State<MainShellView> {
  MainTab _selectedTab = MainTab.home;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, homeState) {
          final isActiveShift =
              homeState.dashboard?.activeShift.isInProgress ?? false;
          final hideBottomNav = isActiveShift || homeState.isEndingShift;

          return Scaffold(
            backgroundColor: AppColors.homeBackground,
            body: IndexedStack(
              index: _selectedTab.index,
              children: [
                const HomeTabView(),
                ScheduleTabView(
                  onBack: () => setState(() => _selectedTab = MainTab.home),
                ),
                const TaskTabView(),
                const ProfileTabView(),
              ],
            ),
            floatingActionButton: !isActiveShift && _selectedTab == MainTab.home
                ? FloatingActionButton(
                    onPressed: () {},
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
