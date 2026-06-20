import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions/context_extensions.dart';

/// Figma node `1:839` — confirm clock-in dialog over home screen.
class StartShiftConfirmDialog extends StatelessWidget {
  const StartShiftConfirmDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: AppColors.homeDialogOverlay,
      builder: (_) => const StartShiftConfirmDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: AppColors.homeDialogShadow,
              blurRadius: 26,
              offset: Offset(0, 24),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirm Action',
              style: context.responsiveStyle(
                AppTextStyles.homeConfirmDialogTitle,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to clock IN?',
              style: context.responsiveStyle(
                AppTextStyles.homeCardSubtitle,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 53,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.homePrimary,
                  foregroundColor: AppColors.authOnGradient,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: context.responsiveStyle(
                    AppTextStyles.authLoginButtonLabel.copyWith(
                      color: AppColors.authOnGradient,
                      height: 1.09,
                    ),
                  ),
                ),
                child: const Text('Confirm Clock In'),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.homeDialogDivider,
            ),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.homeDialogCancel,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: context.responsiveStyle(
                    AppTextStyles.homeDialogCancel,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
