import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_fonts.dart';
import 'auth/auth_gradient_background.dart';

/// Branded full-screen splash shown while the app or a tab is loading.
class AppSplashView extends StatelessWidget {
  const AppSplashView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthGradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 3),
              Text(
                AppConstants.appName,
                textAlign: TextAlign.center,
                style: AppFonts.base(
                  fontSize: 28,
                  fontWeight: AppFonts.bold,
                  color: AppColors.authOnGradient,
                  letterSpacing: -0.8,
                ),
              ),
              if (message != null && message!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: AppFonts.base(
                    fontSize: 14,
                    fontWeight: AppFonts.regular,
                    color: AppColors.authOnGradient.withValues(alpha: 0.72),
                  ),
                ),
              ],
              const Spacer(flex: 4),
            ],
          ),
        ),
      ),
    );
  }
}
