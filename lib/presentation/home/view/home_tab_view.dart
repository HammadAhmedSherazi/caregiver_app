import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../../data/models/home_dashboard_model.dart';
import '../../../data/repositories/client_repository.dart';
import '../../clients/view/client_profile_view.dart';
import '../../widgets/get_request_view.dart';
import '../../widgets/app_splash_view.dart';
import '../../widgets/skeletons/api_tab_skeletons.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../view/active_shift_view.dart';
import '../view/end_shift_view.dart';
import '../widgets/shift_flow/clock_in_flow.dart';
import '../widgets/home_icon_box.dart';
import '../widgets/home_svg_icon.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../../widgets/user_avatar.dart';
import '../widgets/shift_progress_ring.dart';
import '../widgets/start_shift_confirm_dialog.dart';
import '../widgets/vertical_overlap.dart';

class HomeTabView extends StatefulWidget {
  const HomeTabView({
    super.key,
    this.onOpenMenu,
    this.onOpenNotifications,
  });

  final VoidCallback? onOpenMenu;
  final VoidCallback? onOpenNotifications;

  @override
  State<HomeTabView> createState() => _HomeTabViewState();
}

class _HomeTabViewState extends State<HomeTabView> {
  Future<void> _openClientProfile(BuildContext context, String clientName) async {
    final client = await sl<ClientRepository>().findByName(clientName);
    if (!context.mounted || client == null) return;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ClientProfileView(client: client),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PostActionListener<HomeCubit, HomeState>(
      listenWhen: (previous, current) =>
          current.errorMessage != null &&
          current.errorMessage != previous.errorMessage &&
          current.dashboard != null,
      errorMessage: (state) => state.errorMessage,
      onClearError: () => context.read<HomeCubit>().clearActionError(),
      child: BlocListener<HomeCubit, HomeState>(
        listenWhen: (previous, current) =>
            current.infoMessage != null &&
            current.infoMessage != previous.infoMessage,
        listener: (context, state) {
          final message = state.infoMessage;
          if (message == null || message.isEmpty) return;

          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(message),
                behavior: SnackBarBehavior.floating,
              ),
            );
          context.read<HomeCubit>().clearActionError();
        },
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state.isLoading && state.dashboard == null) {
              return const AppSplashView();
            }

            return GetRequestView(
              isLoading: false,
              hasError: state.hasError,
              onRetry: () => context.read<HomeCubit>().loadDashboard(),
              skeleton: const HomeTabSkeleton(),
              child: _buildContent(context, state),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, HomeState state) {
        final dashboard = state.dashboard;
        if (dashboard == null) {
          return const SizedBox.shrink();
        }

        final shift = dashboard.activeShift;
        if (shift != null && state.showActiveShiftScreen) {
          if (state.isEndingShift) {
            return EndShiftView(shift: shift);
          }
          return ActiveShiftView(shift: shift);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HomeHeader(
              caregiverName: dashboard.caregiverName,
              dateLabel: dashboard.dateLabel,
              activeShift: dashboard.activeShift,
              unreadNotifications: dashboard.unreadNotifications,
              onOpenMenu: widget.onOpenMenu,
              onOpenNotifications: widget.onOpenNotifications,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => context.read<HomeCubit>().refresh(),
                color: AppColors.homePrimary,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 100, top: 30),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Today\'s Schedule',
                        style: context.responsiveStyle(
                          AppTextStyles.homeSectionTitle,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...dashboard.schedule.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                        child: _ScheduleCard(
                          entry: entry,
                          onTap: () => _openClientProfile(context, entry.clientName),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                      child: _StatsRow(summary: dashboard.taskSummary),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Pending Task',
                        style: context.responsiveStyle(
                          AppTextStyles.homeSectionTitle,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...dashboard.pendingTasks.map(
                      (task) => Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                        child: _PendingTaskCard(task: task),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.caregiverName,
    required this.dateLabel,
    required this.activeShift,
    this.unreadNotifications = 0,
    this.onOpenMenu,
    this.onOpenNotifications,
  });

  final String caregiverName;
  final String dateLabel;
  final ActiveShift? activeShift;
  final int unreadNotifications;
  final VoidCallback? onOpenMenu;
  final VoidCallback? onOpenNotifications;

  static const _headerHeight = 280.0;
  static const _headerHeightCompact = 132.0;
  static const _cardOverlap = 100.0;

  @override
  Widget build(BuildContext context) {
    final showShiftCard = activeShift != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRect(
          child: ColoredBox(
            color: AppColors.homeHeader,
            child: SizedBox(
              height: showShiftCard ? _headerHeight : _headerHeightCompact,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    left: 92,
                    top: -80,
                    width: 416,
                    height: 353,
                    child: ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.authGlowTop,
                              AppColors.authGlowTop.withValues(alpha: 0.35),
                              AppColors.authGlowTop.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome Back, $caregiverName',
                                  style: context.responsiveStyle(
                                    AppTextStyles.homeWelcome,
                                  ),
                                ),
                                Text(
                                  dateLabel,
                                  style: context.responsiveStyle(
                                    AppTextStyles.homeDate,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 15),
                            child: GestureDetector(
                              onTap: onOpenNotifications,
                              behavior: HitTestBehavior.opaque,
                              child: Badge(
                                isLabelVisible: unreadNotifications > 0,
                                label: Text(
                                  unreadNotifications > 99
                                      ? '99+'
                                      : '$unreadNotifications',
                                ),
                                smallSize: 8,
                                padding: EdgeInsets.zero,
                                backgroundColor: AppColors.authOnGradient,
                                child: const HomeSvgIcon(
                                  asset: AppAssets.icHomeBell,
                                  width: 24,
                                  height: 24,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          BlocBuilder<AuthCubit, AuthState>(
                            builder: (context, authState) {
                              final user = authState.user;
                              return GestureDetector(
                                onTap: onOpenMenu,
                                behavior: HitTestBehavior.opaque,
                                child: UserAvatar(
                                  imageUrl: user?.avatarUrl,
                                  name: user?.name ?? caregiverName,
                                  size: 50,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showShiftCard)
          VerticalOverlap(
            overlap: _cardOverlap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: _ActiveShiftCard(shift: activeShift!),
            ),
          ),
      ],
    );
  }
}

class _ActiveShiftCard extends StatelessWidget {
  const _ActiveShiftCard({required this.shift});

  final ActiveShift shift;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final ringSize = (cardWidth * 0.34).clamp(96.0, 132.0);
        final showRing = shift.showProgressRing && cardWidth >= 300;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            24,
            23,
            showRing ? 16 : 24,
            20,
          ),
          decoration: _cardDecoration(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      shift.cardHeading,
                      style: context.responsiveStyle(
                        AppTextStyles.homeCardSubtitle.copyWith(
                          color: AppColors.homeAccent,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const HomeIconBox(iconAsset: AppAssets.icHomeBanknote),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shift.clientName,
                                style: context.responsiveStyle(
                                  AppTextStyles.homeShiftClientName,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                shift.address,
                                style: context.responsiveStyle(
                                  AppTextStyles.homeAddress,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (shift.showStartShiftButton) ...[
                      const SizedBox(height: 15),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _StartShiftButton(
                          onPressed: () =>
                              _onStartShiftPressed(context, shift),
                        ),
                      ),
                    ],
                    SizedBox(height: shift.showStartShiftButton ? 20 : 12),
                    Text(
                      shift.cardScheduleLabel,
                      style: context.responsiveStyle(
                        AppTextStyles.homeCardSubtitle.copyWith(
                          color: AppColors.homeDarkText,
                          letterSpacing: -0.28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (showRing) ...[
                const SizedBox(width: 8),
                _ShiftCountdown(
                  minutes: shift.minutesUntilStart,
                  progress: shift.progress,
                  size: ringSize,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

Future<void> _onStartShiftPressed(
  BuildContext context,
  ActiveShift shift,
) async {
  final confirmed = await StartShiftConfirmDialog.show(context);
  if (!context.mounted || confirmed != true) {
    return;
  }

  final result = await ClockInFlow.run(context, shift: shift);
  if (!context.mounted || result == null) {
    return;
  }

  context.read<HomeCubit>().completeClockIn(
        clientName: result.clientName,
        serviceType: result.serviceType,
        clientId: shift.clientId,
        scheduleId: shift.scheduleId,
      );
}

class _StartShiftButton extends StatelessWidget {
  const _StartShiftButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.homeAccent,
      borderRadius: BorderRadius.circular(8),
      elevation: 0,
      shadowColor: AppColors.homeAccent.withValues(alpha: 0.1),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 165,
          height: 46,
          alignment: Alignment.center,
          child: Text(
            'Start Shift',
            textAlign: TextAlign.center,
            style: context.responsiveStyle(
              AppTextStyles.authLoginButtonLabel.copyWith(
                fontSize: 18,
                color: AppColors.authOnGradient,
                letterSpacing: -0.54,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShiftCountdown extends StatelessWidget {
  const _ShiftCountdown({
    required this.minutes,
    required this.progress,
    required this.size,
  });

  final int minutes;
  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    final stroke = (size * 0.106).clamp(10.0, 14.0);
    final valueStyle = context.responsiveStyle(
      AppTextStyles.homeShiftCountdownValue,
    );
    final labelStyle = context.responsiveStyle(
      AppTextStyles.homeShiftCountdownLabel,
    );

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ShiftProgressRing(
            progress: progress,
            size: size,
            strokeWidth: stroke,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$minutes', style: valueStyle),
              Text('in min', style: labelStyle),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.entry,
    this.onTap,
  });

  final ScheduleEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
      height: 92,
      padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          HomeInitialsBox(initials: entry.initials),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.clientName,
                        style: context.responsiveStyle(
                          AppTextStyles.homeCardTitle,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (entry.isHighPriority)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.homePriority.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Text(
                          'High Priority',
                          style: context.responsiveStyle(
                            AppTextStyles.labelSmall.copyWith(
                              color: AppColors.homePriority,
                              fontWeight: FontWeight.w500,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  entry.timeLabel,
                  style: context.responsiveStyle(AppTextStyles.homeCardSubtitle),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          HomeSvgIcon(
            asset: AppAssets.arrowForward,
            width: 24,
            height: 24,
            color: AppColors.authButtonText,
          ),
        ],
      ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.summary});

  final TaskSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 133,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.homePrimary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeSvgIcon(
                  asset: AppAssets.icHomeTaskDone,
                  width: 36,
                  height: 36,
                ),
                const Spacer(),
                Text(
                  '${summary.completedTasks}/${summary.totalTasks}',
                  style: context.responsiveStyle(
                    AppTextStyles.headlineSmall.copyWith(
                      color: AppColors.authOnGradient,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  'Task Done',
                  style: context.responsiveStyle(
                    AppTextStyles.homeCardSubtitle.copyWith(
                      color: AppColors.authOnGradient,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 22),
        Expanded(
          child: Container(
            height: 133,
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(radius: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HomeSvgIcon(
                  asset: AppAssets.icHomeTimer,
                  width: 24,
                  height: 24,
                ),
                const Spacer(),
                Text(
                  summary.remainingHours,
                  style: context.responsiveStyle(AppTextStyles.homeCardTitle),
                ),
                Text(
                  'Remaining',
                  style: context.responsiveStyle(AppTextStyles.homeCardSubtitle),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PendingTaskCard extends StatelessWidget {
  const _PendingTaskCard({required this.task});

  final PendingTask task;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 81,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          HomeIconBox(iconAsset: AppAssets.icHomeBox),
          const SizedBox(width: 19),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  task.timeLabel,
                  style: context.responsiveStyle(AppTextStyles.homeCardSubtitle),
                ),
                Text(
                  task.title,
                  style: context.responsiveStyle(AppTextStyles.homeCardTitle),
                ),
              ],
            ),
          ),
          HomeSvgIcon(
            asset: AppAssets.icHomePendingCheck,
            width: 36,
            height: 36,
          ),
        ],
      ),
    );
  }
}

BoxDecoration _cardDecoration({double radius = 20}) {
  return BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: const [
      BoxShadow(
        color: AppColors.homeCardShadow,
        blurRadius: 26,
        offset: Offset(0, 24),
      ),
    ],
  );
}
