import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

enum AuthSocialButtonVariant { apple, google, facebook }

/// Generic social sign-in button for auth screens (Figma).
class AuthSocialButton extends StatelessWidget {
  const AuthSocialButton({
    super.key,
    required this.label,
    required this.iconAsset,
    required this.onPressed,
    this.variant = AuthSocialButtonVariant.google,
  });

  final String label;
  final String iconAsset;
  final VoidCallback? onPressed;
  final AuthSocialButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final style = _resolveStyle();

    return SizedBox(
      height: 60,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: style.backgroundColor,
          foregroundColor: style.textColor,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: style.border,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          children: [
            SvgPicture.asset(iconAsset, width: 24, height: 24),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.authSocialLabel.copyWith(
                  color: style.textColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }

  _SocialButtonStyle _resolveStyle() {
    return switch (variant) {
      AuthSocialButtonVariant.apple => const _SocialButtonStyle(
          backgroundColor: Colors.black,
          textColor: AppColors.authOnGradient,
          border: BorderSide.none,
        ),
      AuthSocialButtonVariant.google => const _SocialButtonStyle(
          backgroundColor: AppColors.authOnGradient,
          textColor: AppColors.authDarkText,
          border: BorderSide(color: AppColors.border),
        ),
      AuthSocialButtonVariant.facebook => const _SocialButtonStyle(
          backgroundColor: AppColors.authOnGradient,
          textColor: AppColors.authFacebookBlue,
          border: BorderSide(color: AppColors.authFacebookBlue),
        ),
    };
  }
}

class _SocialButtonStyle {
  const _SocialButtonStyle({
    required this.backgroundColor,
    required this.textColor,
    required this.border,
  });

  final Color backgroundColor;
  final Color textColor;
  final BorderSide border;
}
