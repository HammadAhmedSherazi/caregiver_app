import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../../data/models/task_page_model.dart';

class TaskStatusBadge extends StatelessWidget {
  const TaskStatusBadge({super.key, required this.status});

  final TaskItemStatus status;

  @override
  Widget build(BuildContext context) {
    final (bg, text, label) = switch (status) {
      TaskItemStatus.pending => (
          const Color(0x2BFABA52),
          const Color(0xFFFFA81A),
          'Pending',
        ),
      TaskItemStatus.overdue => (
          AppColors.homePriority.withValues(alpha: 0.1),
          AppColors.homePriority,
          'Overdue',
        ),
      TaskItemStatus.submitted => (
          AppColors.scheduleScheduledBg,
          AppColors.scheduleScheduledText,
          'Submitted',
        ),
      TaskItemStatus.paid => (
          AppColors.scheduleScheduledBg,
          AppColors.scheduleScheduledText,
          'Paid',
        ),
    };

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: context.responsiveStyle(
          AppFonts.base(
            fontSize: 10,
            fontWeight: AppFonts.medium,
            color: text,
            height: 2.4,
          ),
        ),
      ),
    );
  }
}
