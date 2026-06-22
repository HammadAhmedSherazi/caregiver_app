import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../../data/models/task_page_model.dart';
import '../../home/widgets/home_icon_box.dart';
import '../../home/widgets/home_svg_icon.dart';
import '../../widgets/user_avatar.dart';
import 'task_primary_button.dart';
import 'task_status_badge.dart';

BoxDecoration taskCardDecoration({double radius = 20}) {
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

class TaskActionCard extends StatelessWidget {
  const TaskActionCard({
    super.key,
    required this.task,
    required this.iconAsset,
    this.onAction,
  });

  final TaskItem task;
  final String iconAsset;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
      decoration: taskCardDecoration(),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeIconBox(
                iconAsset: iconAsset,
                boxColor: task.status == TaskItemStatus.overdue &&
                        task.type == TaskItemType.visitSignature
                    ? AppColors.homePriority.withValues(alpha: 0.1)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: context.responsiveStyle(AppTextStyles.homeCardTitle),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.subtitle,
                      style: context.responsiveStyle(
                        AppTextStyles.homeCardSubtitle,
                      ),
                    ),
                  ],
                ),
              ),
              TaskStatusBadge(status: task.status),
            ],
          ),
          const SizedBox(height: 16),
          TaskPrimaryButton(
            label: task.actionLabel,
            onPressed: onAction,
          ),
        ],
      ),
    );
  }
}

class TaskVisitCard extends StatelessWidget {
  const TaskVisitCard({
    super.key,
    required this.task,
    this.onTap,
  });

  final TaskItem task;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 92,
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
        decoration: taskCardDecoration(),
        child: Row(
          children: [
            if (task.avatarUrl != null)
              UserAvatar(
                imageUrl: task.avatarUrl,
                name: task.clientName ?? task.title,
                size: 48,
              )
            else
              HomeIconBox(
                iconAsset: AppAssets.icHomeUserOutline,
                width: 48,
                height: 47,
              ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: context.responsiveStyle(
                            AppTextStyles.homeCardTitle,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (task.isHighPriority) ...[
                        const SizedBox(width: 8),
                        TaskStatusBadge(status: TaskItemStatus.overdue),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    task.subtitle,
                    style: context.responsiveStyle(
                      AppTextStyles.homeCardSubtitle,
                    ),
                  ),
                ],
              ),
            ),
            const HomeSvgIcon(
              asset: AppAssets.arrowForward,
              width: 24,
              height: 24,
              color: AppColors.authButtonText,
            ),
          ],
        ),
      ),
    );
  }
}

class TaskYesNoToggle extends StatelessWidget {
  const TaskYesNoToggle({
    super.key,
    required this.selectedYes,
    required this.onChanged,
  });

  final bool? selectedYes;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ToggleButton(
            label: 'Yes',
            selected: selectedYes == true,
            onTap: () => onChanged(true),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ToggleButton(
            label: 'No',
            selected: selectedYes == false,
            onTap: () => onChanged(false),
          ),
        ),
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 53,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.homePrimary : AppColors.homeIconTint,
          borderRadius: BorderRadius.circular(selected ? 14 : 13),
        ),
        child: Text(
          label,
          style: context.responsiveStyle(
            AppTextStyles.homeCardTitle.copyWith(
              fontSize: 18,
              color: selected ? Colors.white : AppColors.homeMutedText,
            ),
          ),
        ),
      ),
    );
  }
}
