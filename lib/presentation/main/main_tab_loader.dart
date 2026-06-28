import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../auth/cubit/auth_cubit.dart';
import '../home/cubit/home_cubit.dart';
import '../profile/cubit/profile_cubit.dart';
import '../schedule/cubit/schedule_cubit.dart';
import '../task/cubit/task_cubit.dart';
import 'widgets/main_bottom_nav_bar.dart';

/// Triggers the GET API for the selected main bottom tab.
void reloadMainTab(BuildContext context, MainTab tab) {
  switch (tab) {
    case MainTab.home:
      context.read<HomeCubit>().loadDashboard();
    case MainTab.schedule:
      final scheduleCubit = context.read<ScheduleCubit>();
      scheduleCubit.loadSchedule(
        selectedDate: scheduleCubit.state.data?.selectedDate,
      );
    case MainTab.task:
      context.read<TaskCubit>().loadTasks();
    case MainTab.profile:
      final user = context.read<AuthCubit>().state.user;
      context.read<ProfileCubit>().loadProfile(user: user);
  }
}
