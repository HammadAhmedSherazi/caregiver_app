import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';

/// Shared header for login & signup screens (Figma).
class AuthPageHeader extends StatelessWidget {
  const AuthPageHeader({
    super.key,
    this.topSpacing = 24,
  });

  final double topSpacing;

  static const title = 'Getting Started';
  static const subtitle = 'Let’s Signup for explore continues';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: topSpacing),
        Text(
          title,
          style: AppTextStyles.authTitle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: AppTextStyles.authSubtitle,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
