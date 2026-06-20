import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../../home/view/home_tab_view.dart';
import '../../home/widgets/home_svg_icon.dart';
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
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: IndexedStack(
        index: _selectedTab.index,
        children: const [
          HomeTabView(),
          _PlaceholderTab(title: 'Schedule'),
          _PlaceholderTab(title: 'Task'),
          _ProfileTab(),
        ],
      ),
      floatingActionButton: _selectedTab == MainTab.home
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
      bottomNavigationBar: MainBottomNavBar(
        selectedTab: _selectedTab,
        onTabSelected: (tab) => setState(() => _selectedTab = tab),
      ),
    );
  }
}

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        title,
        style: AppTextStyles.headlineSmall,
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Profile', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 16),
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                return Text(
                  state.user?.name ?? 'Caregiver',
                  style: AppTextStyles.titleMedium,
                );
              },
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => context.read<AuthCubit>().logout(),
              child: const Text('Sign Out'),
            ),
          ],
        ),
      ),
    );
  }
}
