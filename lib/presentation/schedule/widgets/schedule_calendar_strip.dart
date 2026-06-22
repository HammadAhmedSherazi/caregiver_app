import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/schedule_page_model.dart';

class ScheduleCalendarStrip extends StatelessWidget {
  const ScheduleCalendarStrip({
    super.key,
    required this.monthLabel,
    required this.days,
    required this.onDaySelected,
  });

  final String monthLabel;
  final List<ScheduleDay> days;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          monthLabel,
          style: AppTextStyles.scheduleMonthLabel,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 92,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final day = days[index];
              return ScheduleDayCard(
                day: day,
                onTap: () => onDaySelected(day.date),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ScheduleDayCard extends StatelessWidget {
  const ScheduleDayCard({
    super.key,
    required this.day,
    required this.onTap,
  });

  final ScheduleDay day;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = day.isSelected;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 81,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.homePrimary : AppColors.authOnGradient,
          borderRadius: BorderRadius.circular(isSelected ? 14 : 20),
          boxShadow: isSelected
              ? null
              : [
                  BoxShadow(
                    color: AppColors.homeCardShadow,
                    blurRadius: 26,
                    offset: const Offset(0, 24),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              day.dayLabel,
              style: AppTextStyles.scheduleDayLabel.copyWith(
                color: isSelected
                    ? AppColors.authOnGradient
                    : AppColors.homeDarkText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${day.dayNumber}',
              style: AppTextStyles.scheduleDayNumber.copyWith(
                color: isSelected
                    ? AppColors.authOnGradient
                    : AppColors.homeMutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
