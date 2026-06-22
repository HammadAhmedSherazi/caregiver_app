import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../home/widgets/vertical_overlap.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/header_back_button.dart';
import '../cubit/schedule_cubit.dart';
import '../cubit/schedule_state.dart';
import '../widgets/schedule_appointment_card.dart';
import '../widgets/schedule_calendar_strip.dart';
import '../widgets/schedule_view_toggle.dart';

class ScheduleTabView extends StatefulWidget {
  const ScheduleTabView({
    super.key,
    this.onBack,
  });

  final VoidCallback? onBack;

  @override
  State<ScheduleTabView> createState() => _ScheduleTabViewState();
}

class _ScheduleTabViewState extends State<ScheduleTabView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final cubit = context.read<ScheduleCubit>();
      if (cubit.state.data == null) {
        cubit.loadSchedule();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ScheduleCubit, ScheduleState>(
      builder: (context, state) {
        if (state.isLoading && state.data == null) {
          return const LoadingWidget(message: 'Loading schedule...');
        }

        if (state.hasError && state.data == null) {
          return ErrorDisplayWidget(
            message: state.errorMessage ?? 'Something went wrong',
            onRetry: () => context.read<ScheduleCubit>().loadSchedule(),
          );
        }

        final data = state.data;
        if (data == null) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ScheduleHeader(
                  onBack: widget.onBack,
                ),
                VerticalOverlap(
                  overlap: _ScheduleHeader.toggleOverlap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ScheduleViewToggle(
                      mode: data.viewMode,
                      onChanged: context.read<ScheduleCubit>().setViewMode,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => context.read<ScheduleCubit>().loadSchedule(
                      selectedDate: data.selectedDate,
                    ),
                color: AppColors.homePrimary,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                  children: [
                    ScheduleCalendarStrip(
                      monthLabel: data.monthLabel,
                      days: data.days,
                      onDaySelected: context.read<ScheduleCubit>().selectDate,
                    ),
                    const SizedBox(height: 24),
                    if (data.appointments.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 48),
                        child: Text(
                          'No appointments for this day',
                          textAlign: TextAlign.center,
                          style: context.responsiveStyle(
                            AppTextStyles.homeCardSubtitle,
                          ),
                        ),
                      )
                    else
                      ...data.appointments.map(
                        (appointment) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ScheduleAppointmentCard(
                            appointment: appointment,
                          ),
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

class _ScheduleHeader extends StatelessWidget {
  const _ScheduleHeader({this.onBack});

  final VoidCallback? onBack;

  static const _headerHeight = 190.0;
  static const toggleOverlap = 34.0;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: ColoredBox(
        color: AppColors.homeHeader,
        child: SizedBox(
          height: _headerHeight,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: 92,
                top: -222,
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
                  padding: const EdgeInsets.fromLTRB(19, 16, 24, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (onBack != null) ...[
                        HeaderBackButton(
                          onTap: onBack!,
                          titleStyle: AppTextStyles.scheduleScreenTitle,
                        ),
                        const SizedBox(width: 24),
                      ],
                      Text(
                        'Schedule',
                        style: context.responsiveStyle(
                          AppTextStyles.scheduleScreenTitle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
