import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../home/widgets/home_svg_icon.dart';
import 'task_primary_button.dart';

class TaskSuccessSheet extends StatelessWidget {
  const TaskSuccessSheet({
    super.key,
    required this.title,
    required this.message,
    required this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.showSummary = false,
    this.summaryRows = const [],
  });

  final String title;
  final String message;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final bool showSummary;
  final List<MapEntry<String, String>> summaryRows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: const Offset(0, -85),
            child: Container(
              width: 99,
              height: 99,
              decoration: BoxDecoration(
                color: AppColors.homePrimary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: HomeSvgIcon(
                  asset: AppAssets.icTaskTickCircle,
                  width: 70,
                  height: 70,
                ),
              ),
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.responsiveStyle(
              AppTextStyles.homeAddress.copyWith(fontSize: 22),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: context.responsiveStyle(AppTextStyles.homeCardSubtitle),
          ),
          if (showSummary && summaryRows.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.homeIconTint,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.homePrimary.withValues(alpha: 0.14),
                ),
              ),
              child: Column(
                children: summaryRows
                    .map(
                      (row) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                row.key,
                                style: context.responsiveStyle(
                                  AppTextStyles.homeCardTitle.copyWith(
                                    color: AppColors.homeMutedText,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                            Text(
                              row.value,
                              style: context.responsiveStyle(
                                AppTextStyles.homeCardTitle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 32),
          TaskPrimaryButton(label: primaryLabel, onPressed: onPrimary),
          if (secondaryLabel != null) ...[
            const SizedBox(height: 20),
            const Divider(color: AppColors.homeDialogDivider),
            TextButton(
              onPressed: onSecondary,
              child: Text(
                secondaryLabel!,
                style: context.responsiveStyle(
                  AppTextStyles.homeCardSubtitle.copyWith(
                    color: AppColors.homeDialogCancel,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
