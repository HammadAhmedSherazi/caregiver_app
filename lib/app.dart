import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/constants/app_constants.dart';
import 'core/di/service_locator.dart';
import 'core/navigation/root_navigator.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_fonts.dart';
import 'core/theme/app_theme.dart';
import 'data/local/language_store.dart';
import 'presentation/app_gate/view/app_gate_view.dart';
import 'presentation/app_gate/widgets/app_session_handler.dart';
import 'presentation/auth/cubit/auth_cubit.dart';
import 'presentation/checkin/cubit/checkin_cubit.dart';
import 'presentation/documents/cubit/documents_cubit.dart';
import 'presentation/home/cubit/home_cubit.dart';
import 'presentation/profile/cubit/profile_cubit.dart';
import 'presentation/schedule/cubit/schedule_cubit.dart';
import 'presentation/task/cubit/task_cubit.dart';
import 'presentation/time/cubit/time_cubit.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<AuthCubit>()..initialize()),
        BlocProvider(create: (_) => sl<HomeCubit>()),
        BlocProvider(create: (_) => sl<ScheduleCubit>()),
        BlocProvider(create: (_) => sl<ProfileCubit>()),
        BlocProvider(create: (_) => sl<TaskCubit>()),
        BlocProvider(create: (_) => sl<TimeCubit>()),
        BlocProvider(create: (_) => sl<DocumentsCubit>()),
        BlocProvider(create: (_) => sl<CheckInCubit>()),
      ],
      child: AppSessionHandler(
        child: _LanguageScope(
          builder: (locale) => MaterialApp(
            locale: locale,
            supportedLocales: const [Locale('en'), Locale('ar')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            navigatorKey: rootNavigatorKey,
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
        ),
      ),
    );
  }
}

/// Rebuilds the whole app in the chosen language (English / Arabic) when it
/// changes on the sign-in screen or in Profile. Arabic also switches every
/// screen to right-to-left through [MaterialApp.locale].
class _LanguageScope extends StatefulWidget {
  const _LanguageScope({required this.builder});

  final Widget Function(Locale locale) builder;

  @override
  State<_LanguageScope> createState() => _LanguageScopeState();
}

class _LanguageScopeState extends State<_LanguageScope> {
  final _store = sl<LanguageStore>();
  late String _language = _store.current;

  @override
  void initState() {
    super.initState();
    _store.language.addListener(_onChange);
  }

  @override
  void dispose() {
    _store.language.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (_store.current == _language) return;
    setState(() => _language = _store.current);
    // Copy comes from tr(), which widgets don't depend on, so mark the whole
    // tree dirty once; navigation and screen state are kept.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      void rebuild(Element element) {
        element.markNeedsBuild();
        element.visitChildren(rebuild);
      }

      (context as Element).visitChildren(rebuild);
    });
  }

  @override
  Widget build(BuildContext context) => widget.builder(Locale(_language));
}
