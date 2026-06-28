import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/task_page_model.dart';
import '../../home/widgets/vertical_overlap.dart';
import '../../widgets/get_request_view.dart';
import '../../widgets/skeletons/api_tab_skeletons.dart';
import '../cubit/task_cubit.dart';
import '../widgets/payroll_paystub_card.dart';
import '../widgets/payroll_widgets.dart';
import '../widgets/task_screen_header.dart';
import 'payroll_detail_view.dart';

class PayrollView extends StatefulWidget {
  const PayrollView({super.key});

  static const _headerHeight = 209.0;
  static const _heroOverlap = 48.0;

  @override
  State<PayrollView> createState() => _PayrollViewState();
}

class _PayrollViewState extends State<PayrollView> {
  PayrollSummary? _payroll;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadPayroll();
  }

  Future<void> _loadPayroll() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final payroll = await context.read<TaskCubit>().loadPayrollSummary();
      if (!mounted) return;
      setState(() {
        _payroll = payroll;
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
    final payroll = _payroll;
    final subtitle = payroll != null
        ? '${payroll.year}'
        : '${DateTime.now().year}';

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
                title: 'Payroll',
                subtitle: subtitle,
                onBack: () => Navigator.of(context).pop(),
                height: PayrollView._headerHeight,
              ),
              if (payroll != null)
                VerticalOverlap(
                  overlap: PayrollView._heroOverlap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: PayrollHeroCard(
                      label: 'Year to date',
                      amount: payroll.yearToDateAmount,
                      subtitle: payroll.hoursLabel,
                      badges: [
                        payroll.quickbooksStatus,
                        payroll.gustoStatus,
                      ],
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: GetRequestView(
              isLoading: _isLoading,
              hasError: _hasError,
              onRetry: _loadPayroll,
              skeleton: const PayrollContentSkeleton(),
              child: payroll == null
                  ? const SizedBox.shrink()
                  : _PayrollContent(
                      payroll: payroll,
                      onRefresh: _loadPayroll,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PayrollContent extends StatelessWidget {
  const _PayrollContent({
    required this.payroll,
    required this.onRefresh,
  });

  final PayrollSummary payroll;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.homePrimary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        children: [
          const PayrollSectionTitle(title: 'Paystubs'),
          const SizedBox(height: 16),
          if (payroll.paystubs.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: Text(
                'No paystubs available',
                textAlign: TextAlign.center,
                style: AppTextStyles.homeCardSubtitle,
              ),
            )
          else
            for (final stub in payroll.paystubs) ...[
              PayrollPaystubCard(
                stub: stub,
                onTap: () async {
                  final detail = await context
                      .read<TaskCubit>()
                      .getPaystubDetail(stub.id);
                  if (!context.mounted) return;
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PayrollDetailView(detail: detail),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
            ],
        ],
      ),
    );
  }
}
