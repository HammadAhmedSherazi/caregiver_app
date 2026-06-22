import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/schedule_page_model.dart';

class ScheduleStatusBadge extends StatelessWidget {
  const ScheduleStatusBadge({
    super.key,
    required this.status,
  });

  final ScheduleAppointmentStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, textColor, label) = switch (status) {
      ScheduleAppointmentStatus.upcoming => (
          AppColors.scheduleUpcomingBg,
          AppColors.scheduleUpcomingText,
          'Upcoming',
        ),
      ScheduleAppointmentStatus.scheduled => (
          AppColors.scheduleScheduledBg,
          AppColors.scheduleScheduledText,
          'Schedule',
        ),
    };

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(100),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTextStyles.scheduleBadge.copyWith(color: textColor),
      ),
    );
  }
}
