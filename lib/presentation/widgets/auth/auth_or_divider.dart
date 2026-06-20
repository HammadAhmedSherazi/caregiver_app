import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// OR divider used between primary login and social buttons.
class AuthOrDivider extends StatelessWidget {
  const AuthOrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        const Divider(
          color: AppColors.authDivider,
          thickness: 1,
          height: 1,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.authOnGradient,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            'OR',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.authDarkText,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.96,
            ),
          ),
        ),
      ],
    );
  }
}
