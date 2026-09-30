import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/navigation/root_navigator.dart';
import '../../../core/network/chat_realtime_service.dart';
import '../../../core/network/session_expired_notifier.dart';
import '../../../core/push/firebase_push_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../../checkin/cubit/checkin_cubit.dart';
import '../../documents/cubit/documents_cubit.dart';
import '../../home/cubit/home_cubit.dart';
import '../../task/cubit/task_cubit.dart';
import '../../time/cubit/time_cubit.dart';
import '../../widgets/velora/velora.dart';
import '../../../core/i18n/tr.dart';

class AppSessionHandler extends StatefulWidget {
  const AppSessionHandler({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AppSessionHandler> createState() => _AppSessionHandlerState();
}

class _AppSessionHandlerState extends State<AppSessionHandler>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    sl<SessionExpiredNotifier>().onSessionExpired = _onSessionExpired;
    sl<FirebasePushService>().foregroundNotification.addListener(_onForegroundPush);
  }

  /// Android doesn't show a banner while the app is open, so show a toast.
  /// (iOS shows the system banner itself.)
  void _onForegroundPush() {
    final n = sl<FirebasePushService>().foregroundNotification.value;
    final context = rootNavigatorKey.currentContext;
    if (n == null || context == null || defaultTargetPlatform != TargetPlatform.android) return;
    final text = [n.title, n.body].whereType<String>().where((t) => t.isNotEmpty).join(' · ');
    if (text.isNotEmpty && ScaffoldMessenger.maybeOf(context) != null) showVeloraToast(context, text);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    sl<SessionExpiredNotifier>().onSessionExpired = null;
    sl<FirebasePushService>().foregroundNotification.removeListener(_onForegroundPush);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(_onAppResumed());
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // Close without logout — drop socket so reopen gets a clean subscribe.
        unawaited(sl<ChatRealtimeService>().suspend());
    }
  }

  Future<void> _onAppResumed() async {
    if (!mounted) return;
    final auth = context.read<AuthCubit>().state;
    if (auth.status != AuthStatus.authenticated) return;

    await sl<AuthRepository>().refreshSession();
    if (!mounted) return;
    await sl<ChatRealtimeService>().resume();
  }

  void _onSessionExpired() {
    if (!mounted) return;
    context.read<AuthCubit>().handleSessionExpired();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) {
        final push = sl<FirebasePushService>();
        if (state.status == AuthStatus.authenticated) {
          unawaited(push.onSignedIn());
        } else if (state.status == AuthStatus.unauthenticated) {
          push.onSignedOut();
        }
      },
      child: _sessionListeners(),
    );
  }

  Widget _sessionListeners() {
    return BlocListener<AuthCubit, AuthState>(
      listenWhen: (previous, current) =>
          previous.status == AuthStatus.authenticated &&
          current.status == AuthStatus.unauthenticated,
      listener: (context, state) {
        rootNavigatorKey.currentState?.popUntil((route) => route.isFirst);
        context.read<HomeCubit>().reset();
        context.read<TaskCubit>().reset();
        context.read<TimeCubit>().reset();
        context.read<DocumentsCubit>().reset();
        context.read<CheckInCubit>().reset();
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
                content: Text(tr(message)),
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
