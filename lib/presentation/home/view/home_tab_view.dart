import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../../data/models/home_dashboard_model.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/shift_flow/clock_in_flow.dart';
import '../widgets/home_icon_box.dart';
import '../widgets/home_svg_icon.dart';
import '../widgets/shift_progress_ring.dart';
import '../widgets/start_shift_confirm_dialog.dart';

class HomeTabView extends StatefulWidget {
  const HomeTabView({super.key});

  @override
  State<HomeTabView> createState() => _HomeTabViewState();
}

class _HomeTabViewState extends State<HomeTabView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<HomeCubit>();
      if (cubit.state.dashboard == null) {
        cubit.loadDashboard();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state.isLoading && state.dashboard == null) {
          return const LoadingWidget(message: 'Loading dashboard...');
        }

        if (state.hasError && state.dashboard == null) {
          return ErrorDisplayWidget(
            message: state.errorMessage ?? 'Something went wrong',
            onRetry: () => context.read<HomeCubit>().loadDashboard(),
          );
        }

        final dashboard = state.dashboard;
        if (dashboard == null) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HomeHeader(
              caregiverName: dashboard.caregiverName,
              dateLabel: dashboard.dateLabel,
              activeShift: dashboard.activeShift,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => context.read<HomeCubit>().refresh(),
                color: AppColors.homePrimary,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 100),
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
                        child: _ScheduleCard(entry: entry),
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
      },
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.caregiverName,
    required this.dateLabel,
    required this.activeShift,
  });

  final String caregiverName;
  final String dateLabel;
  final ActiveShift activeShift;

  static const _headerHeight = 280.0;
  static const _cardOverlap = 100.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRect(
          child: ColoredBox(
            color: AppColors.homeHeader,
            child: SizedBox(
              height: _headerHeight,
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
                            child: Badge(
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
                          const SizedBox(width: 16),
                          HomeProfileAvatar(
                            asset: AppAssets.homeAvatar,
                            fallbackInitial: caregiverName.isNotEmpty
                                ? caregiverName[0].toUpperCase()
                                : 'M',
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
        _VerticalOverlap(
          overlap: _cardOverlap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: activeShift.isInProgress
                ? _InProgressShiftCard(shift: activeShift)
                : _ActiveShiftCard(shift: activeShift),
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
        final showRing = cardWidth >= 300;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 23, 16, 20),
          decoration: _cardDecoration(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    const SizedBox(height: 15),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _StartShiftButton(
                        onPressed: () =>
                            _onStartShiftPressed(context, shift),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      shift.timeRange,
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
      );
}

class _InProgressShiftCard extends StatelessWidget {
  const _InProgressShiftCard({required this.shift});

  final ActiveShift shift;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(23, 26, 23, 24),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visit in progress',
            style: context.responsiveStyle(
              AppTextStyles.labelSmall.copyWith(
                fontSize: 14,
                color: AppColors.homeMutedText,
                letterSpacing: -0.28,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            shift.clientName,
            style: context.responsiveStyle(AppTextStyles.homeCardTitle),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const HomeSvgIcon(
                asset: AppAssets.icHomeLocation,
                width: 12,
                height: 12,
                color: AppColors.homeDarkText,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  shift.gpsAddress,
                  style: context.responsiveStyle(AppTextStyles.homeCardSubtitle),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Text(
                  '00:00:00',
                  style: context.responsiveStyle(
                    AppTextStyles.homeShiftCountdownValue.copyWith(fontSize: 48),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  shift.startedAtLabel ?? 'Started · ${shift.serviceType}',
                  style: context.responsiveStyle(
                    AppTextStyles.homeCardSubtitle.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 53,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.homeDarkText,
                side: const BorderSide(color: AppColors.homeDialogDivider),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: context.responsiveStyle(
                  AppTextStyles.homeCardTitle.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
              child: const Text('End shift'),
            ),
          ),
        ],
      ),
    );
  }
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
  const _ScheduleCard({required this.entry});

  final ScheduleEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
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

/// Paints [child] shifted upward while reducing layout height by [overlap].
class _VerticalOverlap extends SingleChildRenderObjectWidget {
  const _VerticalOverlap({
    required this.overlap,
    required super.child,
  });

  final double overlap;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderVerticalOverlap(overlap);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderVerticalOverlap renderObject,
  ) {
    renderObject.overlap = overlap;
  }
}

class _RenderVerticalOverlap extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  _RenderVerticalOverlap(double overlap) : _overlap = overlap;

  double _overlap;

  double get overlap => _overlap;

  set overlap(double value) {
    if (_overlap == value) {
      return;
    }
    _overlap = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }

    child.layout(constraints, parentUsesSize: true);
    size = constraints.constrain(
      Size(
        child.size.width,
        math.max(0, child.size.height - _overlap),
      ),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) {
      return;
    }

    context.paintChild(child, offset - Offset(0, _overlap));
  }

  @override
  void applyPaintTransform(covariant RenderBox child, Matrix4 transform) {
    transform.translateByDouble(0, -_overlap, 0, 1);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) {
      return false;
    }

    return result.addWithPaintTransform(
      transform: Matrix4.translationValues(0, -_overlap, 0),
      position: position,
      hitTest: (BoxHitTestResult result, Offset transformed) {
        return child.hitTest(result, position: transformed);
      },
    );
  }
}
