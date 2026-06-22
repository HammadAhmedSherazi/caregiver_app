import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_constants.dart';
import 'core/di/service_locator.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_fonts.dart';
import 'core/theme/app_theme.dart';
import 'presentation/app_gate/view/app_gate_view.dart';
import 'presentation/auth/cubit/auth_cubit.dart';
import 'presentation/home/cubit/home_cubit.dart';
import 'presentation/profile/cubit/profile_cubit.dart';
import 'presentation/schedule/cubit/schedule_cubit.dart';
import 'presentation/task/cubit/task_cubit.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => sl<AuthCubit>()..initialize(),
        ),
        BlocProvider(
          create: (_) => sl<HomeCubit>(),
        ),
        BlocProvider(
          create: (_) => sl<ScheduleCubit>(),
        ),
        BlocProvider(
          create: (_) => sl<ProfileCubit>(),
        ),
        BlocProvider(
          create: (_) => sl<TaskCubit>(),
        ),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,
        builder: (context, child) {
          return DefaultTextStyle(
            style: AppFonts.base(
              fontSize: 14,
              fontWeight: AppFonts.regular,
              color: AppColors.textPrimary,
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const AppGateView(),
      ),
    );
  }
}
