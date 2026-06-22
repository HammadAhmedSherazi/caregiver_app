import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../../data/models/task_page_model.dart';
import '../../home/widgets/home_icon_box.dart';
import '../../home/widgets/home_svg_icon.dart';

BoxDecoration complianceSummaryCardDecoration() {
  return BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
    boxShadow: const [
      BoxShadow(
        color: AppColors.homeCardShadow,
        blurRadius: 26,
        offset: Offset(0, 24),
      ),
    ],
  );
}

class ComplianceHistorySummaryCard extends StatelessWidget {
  const ComplianceHistorySummaryCard({
    super.key,
    required this.summary,
  });

  final ComplianceHistorySummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 102,
      width: double.infinity,
      decoration: complianceSummaryCardDecoration(),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _SummaryStat(
            value: '${summary.submittedCount}',
            label: 'Submitted',
            color: AppColors.scheduleScheduledText,
          ),
          const SizedBox(width: 38),
          const _SummaryDivider(),
          const SizedBox(width: 38),
          _SummaryStat(
            value: summary.overdueCount.toString().padLeft(2, '0'),
            label: 'Overdue',
            color: AppColors.homePriority,
          ),
          const SizedBox(width: 38),
          const _SummaryDivider(),
          const SizedBox(width: 38),
          _SummaryStat(
            value: '${summary.onTimePercent}%',
            label: 'On time %',
            color: AppColors.homePrimary,
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: context.responsiveStyle(
            AppFonts.base(
              fontSize: 18,
              fontWeight: AppFonts.bold,
              color: color,
              height: 1.43,
              letterSpacing: -0.9,
            ),
          ),
        ),
        Text(
          label,
          style: context.responsiveStyle(
            AppFonts.base(
              fontSize: 12,
              fontWeight: AppFonts.medium,
              color: Colors.black,
              height: 1.43,
              letterSpacing: -0.6,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 46,
      color: Colors.black.withValues(alpha: 0.1),
    );
  }
}

class ComplianceHistoryRecordCard extends StatelessWidget {
  const ComplianceHistoryRecordCard({
    super.key,
    required this.record,
    this.onTap,
  });

  final ComplianceHistoryRecord record;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 92,
          padding: const EdgeInsets.fromLTRB(17, 23, 17, 21),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: AppColors.homeCardShadow,
                blurRadius: 26,
                offset: Offset(0, 24),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HomeIconBox(
                iconAsset: AppAssets.icTaskForm,
                width: 48,
                height: 47,
                iconSize: 20,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.periodLabel,
                        style: context.responsiveStyle(
                          AppTextStyles.homeCardTitle.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.8,
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        record.submittedLabel,
                        style: context.responsiveStyle(
                          AppTextStyles.homeCardSubtitle.copyWith(
                            fontSize: 14,
                            letterSpacing: -0.28,
                            color: AppColors.homeDarkText.withValues(alpha: 0.35),
                          ),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 11),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ComplianceStatusBadge(isSubmitted: record.isSubmitted),
                    if (record.hasAttachment) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 25,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.homeIconTint,
                          borderRadius: BorderRadius.circular(9000),
                        ),
                        child: const HomeSvgIcon(
                          asset: AppAssets.icTaskUpload,
                          width: 11,
                          height: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComplianceStatusBadge extends StatelessWidget {
  const _ComplianceStatusBadge({required this.isSubmitted});

  final bool isSubmitted;

  @override
  Widget build(BuildContext context) {
    final color = isSubmitted
        ? AppColors.scheduleScheduledText
        : AppColors.homePriority;
    final label = isSubmitted ? 'Submitted' : 'Overdue';

    return Container(
      height: 24,
      width: 82,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: context.responsiveStyle(
          AppFonts.base(
            fontSize: 10,
            fontWeight: AppFonts.medium,
            color: color,
            height: 2.4,
          ),
        ),
      ),
    );
  }
}
