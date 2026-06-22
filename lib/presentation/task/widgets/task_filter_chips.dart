import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../../data/models/task_page_model.dart';

class TaskFilterChips extends StatelessWidget {
  const TaskFilterChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final TaskFilter selected;
  final ValueChanged<TaskFilter> onChanged;

  static const _labels = {
    TaskFilter.all: 'All',
    TaskFilter.compliance: 'Compliance',
    TaskFilter.documents: 'Documents',
    TaskFilter.visits: 'Visits',
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: TaskFilter.values.map((filter) {
          final isSelected = filter == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => onChanged(filter),
              child: Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.homePrimary
                      : AppColors.homePrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  _labels[filter]!,
                  style: context.responsiveStyle(
                    AppFonts.base(
                      fontSize: 10,
                      fontWeight:
                          isSelected ? AppFonts.medium : AppFonts.regular,
                      color: isSelected
                          ? Colors.white
                          : AppColors.homePrimary,
                      height: 2.4,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
