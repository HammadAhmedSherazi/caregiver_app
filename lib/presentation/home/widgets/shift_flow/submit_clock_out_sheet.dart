import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../../../../data/models/home_dashboard_model.dart';
import '../home_svg_icon.dart';
import 'shift_clock_out_summary.dart';
import 'shift_completed_icon_badge.dart';
import 'shift_flow_sheet_scaffold.dart';

/// Shift completed summary sheet (Figma node `1:1338`).
class ShiftCompletedSummarySheet extends StatelessWidget {
  const ShiftCompletedSummarySheet({
    super.key,
    required this.clientName,
    required this.clockInTime,
    required this.clockOutTime,
    required this.totalHours,
  });

  final String clientName;
  final String clockInTime;
  final String clockOutTime;
  final String totalHours;

  static Future<bool> show(
    BuildContext context, {
    required ActiveShift shift,
  }) async {
    final summary = ShiftClockOutSummary.fromShift(shift);
    final result = await showShiftFlowSheet(
      context: context,
      child: ShiftCompletedSummarySheet(
        clientName: summary.clientName,
        clockInTime: summary.clockInTime,
        clockOutTime: summary.clockOutTime,
        totalHours: summary.totalHours,
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
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 26),
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
                    'Your visit was recorded and synced successfully.',
                    textAlign: TextAlign.center,
                    style: context.responsiveStyle(
                      AppTextStyles.homeCardSubtitle.copyWith(
                        fontSize: 14,
                        letterSpacing: -0.28,
                        color: AppColors.homeMutedText,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  _ShiftCompletedSummaryCard(
                    clientName: clientName,
                    clockInTime: clockInTime,
                    clockOutTime: clockOutTime,
                    totalHours: totalHours,
                  ),
                  const SizedBox(height: 32),
                  ShiftFlowPrimaryButton(
                    label: 'Back to home',
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

class _ShiftCompletedSummaryCard extends StatelessWidget {
  const _ShiftCompletedSummaryCard({
    required this.clientName,
    required this.clockInTime,
    required this.clockOutTime,
    required this.totalHours,
  });

  final String clientName;
  final String clockInTime;
  final String clockOutTime;
  final String totalHours;

  static const _labelColor = Color(0x9E0D1B2A);

  @override
  Widget build(BuildContext context) {
    final labelStyle = context.responsiveStyle(
      AppTextStyles.homeCardTitle.copyWith(
        fontWeight: FontWeight.w400,
        fontSize: 16,
        letterSpacing: -0.32,
        color: _labelColor,
      ),
    );
    final valueStyle = context.responsiveStyle(
      AppTextStyles.homeCardTitle.copyWith(
        fontSize: 16,
        letterSpacing: -0.8,
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.homeSheetDetailsBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.homeSheetDetailsBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.homeCardShadow,
            blurRadius: 26,
            offset: Offset(0, 24),
          ),
        ],
      ),
      child: Column(
        children: [
          _SummaryRow(
            label: 'Client',
            value: clientName,
            labelStyle: labelStyle,
            valueStyle: valueStyle,
          ),
          const SizedBox(height: 19),
          _SummaryRow(
            label: 'Clock-in',
            value: clockInTime,
            labelStyle: labelStyle,
            valueStyle: valueStyle,
          ),
          const SizedBox(height: 19),
          _SummaryRow(
            label: 'Clock-out',
            value: clockOutTime,
            labelStyle: labelStyle,
            valueStyle: valueStyle,
          ),
          const SizedBox(height: 19),
          _SummaryRow(
            label: 'Total hours',
            value: totalHours,
            labelStyle: labelStyle,
            valueStyle: valueStyle,
          ),
          const SizedBox(height: 19),
          Row(
            children: [
              Text('HHAExchange', style: labelStyle),
              const Spacer(),
              Container(
                height: 24,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.homeVerifiedBg,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const HomeSvgIcon(
                      asset: AppAssets.icHomeSyncedCheck,
                      width: 8,
                      height: 8,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Synced',
                      style: context.responsiveStyle(
                        AppTextStyles.labelSmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.homeVerifiedText,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: labelStyle),
        const Spacer(),
        Text(value, style: valueStyle),
      ],
    );
  }
}
