import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../widgets/app_splash_view.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../../auth/view/login_view.dart';
import '../../main/view/main_shell_view.dart';
import '../../onboarding/view/onboarding_view.dart';

class AppGateView extends StatelessWidget {
  const AppGateView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        return switch (state.status) {
          AuthStatus.initial || AuthStatus.loading => const AppSplashView(),
          AuthStatus.onboarding => const OnboardingView(),
          AuthStatus.unauthenticated => const LoginView(),
          AuthStatus.authenticated => const MainShellView(),
        };
      },
    );
  }
}
