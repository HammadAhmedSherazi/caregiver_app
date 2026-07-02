import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/network/session_expired_notifier.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../../home/cubit/home_cubit.dart';

class AppSessionHandler extends StatefulWidget {
  const AppSessionHandler({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AppSessionHandler> createState() => _AppSessionHandlerState();
}

class _AppSessionHandlerState extends State<AppSessionHandler> {
  @override
  void initState() {
    super.initState();
    sl<SessionExpiredNotifier>().onSessionExpired = _onSessionExpired;
  }

  @override
  void dispose() {
    sl<SessionExpiredNotifier>().onSessionExpired = null;
    super.dispose();
  }

  void _onSessionExpired() {
    if (!mounted) return;
    context.read<AuthCubit>().handleSessionExpired();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous.status == AuthStatus.authenticated &&
          current.status == AuthStatus.unauthenticated,
      listener: (context, state) {
        context.read<HomeCubit>().reset();
      },
      child: BlocListener<AuthCubit, AuthState>(
        listenWhen: (previous, current) =>
            previous.status == AuthStatus.authenticated &&
            current.status == AuthStatus.unauthenticated &&
            current.errorMessage != null &&
            !current.isSubmitting,
        listener: (context, state) {
          final message = state.errorMessage;
          if (message == null || message.isEmpty) return;

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          context.read<AuthCubit>().clearActionError();
        },
        child: widget.child,
      ),
    );
  }
}
