import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../data/models/home_dashboard_model.dart';
import 'shift_clock_out_summary.dart';
import 'shift_completed_icon_badge.dart';
import 'shift_flow_sheet_scaffold.dart';

/// Shift completed preview sheet (Figma node `1:1169`).
class ShiftCompletedPreviewSheet extends StatelessWidget {
  const ShiftCompletedPreviewSheet({
    super.key,
    required this.totalHoursCompact,
    required this.clientName,
  });

  final String totalHoursCompact;
  final String clientName;

  static Future<bool> show(
    BuildContext context, {
    required ActiveShift shift,
  }) async {
    final summary = ShiftClockOutSummary.fromShift(shift);
    final result = await showShiftFlowSheet(
      context: context,
      child: ShiftCompletedPreviewSheet(
        totalHoursCompact: summary.totalHoursCompact,
        clientName: summary.clientName,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 65),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Shift completed',
                    textAlign: TextAlign.center,
                    style: context.responsiveStyle(
                      AppTextStyles.homeCardTitle.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.44,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$totalHoursCompact logged for $clientName. '
                    'Your hours have been verified and synced.',
                    textAlign: TextAlign.center,
                    style: context.responsiveStyle(
                      AppTextStyles.homeCardSubtitle.copyWith(
                        fontSize: 14,
                        letterSpacing: -0.28,
                        color: AppColors.homeMutedText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  ShiftFlowPrimaryButton(
                    label: 'View summary',
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
            ),
          ),
          const ShiftCompletedIconBadge(),
        ],
      ),
    );
  }
}
