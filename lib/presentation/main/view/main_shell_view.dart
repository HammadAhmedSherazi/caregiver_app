import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../../checkin/view/checkin_tab_view.dart';
import '../../documents/view/documents_tab_view.dart';
import '../../home/view/home_tab_view.dart';
import '../../pay/view/pay_tab_view.dart';
import '../../time/view/time_tab_view.dart';
import '../../widgets/get_request_view.dart';
import '../../widgets/velora/velora.dart';
import '../app_navigator.dart';
import '../main_tab_loader.dart';
import '../widgets/main_bottom_nav_bar.dart';

/// Signed-in shell: five tabs with the floating VELORA tab bar.
///
/// Inbox and Profile are opened from the Home header; every other page is
/// pushed on top through [AppNavigator].
class MainShellView extends StatefulWidget {
  const MainShellView({super.key});

  @override
  State<MainShellView> createState() => _MainShellViewState();
}

class _MainShellViewState extends State<MainShellView> {
  MainTab _selectedTab = MainTab.home;

  @override
  void initState() {
    super.initState();
    AppNavigator.registerTabSelector(_selectTab);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      reloadMainTab(context, MainTab.home);
    });
  }

  @override
  void dispose() {
    AppNavigator.unregisterTabSelector(_selectTab);
    super.dispose();
  }

  void _selectTab(MainTab tab) {
    if (!mounted) return;
    setState(() => _selectedTab = tab);
    reloadMainTab(context, tab);
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
      child: Scaffold(
          backgroundColor: VeloraColors.background,
          extendBody: true,
          body: IndexedStack(
            index: _selectedTab.index,
            children: const [
              HomeTabView(),
              TimeTabView(),
              CheckInTabView(),
              PayTabView(),
              DocumentsTabView(),
            ],
          ),
          bottomNavigationBar: MainBottomNavBar(
            selectedTab: _selectedTab,
            onTabSelected: _selectTab,
          ),
        ),
    );
  }
}
