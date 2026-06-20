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
import '../widgets/home_svg_icon.dart';
import '../widgets/vertical_overlap.dart';

class ActiveShiftView extends StatelessWidget {
  const ActiveShiftView({super.key, required this.shift});

  final ActiveShift shift;

  static const _cardOverlap = 100.0;

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
              _ActiveShiftHeader(
                onBack: () => context.read<HomeCubit>().endShift(),
              ),
              VerticalOverlap(
                overlap: _cardOverlap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: _ActiveShiftVisitCard(shift: shift),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              children: [
                _ActiveShiftQuickActions(),
                const SizedBox(height: 12),
                _ActiveShiftCareTasksCard(tasks: shift.careTasks),
                const SizedBox(height: 24),
                _ActiveShiftEndButton(
                  onPressed: () =>
                      context.read<HomeCubit>().beginEndShift(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveShiftHeader extends StatelessWidget {
  const _ActiveShiftHeader({required this.onBack});

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
                    children: [
                      GestureDetector(
                        onTap: onBack,
                        child: const HomeSvgIcon(
                          asset: AppAssets.icHomeBackArrow,
                          width: 34,
                          height: 34,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Text(
                          'Active shift',
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
                      const _LiveBadge(),
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

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.homeVerifiedBg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HomeSvgIcon(
            asset: AppAssets.icHomeLiveDot,
            width: 4,
            height: 4,
          ),
          const SizedBox(width: 4),
          Text(
            'Live',
            style: context.responsiveStyle(
              AppTextStyles.labelSmall.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: AppColors.homeVerifiedText,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveShiftVisitCard extends StatelessWidget {
  const _ActiveShiftVisitCard({required this.shift});

  final ActiveShift shift;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        top: 20
      ),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(23, 26, 23, 24),
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
            'VISIT IN PROGRESS',
            style: context.responsiveStyle(
              AppTextStyles.homeCardTitle.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                color: AppColors.homeDarkText,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            shift.clientName,
            style: context.responsiveStyle(
              AppTextStyles.homeCardTitle.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const HomeSvgIcon(
                asset: AppAssets.icHomeLocation,
                width: 12,
                height: 12,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  shift.gpsAddress,
                  style: context.responsiveStyle(
                    AppTextStyles.homeCardSubtitle.copyWith(
                      fontSize: 14,
                      letterSpacing: -0.28,
                    ),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Center(
            child: Column(
              children: [
                _ActiveShiftTimer(startedAt: shift.shiftStartedAt),
                const SizedBox(height: 10),
                Text(
                  (shift.startedAtLabel ?? 'Started · ${shift.serviceType}')
                      .toUpperCase(),
                  style: context.responsiveStyle(
                    AppTextStyles.labelSmall.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.11,
                      color: AppColors.homeDarkText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _ActiveShiftStatusButton(
                  title: 'GPS',
                  status: 'Verified',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActiveShiftStatusButton(
                  title: 'HHAExchange',
                  status: 'Synced',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiveShiftTimer extends StatefulWidget {
  const _ActiveShiftTimer({this.startedAt});

  final DateTime? startedAt;

  @override
  State<_ActiveShiftTimer> createState() => _ActiveShiftTimerState();
}

class _ActiveShiftTimerState extends State<_ActiveShiftTimer> {
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
    final minutes =
        (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds =
        (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _format(_elapsed),
      style: context.responsiveStyle(
        AppTextStyles.homeShiftCountdownValue.copyWith(
          fontSize: 50,
          fontWeight: FontWeight.w600,
          letterSpacing: 3,
          color: AppColors.homeDarkText,
        ),
      ),
    );
  }
}

class _ActiveShiftStatusButton extends StatelessWidget {
  const _ActiveShiftStatusButton({
    required this.title,
    required this.status,
  });

  final String title;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62,
      decoration: BoxDecoration(
        color: AppColors.homePrimary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x3B000000), width: 0.2),
        boxShadow: const [
          BoxShadow(
            color: AppColors.homeCardShadow,
            blurRadius: 26,
            offset: Offset(0, 24),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: context.responsiveStyle(
              AppTextStyles.homeCardTitle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.authOnGradient,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const HomeSvgIcon(
                asset: AppAssets.icHomeVerifiedWhite,
                width: 10,
                height: 10,
              ),
              const SizedBox(width: 6),
              Text(
                status,
                style: context.responsiveStyle(
                  AppTextStyles.labelSmall.copyWith(
                    fontSize: 11.6,
                    fontWeight: FontWeight.w400,
                    color: AppColors.authOnGradient,
                    letterSpacing: -0.23,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiveShiftQuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActiveShiftQuickActionTile(
            label: 'Add note',
            iconAsset: AppAssets.icHomeAddNote,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActiveShiftQuickActionTile(
            label: 'Care plan',
            iconAsset: AppAssets.icHomeCarePlan,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActiveShiftQuickActionTile(
            label: 'Call office',
            iconAsset: AppAssets.icHomeCall,
            onTap: () {},
          ),
        ),
      ],
    );
  }
}

class _ActiveShiftQuickActionTile extends StatelessWidget {
  const _ActiveShiftQuickActionTile({
    required this.label,
    required this.iconAsset,
    required this.onTap,
  });

  final String label;
  final String iconAsset;
  final VoidCallback onTap;

  static const _cardBorder = Color(0x1A000000);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          height: 85,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _cardBorder),
            boxShadow: const [
              BoxShadow(
                color: AppColors.homeCardShadow,
                blurRadius: 26,
                offset: Offset(0, 24),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HomeSvgIcon(
                asset: iconAsset,
                width: 20,
                height: 20,
                color: AppColors.homeDarkText,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: context.responsiveStyle(
                  AppTextStyles.homeCardTitle.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.6,
                    color: AppColors.homeDarkText,
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

class _ActiveShiftCareTasksCard extends StatelessWidget {
  const _ActiveShiftCareTasksCard({required this.tasks});

  final List<String> tasks;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 25, 20, 24),
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
            'Care tasks',
            style: context.responsiveStyle(
              AppTextStyles.homeCardTitle.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < tasks.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            _ActiveShiftTaskRow(label: tasks[i]),
          ],
        ],
      ),
    );
  }
}

class _ActiveShiftTaskRow extends StatelessWidget {
  const _ActiveShiftTaskRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 5),
          child: HomeSvgIcon(
            asset: AppAssets.icHomeTaskBullet,
            width: 7,
            height: 7,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: context.responsiveStyle(
              AppTextStyles.homeCardSubtitle.copyWith(
                fontSize: 14,
                letterSpacing: -0.28,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveShiftEndButton extends StatelessWidget {
  const _ActiveShiftEndButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 325,
        height: 53,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.homePrimary,
            foregroundColor: AppColors.authOnGradient,
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
          child: const Text('End shift'),
        ),
      ),
    );
  }
}
