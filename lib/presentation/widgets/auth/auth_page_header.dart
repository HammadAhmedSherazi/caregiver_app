import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';

/// Shared header for auth screens (Figma).
class AuthPageHeader extends StatelessWidget {
  const AuthPageHeader({
    super.key,
    this.topSpacing = 24,
    this.title = defaultTitle,
    this.subtitle = defaultSubtitle,
  });

  final double topSpacing;
  final String title;
  final String subtitle;

  static const defaultTitle = 'Getting Started';
  static const defaultSubtitle = 'Let’s Signup for explore continues';

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
