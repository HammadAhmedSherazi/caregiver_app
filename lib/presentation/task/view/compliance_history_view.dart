import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../../data/models/task_page_model.dart';
import '../../home/widgets/vertical_overlap.dart';
import '../widgets/compliance_history_widgets.dart';
import '../widgets/task_screen_header.dart';

class ComplianceHistoryView extends StatelessWidget {
  const ComplianceHistoryView({
    super.key,
    required this.summary,
    required this.records,
  });

  final ComplianceHistorySummary summary;
  final List<ComplianceHistoryRecord> records;

  static const _headerHeight = 209.0;
  static const _summaryOverlap = 32.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TaskScreenHeader(
                title: 'Compliance History',
                subtitle: 'Last 12 months',
                onBack: () => Navigator.of(context).pop(),
                height: _headerHeight,
              ),
              VerticalOverlap(
                overlap: _summaryOverlap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ComplianceHistorySummaryCard(summary: summary),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 25, 24, 40),
              children: [
                Text(
                  'Record',
                  style: context.responsiveStyle(
                    AppTextStyles.homeCardTitle.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.homeDarkText,
                      letterSpacing: -0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < records.length; i++) ...[
                  ComplianceHistoryRecordCard(record: records[i]),
                  if (i < records.length - 1) const SizedBox(height: 15),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
