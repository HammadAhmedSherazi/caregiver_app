import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';

class TaskPrimaryButton extends StatelessWidget {
  const TaskPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: AppColors.homePrimary,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 53,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            label,
            style: AppFonts.base(
              fontSize: 18,
              fontWeight: AppFonts.bold,
              color: Colors.white,
              height: 1.09,
              letterSpacing: -0.54,
            ),
          ),
        ),
      ),
    );

    return expanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}
