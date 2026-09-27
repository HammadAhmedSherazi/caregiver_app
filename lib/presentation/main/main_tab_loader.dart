import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../checkin/cubit/checkin_cubit.dart';
import '../documents/cubit/documents_cubit.dart';
import '../home/cubit/home_cubit.dart';
import '../task/cubit/task_cubit.dart';
import '../time/cubit/time_cubit.dart';
import 'widgets/main_bottom_nav_bar.dart';

/// Triggers the GET APIs for the selected main bottom tab.
void reloadMainTab(BuildContext context, MainTab tab) {
  switch (tab) {
    case MainTab.home:
      context.read<HomeCubit>().loadDashboard();
      // "Needs your attention" and pay come from the task page; "This week"
      // and missed clock-outs come from the visit history.
      context.read<TaskCubit>().loadTasks();
      context.read<TimeCubit>().load();
    case MainTab.time:
      context.read<TimeCubit>().load();
    case MainTab.checkIn:
      context.read<CheckInCubit>().load();
    case MainTab.pay:
      context.read<TaskCubit>().loadTasks();
    case MainTab.docs:
      context.read<DocumentsCubit>().load();
      context.read<TaskCubit>().loadTasks();
  }
}
