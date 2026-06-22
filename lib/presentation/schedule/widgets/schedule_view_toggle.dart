import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/schedule_page_model.dart';

class ScheduleViewToggle extends StatelessWidget {
  const ScheduleViewToggle({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final ScheduleViewMode mode;
  final ValueChanged<ScheduleViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.authOnGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.homeCardShadow,
            blurRadius: 26,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _ToggleSegment(
              label: 'Day',
              isSelected: mode == ScheduleViewMode.day,
              onTap: () => onChanged(ScheduleViewMode.day),
            ),
          ),
          Expanded(
            child: _ToggleSegment(
              label: 'Week',
              isSelected: mode == ScheduleViewMode.week,
              onTap: () => onChanged(ScheduleViewMode.week),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  const _ToggleSegment({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.homePrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: isSelected
              ? AppTextStyles.scheduleToggleSelected
              : AppTextStyles.scheduleToggleUnselected,
        ),
      ),
    );
  }
}
