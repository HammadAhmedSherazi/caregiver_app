import 'package:flutter/material.dart';

/// Legacy colour tokens, re-pointed at the VELORA palette so screens that
/// were not rebuilt still match the redesign. New code should use
/// [VeloraColors] from `velora_theme.dart`.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF0F4A41);
  static const Color primaryLight = Color(0xFFDFEEE9);
  static const Color primaryDark = Color(0xFF0C3A34);

  // Auth / onboarding (Figma)
  static const Color authBackground = Color(0xFF0A2C28);
  static const Color authGlowTop = Color(0xFF37B199);
  static const Color authGlowBottom = Color(0xFF2E9C86);
  static const Color authButtonText = Color(0xFF0F4A41);
  static const Color authOnGradient = Color(0xFFFFFFFF);
  static const Color authFieldHint = Color(0xFFB6C3BE);
  static const Color authDarkText = Color(0xFF122420);
  static const Color authDivider = Color(0xFF16685B);
  static const Color authFacebookBlue = Color(0xFF0078FF);

  // Home dashboard (Figma)
  static const Color homeBackground = Color(0xFFF4F7F5);
  static const Color homeHeader = Color(0xFF0F4A41);
  static const Color payrollHeroCard = Color(0xFF0C3A34);
  static const Color homeAccent = Color(0xFF16685B);
  static const Color homePrimary = Color(0xFF16685B);
  static const Color homeIconTint = Color(0xFFDFEEE9);
  static const Color homeNavBar = Color(0xFF0C3A34);
  static const Color homeDarkText = Color(0xFF122420);
  static const Color homeMutedText = Color(0xFF54655F);
  static const Color homePriority = Color(0xFFA1362E);
  static const Color homeCardShadow = Color(0x140A1E1A);
  static const Color homeProgressTrack = Color(0xFFEEF3F0);
  static const Color homeProgressGradientEnd = Color(0xFFDFEEE9);
  static const Color homeDialogOverlay = Color(0x73091815);
  static const Color homeDialogShadow = Color(0x400D1B2A);
  static const Color homeDialogDivider = Color(0xFFE8EBF0);
  static const Color homeDialogCancel = Color(0xFF444444);
  static const Color homeSheetLabel = Color(0x9E0D1B2A);
  static const Color homeSheetDetailsBg = Color(0xFFDFEEE9);
  static const Color homeSheetDetailsBorder = Color(0x3316685B);
  static const Color homeVerifiedBg = Color(0x1A00BA00);
  static const Color homeVerifiedText = Color(0xDE00BA00);
  static const Color homeSyncBg = Color(0x2616685B);
  static const Color homeOfflineBannerBg = Color(0xFFFFEFC5);

  // Schedule tab (Figma)
  static const Color scheduleUpcomingBg = Color(0xFFDFEEE9);
  static const Color scheduleUpcomingText = Color(0xFF0F4A41);
  static const Color scheduleScheduledBg = Color(0xFFE4FBF0);
  static const Color scheduleScheduledText = Color(0xFF00BA00);
  static const Color scheduleTimelineLine = Color(0x330D1B2A);

  static const Color background = Color(0xFFF4F7F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color sidebar = Color(0xFF0C3A34);
  static const Color border = Color(0xFFE3EAE6);

  static const Color textPrimary = Color(0xFF122420);
  static const Color textSecondary = Color(0xFF54655F);
  static const Color textDisabled = Color(0xFFB6C3BE);
  static const Color textOnDark = Color(0xFFF8FAFC);

  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFDC2626);
  static const Color info = Color(0xFF0284C7);
}
