import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'auth_forward_icon.dart';

/// Generic white CTA button for auth/onboarding screens.
///
/// Layout: [label] on the left, optional trailing icon on the right.
/// Reuse across onboarding, login, signup, etc.
class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.showTrailingIcon = true,
    this.trailingIcon,
    this.height = 66,
    this.borderRadius = 18,
    this.horizontalPadding = 32,
    this.labelStyle,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool showTrailingIcon;
  final Widget? trailingIcon;
  final double height;
  final double borderRadius;
  final double horizontalPadding;
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.authOnGradient,
          foregroundColor: AppColors.authButtonText,
          disabledBackgroundColor:
              AppColors.authOnGradient.withValues(alpha: 0.7),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 10,
          ),
        ),
        child: isLoading ? _buildLoader() : _buildContent(),
      ),
    );
  }

  Widget _buildLoader() {
    return const SizedBox(
      height: 22,
      width: 22,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: AppColors.authButtonText,
      ),
    );
  }

  Widget _buildContent() {
    final textStyle = labelStyle ?? AppTextStyles.authButtonLabel;

    if (!showTrailingIcon) {
      return Text(label, style: textStyle);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textStyle),
        trailingIcon ?? const AuthForwardIcon(),
      ],
    );
  }
}
