import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_fonts.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle _base({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: AppFonts.fontFamily,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static TextStyle get displayLarge => _base(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.12,
        letterSpacing: -0.25,
      );

  static TextStyle get displayMedium => _base(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        height: 1.16,
      );

  static TextStyle get displaySmall => _base(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.22,
      );

  static TextStyle get headlineLarge => _base(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.25,
      );

  static TextStyle get headlineMedium => _base(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.29,
      );

  static TextStyle get headlineSmall => _base(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.33,
      );

  static TextStyle get titleLarge => _base(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.27,
      );

  static TextStyle get titleMedium => _base(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.5,
        letterSpacing: 0.15,
      );

  static TextStyle get titleSmall => _base(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
        height: 1.43,
        letterSpacing: 0.1,
      );

  static TextStyle get bodyLarge => _base(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.5,
        letterSpacing: 0.5,
      );

  static TextStyle get bodyMedium => _base(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
        height: 1.43,
        letterSpacing: 0.25,
      );

  static TextStyle get bodySmall => _base(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.33,
        letterSpacing: 0.4,
      );

  static TextStyle get labelLarge => _base(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
        height: 1.43,
        letterSpacing: 0.1,
      );

  static TextStyle get labelMedium => _base(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.33,
        letterSpacing: 0.5,
      );

  static TextStyle get labelSmall => _base(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
        height: 1.45,
        letterSpacing: 0.5,
      );

  // Auth / onboarding (Figma)
  static TextStyle get onboardingHeadline => _base(
        fontSize: 45,
        fontWeight: FontWeight.w600,
        color: AppColors.authOnGradient,
        height: 1.09,
        letterSpacing: -2.25,
      );

  static TextStyle get onboardingSubtitle => _base(
        fontSize: 18,
        fontWeight: FontWeight.w400,
        color: AppColors.authOnGradient,
        height: 1.38,
        letterSpacing: -0.54,
      );

  static TextStyle get authButtonLabel => _base(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.authButtonText,
        height: 1.09,
        letterSpacing: -0.6,
      );

  static TextTheme get textTheme => TextTheme(
        displayLarge: displayLarge,
        displayMedium: displayMedium,
        displaySmall: displaySmall,
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        headlineSmall: headlineSmall,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        titleSmall: titleSmall,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        bodySmall: bodySmall,
        labelLarge: labelLarge,
        labelMedium: labelMedium,
        labelSmall: labelSmall,
      );
}
