import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';

/// Shared footer link for auth screens.
class AuthPageFooter extends StatelessWidget {
  const AuthPageFooter({
    super.key,
    required this.title,
    required this.actionLabel,
    required this.onActionTap,
    this.topSpacing = 65,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onActionTap;
  final double topSpacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: topSpacing),
        Text(
          title,
          style: AppTextStyles.authFooterTitle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onActionTap,
          child: Text(
            actionLabel,
            style: AppTextStyles.authFooterLink,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
