import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../../data/models/task_page_model.dart';
import '../../home/widgets/vertical_overlap.dart';
import '../../widgets/get_request_view.dart';
import '../../widgets/skeletons/api_tab_skeletons.dart';
import '../cubit/task_cubit.dart';
import '../widgets/compliance_history_widgets.dart';
import '../widgets/task_screen_header.dart';

class ComplianceHistoryView extends StatefulWidget {
  const ComplianceHistoryView({super.key});

  static const _headerHeight = 209.0;
  static const _summaryOverlap = 32.0;

  @override
  State<ComplianceHistoryView> createState() => _ComplianceHistoryViewState();
}

class _ComplianceHistoryViewState extends State<ComplianceHistoryView> {
  ComplianceHistoryPage? _history;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final history = await context.read<TaskCubit>().loadComplianceHistory();
      if (!mounted) return;
      setState(() {
        _history = history;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = _history;

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
                height: ComplianceHistoryView._headerHeight,
              ),
              if (history != null)
                VerticalOverlap(
                  overlap: ComplianceHistoryView._summaryOverlap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ComplianceHistorySummaryCard(summary: history.summary),
                  ),
                ),
            ],
          ),
          Expanded(
            child: GetRequestView(
              isLoading: _isLoading,
              hasError: _hasError,
              onRetry: _loadHistory,
              skeleton: const ComplianceHistorySkeleton(),
              child: history == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      onRefresh: _loadHistory,
                      color: AppColors.homePrimary,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
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
                          if (history.records.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 48),
                              child: Text(
                                'No compliance records yet',
                                textAlign: TextAlign.center,
                                style: context.responsiveStyle(
                                  AppTextStyles.homeCardSubtitle,
                                ),
                              ),
                            )
                          else
                            for (var i = 0; i < history.records.length; i++) ...[
                              ComplianceHistoryRecordCard(
                                record: history.records[i],
                              ),
                              if (i < history.records.length - 1)
                                const SizedBox(height: 15),
                            ],
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
