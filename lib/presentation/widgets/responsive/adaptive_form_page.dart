import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_helper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../auth/auth_screen_shell.dart';
import 'adaptive_content.dart';
import 'responsive_layout.dart';

/// Generic auth/form page layout using the shared gradient background.
class AdaptiveFormPage extends StatelessWidget {
  const AdaptiveFormPage({
    super.key,
    required this.title,
    required this.subtitle,
    this.footer,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget? footer;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AuthScreenShell(
      child: ResponsiveLayout(
        mobile: _buildContent,
        tablet: _buildContent,
        expanded: _buildContent,
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return AdaptiveContent(
      scrollable: true,
      maxWidth: ResponsiveHelper.isTabletOrLarger(context) ? 430 : double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveHelper.value(
          context,
          compact: 24,
          medium: 32,
          expanded: 32,
        ),
        vertical: ResponsiveHelper.value(
          context,
          compact: 24,
          medium: 32,
          expanded: 40,
        ),
      ),
      child: _FormHeader(
        title: title,
        subtitle: subtitle,
        footer: footer,
        child: child,
      ),
    );
  }
}

class _FormHeader extends StatelessWidget {
  const _FormHeader({
    required this.title,
    required this.subtitle,
    this.footer,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget? footer;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.authOnGradient,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.authOnGradient.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 32),
        child,
        if (footer != null) ...[
          const SizedBox(height: 24),
          footer!,
        ],
      ],
    );
  }
}
