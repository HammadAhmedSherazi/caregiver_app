import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../../data/models/task_page_model.dart';
import '../../home/widgets/home_icon_box.dart';
import '../../home/widgets/home_svg_icon.dart';
import 'task_cards.dart';
import 'task_progress_ring.dart';

class ClientTasksProgressCard extends StatelessWidget {
  const ClientTasksProgressCard({
    super.key,
    required this.completedCount,
    required this.totalCount,
    required this.progressPercent,
    required this.progress,
  });

  final int completedCount;
  final int totalCount;
  final int progressPercent;
  final double progress;

  // Figma card `1:2819` (382×255) — ring + percent positions.
  static const _figmaCardWidth = 382.0;
  static const _figmaRingCenterX = 285.0;
  static const _figmaRingOuterSize = 203.0;
  static const _figmaRingInnerSize = 145.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 255,
      width: double.infinity,
      decoration: taskCardDecoration(),
      clipBehavior: Clip.none,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = constraints.maxWidth;
          final scale = cardWidth / _figmaCardWidth;
          final ringOuter = _figmaRingOuterSize * scale;
          final ringInner = _figmaRingInnerSize * scale;
          final ringCenterX = _figmaRingCenterX * scale;
          final ringLeft = ringCenterX - ringOuter / 2;
          final stroke = 17 * scale;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: ringLeft,
                top: 0,
                width: ringOuter,
                height: ringOuter,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    TaskProgressRing(
                      progress: progress,
                      size: ringInner,
                      strokeWidth: stroke,
                    ),
                    Text(
                      '$progressPercent%',
                      textAlign: TextAlign.center,
                      style: context.responsiveStyle(
                        AppFonts.base(
                          fontSize: 32 * scale,
                          fontWeight: AppFonts.black,
                          color: AppColors.homeDarkText,
                          height: 1.0,
                          letterSpacing: -0.64,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 24,
                top: 21,
                right: cardWidth - ringLeft + 8,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const HomeIconBox(
                      iconAsset: AppAssets.icHomeBanknote,
                      width: 48,
                      height: 47,
                      iconSize: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today's progress",
                            style: context.responsiveStyle(
                              AppFonts.base(
                                fontSize: 14,
                                fontWeight: AppFonts.regular,
                                color: AppColors.homeDarkText,
                                height: 1.43,
                                letterSpacing: -0.7,
                              ),
                            ),
                          ),
                          Text(
                            '$completedCount of $totalCount',
                            style: context.responsiveStyle(
                              AppFonts.base(
                                fontSize: 22,
                                fontWeight: AppFonts.extraBold,
                                color: AppColors.homeDarkText,
                                height: 1.43,
                                letterSpacing: -0.44,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 26,
                right: 26,
                top: 187,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: context.responsiveStyle(
                            AppFonts.base(
                              fontSize: 14,
                              fontWeight: AppFonts.regular,
                              color:
                                  AppColors.homeDarkText.withValues(alpha: 0.35),
                              height: 1.43,
                              letterSpacing: -0.28,
                            ),
                          ),
                        ),
                        Text(
                          '$progressPercent%',
                          style: context.responsiveStyle(
                            AppFonts.base(
                              fontSize: 14,
                              fontWeight: AppFonts.regular,
                              color:
                                  AppColors.homeDarkText.withValues(alpha: 0.35),
                              height: 1.43,
                              letterSpacing: -0.28,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ClientTaskLinearProgress(progress: progress),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ClientTaskLinearProgress extends StatelessWidget {
  const _ClientTaskLinearProgress({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final fillWidth = trackWidth * clamped;

        return SizedBox(
          height: 5,
          width: trackWidth,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 2,
                right: 0,
                top: 0,
                bottom: 0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: const ColoredBox(color: AppColors.homeProgressTrack),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: fillWidth,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          AppColors.homeProgressGradientEnd,
                          Color(0xFF76A3FF),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ClientCareTaskCard extends StatelessWidget {
  const ClientCareTaskCard({
    super.key,
    required this.task,
    required this.onToggle,
  });

  final ClientCareTask task;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 81,
          padding: const EdgeInsets.fromLTRB(20, 17, 20, 17),
          decoration: taskCardDecoration(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const HomeIconBox(
                iconAsset: AppAssets.icHomeBox,
                width: 48,
                height: 47,
                iconSize: 24,
              ),
              const SizedBox(width: 19),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      task.timeLabel,
                      style: context.responsiveStyle(
                        AppTextStyles.homeCardSubtitle.copyWith(
                          fontSize: 14,
                          letterSpacing: -0.28,
                          color: AppColors.homeDarkText.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    Text(
                      task.title,
                      style: context.responsiveStyle(
                        AppTextStyles.homeCardTitle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              HomeSvgIcon(
                asset: task.isCompleted
                    ? AppAssets.icTaskCheckCircleGreen
                    : AppAssets.icTaskCheckCircleEmpty,
                width: 24,
                height: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ClientComplianceTaskCard extends StatelessWidget {
  const ClientComplianceTaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 92,
          padding: const EdgeInsets.fromLTRB(17, 23, 17, 21),
          decoration: taskCardDecoration(),
          child: Row(
            children: [
              const HomeIconBox(
                iconAsset: AppAssets.icTaskForm,
                width: 48,
                height: 47,
                iconSize: 24,
              ),
              const SizedBox(width: 19),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: context.responsiveStyle(
                        AppTextStyles.homeCardTitle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: context.responsiveStyle(
                        AppTextStyles.homeCardSubtitle.copyWith(
                          fontSize: 14,
                          letterSpacing: -0.28,
                          color: AppColors.homeDarkText.withValues(alpha: 0.35),
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const HomeSvgIcon(
                asset: AppAssets.arrowForward,
                width: 24,
                height: 24,
                color: AppColors.homeDarkText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
