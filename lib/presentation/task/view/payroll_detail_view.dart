import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../../data/models/task_page_model.dart';
import '../../home/widgets/vertical_overlap.dart';
import '../cubit/task_cubit.dart';
import '../widgets/payroll_widgets.dart';
import '../widgets/task_primary_button.dart';
import '../widgets/task_screen_header.dart';

class PayrollDetailView extends StatefulWidget {
  const PayrollDetailView({
    super.key,
    required this.detail,
  });

  final PaystubDetail detail;

  static const _headerHeight = 209.0;
  static const _heroOverlap = 48.0;

  @override
  State<PayrollDetailView> createState() => _PayrollDetailViewState();
}

class _PayrollDetailViewState extends State<PayrollDetailView> {
  bool _isDownloading = false;

  Future<void> _downloadPdf() async {
    if (!widget.detail.stubAvailable || _isDownloading) return;

    setState(() => _isDownloading = true);

    try {
      await context.read<TaskCubit>().downloadAndOpenPayStub(widget.detail.id);
    } on PayStubDownloadException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(error.message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Unable to download pay stub. Please try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;

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
                subtitle: detail.periodLabel,
                onBack: () => Navigator.of(context).pop(),
                height: PayrollDetailView._headerHeight,
              ),
              VerticalOverlap(
                overlap: PayrollDetailView._heroOverlap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: PayrollHeroCard(
                    label: 'Gross pay',
                    amount: detail.grossPay,
                    height: 141,
                    footer: detail.isPaid
                        ? const PayrollPaidBadge()
                        : null,
                    badges: [detail.status, detail.program],
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
              children: [
                PayrollInfoCard(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  child: Column(
                    children: [
                      PayrollDetailRow(
                        label: 'Pay period',
                        value: detail.periodLabel,
                      ),
                      const SizedBox(height: 20),
                      PayrollDetailRow(
                        label: 'Pay date',
                        value: detail.payDate,
                      ),
                      const SizedBox(height: 20),
                      PayrollDetailRow(
                        label: 'Hours worked',
                        value: detail.hoursWorked,
                      ),
                      const SizedBox(height: 20),
                      PayrollDetailRow(
                        label: 'Rate',
                        value: detail.rate,
                      ),
                      const SizedBox(height: 20),
                      PayrollDetailRow(
                        label: 'Status',
                        value: detail.status,
                      ),
                      const SizedBox(height: 20),
                      PayrollDetailRow(
                        label: 'Program',
                        value: detail.program,
                      ),
                    ],
                  ),
                ),
                if (detail.visitSummary.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const PayrollSectionTitle(title: 'Visit summary'),
                  const SizedBox(height: 16),
                  PayrollInfoCard(
                    padding: const EdgeInsets.fromLTRB(16, 23, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < detail.visitSummary.length; i++) ...[
                          if (i > 0) const SizedBox(height: 15),
                          PayrollDetailRow(
                            label: detail.visitSummary[i].key,
                            value: detail.visitSummary[i].value,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                if (detail.netPay != null) ...[
                  const SizedBox(height: 24),
                  PayrollSectionTitle(
                    title: detail.estimatedBreakdown
                        ? 'Estimated breakdown'
                        : 'Pay breakdown',
                  ),
                  const SizedBox(height: 16),
                  PayrollInfoCard(
                    padding: const EdgeInsets.fromLTRB(16, 23, 16, 20),
                    child: Column(
                      children: [
                        PayrollDetailRow(
                          label: 'Gross pay',
                          value: detail.grossPay,
                        ),
                        if (detail.federalTax != null) ...[
                          const SizedBox(height: 20),
                          PayrollDetailRow(
                            label: 'Federal tax',
                            value: detail.federalTax!,
                          ),
                        ],
                        if (detail.stateTax != null) ...[
                          const SizedBox(height: 20),
                          PayrollDetailRow(
                            label: 'State tax',
                            value: detail.stateTax!,
                          ),
                        ],
                        if (detail.fica != null) ...[
                          const SizedBox(height: 20),
                          PayrollDetailRow(
                            label: 'FICA',
                            value: detail.fica!,
                          ),
                        ],
                        const SizedBox(height: 20),
                        PayrollDetailRow(
                          label: 'Net pay',
                          value: detail.netPay!,
                        ),
                      ],
                    ),
                  ),
                  if (detail.estimatedBreakdown) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Tax amounts are estimated. Authoritative net pay comes from your payroll provider.',
                      textAlign: TextAlign.center,
                      style: context.responsiveStyle(
                        AppTextStyles.homeCardSubtitle,
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 32),
                TaskPrimaryButton(
                  label: _isDownloading ? 'Downloading...' : 'Download PDF',
                  onPressed: detail.stubAvailable && !_isDownloading
                      ? _downloadPdf
                      : null,
                ),
                if (!detail.stubAvailable) ...[
                  const SizedBox(height: 12),
                  Text(
                    'PDF stub is not available for this pay period yet.',
                    textAlign: TextAlign.center,
                    style: context.responsiveStyle(
                      AppTextStyles.homeCardSubtitle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
