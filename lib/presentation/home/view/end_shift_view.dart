import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../../data/models/home_dashboard_model.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../../widgets/header_back_button.dart';
import '../widgets/home_svg_icon.dart';
import '../widgets/shift_flow/clock_out_flow.dart';
import '../widgets/vertical_overlap.dart';

class EndShiftView extends StatefulWidget {
  const EndShiftView({super.key, required this.shift});

  final ActiveShift shift;

  static const _cardOverlap = 100.0;

  @override
  State<EndShiftView> createState() => _EndShiftViewState();
}

class _EndShiftViewState extends State<EndShiftView> {
  late Set<int> _completedTaskIds;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _completedTaskIds = {
      for (final task in widget.shift.careTasks)
        if (task.isCompleted) task.id,
    };
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _toggleTask(int taskId) {
    setState(() {
      if (_completedTaskIds.contains(taskId)) {
        _completedTaskIds.remove(taskId);
      } else {
        _completedTaskIds.add(taskId);
      }
    });
    context.read<HomeCubit>().toggleCareTask(taskId);
  }

  Future<void> _onSubmitClockOut() async {
    final completed = await ClockOutFlow.run(
      context,
      shift: widget.shift,
    );
    if (!mounted) return;
    if (completed) {
      await context.read<HomeCubit>().endShift(
            visitId: widget.shift.visitId,
            notes: _notesController.text.trim(),
            scheduleId: widget.shift.scheduleId,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.homeBackground,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _EndShiftHeader(
                onBack: () => context.read<HomeCubit>().cancelEndShift(),
              ),
              VerticalOverlap(
                overlap: EndShiftView._cardOverlap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: _EndShiftTimeCard(
                    shiftStartedAt: widget.shift.shiftStartedAt,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              children: [
                if (widget.shift.careTasks.isNotEmpty) ...[
                  Text(
                    'Confirm completed tasks',
                    style: context.responsiveStyle(
                      AppTextStyles.homeCardTitle.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        letterSpacing: -0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),
                  _EndShiftTasksCard(
                    tasks: widget.shift.careTasks,
                    completedTaskIds: _completedTaskIds,
                    onToggle: _toggleTask,
                  ),
                  const SizedBox(height: 25),
                ],
                const _EndShiftNotesHeading(),
                const SizedBox(height: 13),
                _EndShiftNotesField(controller: _notesController),
                const SizedBox(height: 33),
                BlocBuilder<HomeCubit, HomeState>(
                  buildWhen: (previous, current) =>
                      previous.isClockingOut != current.isClockingOut,
                  builder: (context, state) {
                    return _EndShiftSubmitButton(
                      isLoading: state.isClockingOut,
                      onPressed:
                          state.isClockingOut ? null : _onSubmitClockOut,
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EndShiftHeader extends StatelessWidget {
  const _EndShiftHeader({required this.onBack});

  final VoidCallback onBack;

  static const _headerHeight = 209.0;

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
                  padding: const EdgeInsets.fromLTRB(19, 12, 18, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HeaderBackButton(
                        onTap: onBack,
                        titleStyle: AppTextStyles.homeWelcome,
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Text(
                          'End shift',
                          style: context.responsiveStyle(
                            AppTextStyles.homeCardTitle.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.authOnGradient,
                              letterSpacing: -1,
                            ),
                          ),
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

class _EndShiftTimeCard extends StatefulWidget {
  const _EndShiftTimeCard({this.shiftStartedAt});

  final DateTime? shiftStartedAt;

  @override
  State<_EndShiftTimeCard> createState() => _EndShiftTimeCardState();
}

class _EndShiftTimeCardState extends State<_EndShiftTimeCard> {
  late Timer _clockOutTimer;

  @override
  void initState() {
    super.initState();
    _clockOutTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockOutTimer.cancel();
    super.dispose();
  }

  String _formatClockTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final clockInTime = _formatClockTime(
      widget.shiftStartedAt ?? DateTime.now(),
    );
    final clockOutTime = _formatClockTime(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(top: 20),
      width: double.infinity,
      height: 180,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.homeCardShadow,
            blurRadius: 26,
            offset: Offset(0, 24),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOTAL TIME',
            style: context.responsiveStyle(
              AppTextStyles.homeCardTitle.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: AppColors.homeDarkText,
              ),
            ),
          ),
          const SizedBox(height: 4),
          _EndShiftTotalTimer(startedAt: widget.shiftStartedAt),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: _EndShiftClockButton(
                  label: 'Clock-in',
                  time: clockInTime,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _EndShiftClockButton(
                  label: 'Clock-out',
                  time: clockOutTime,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EndShiftTotalTimer extends StatefulWidget {
  const _EndShiftTotalTimer({this.startedAt});

  final DateTime? startedAt;

  @override
  State<_EndShiftTotalTimer> createState() => _EndShiftTotalTimerState();
}

class _EndShiftTotalTimerState extends State<_EndShiftTotalTimer> {
  late Timer _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateElapsed());
  }

  void _updateElapsed() {
    final startedAt = widget.startedAt;
    setState(() {
      _elapsed = startedAt != null
          ? DateTime.now().difference(startedAt)
          : Duration.zero;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _format(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _format(_elapsed),
      style: context.responsiveStyle(
        AppTextStyles.homeCardTitle.copyWith(
          fontSize: 22.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.35,
          color: AppColors.homeDarkText,
        ),
      ),
    );
  }
}

class _EndShiftClockButton extends StatelessWidget {
  const _EndShiftClockButton({
    required this.label,
    required this.time,
  });

  final String label;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.homePrimary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: context.responsiveStyle(
              AppTextStyles.labelSmall.copyWith(
                fontSize: 11.6,
                fontWeight: FontWeight.w400,
                color: AppColors.authOnGradient,
                height: 1.43,
              ),
            ),
          ),
          Text(
            time,
            style: context.responsiveStyle(
              AppTextStyles.labelSmall.copyWith(
                fontSize: 11.6,
                fontWeight: FontWeight.w500,
                color: AppColors.authOnGradient,
                height: 1.43,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EndShiftTasksCard extends StatelessWidget {
  const _EndShiftTasksCard({
    required this.tasks,
    required this.completedTaskIds,
    required this.onToggle,
  });

  final List<CareTaskItem> tasks;
  final Set<int> completedTaskIds;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 21, 20, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.homeCardShadow,
            blurRadius: 26,
            offset: Offset(0, 24),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < tasks.length; i++) ...[
            if (i > 0) const SizedBox(height: 18),
            _EndShiftTaskRow(
              label: tasks[i].label,
              isCompleted: completedTaskIds.contains(tasks[i].id),
              onTap: () => onToggle(tasks[i].id),
            ),
          ],
        ],
      ),
    );
  }
}

class _EndShiftTaskRow extends StatelessWidget {
  const _EndShiftTaskRow({
    required this.label,
    required this.isCompleted,
    required this.onTap,
  });

  final String label;
  final bool isCompleted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          HomeSvgIcon(
            asset: isCompleted
                ? AppAssets.icHomeTaskChecked
                : AppAssets.icHomeTaskUnchecked,
            width: 12,
            height: 12,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: context.responsiveStyle(
                AppTextStyles.homeCardSubtitle.copyWith(
                  fontSize: 14,
                  letterSpacing: -0.28,
                  color: AppColors.homeMutedText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EndShiftNotesHeading extends StatelessWidget {
  const _EndShiftNotesHeading();

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: context.responsiveStyle(
          AppTextStyles.homeCardTitle.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            letterSpacing: -0.8,
            color: AppColors.homeDarkText,
          ),
        ),
        children: [
          const TextSpan(text: 'Visit notes '),
          TextSpan(
            text: '(optional)',
            style: context.responsiveStyle(
              AppTextStyles.homeCardSubtitle.copyWith(
                fontWeight: FontWeight.w400,
                fontSize: 16,
                letterSpacing: -0.8,
                color: const Color(0x700D1B2A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EndShiftNotesField extends StatelessWidget {
  const _EndShiftNotesField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 119,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.homeCardShadow,
            blurRadius: 26,
            offset: Offset(0, 24),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: null,
        expands: true,
        textCapitalization: TextCapitalization.sentences,
        style: context.responsiveStyle(
          AppTextStyles.homeCardSubtitle.copyWith(
            fontSize: 14,
            letterSpacing: -0.28,
            color: AppColors.homeDarkText,
          ),
        ),
        decoration: InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: 'Client was in good spirits today. Ate full breakfast',
          hintStyle: context.responsiveStyle(
            AppTextStyles.homeCardSubtitle.copyWith(
              fontSize: 14,
              letterSpacing: -0.28,
              color: AppColors.homeMutedText,
            ),
          ),
        ),
      ),
    );
  }
}

class _EndShiftSubmitButton extends StatelessWidget {
  const _EndShiftSubmitButton({
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 325,
        height: 53,
        child: FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.homePrimary,
            foregroundColor: AppColors.authOnGradient,
            disabledBackgroundColor: AppColors.homePrimary,
            disabledForegroundColor: AppColors.authOnGradient,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: context.responsiveStyle(
              AppTextStyles.homeCardTitle.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.authOnGradient,
                letterSpacing: -0.54,
              ),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.authOnGradient,
                  ),
                )
              : const Text('Submit clock-out'),
        ),
      ),
    );
  }
}
