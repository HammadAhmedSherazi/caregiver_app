import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/task_page_model.dart';
import '../../main/app_navigator.dart';
import '../../task/cubit/task_cubit.dart';
import '../../widgets/velora/velora.dart';

/// Paystub detail (`GET /pay/{id}`) with the PDF download (`GET /pay/{id}/stub`).
///
/// The PDF opens in the device's viewer, which provides Save / Share; the
/// design's in-app document viewer is not built.
class PaystubView extends StatefulWidget {
  const PaystubView({super.key, required this.paystubId});

  final String paystubId;

  @override
  State<PaystubView> createState() => _PaystubViewState();
}

class _PaystubViewState extends State<PaystubView> {
  late Future<PaystubDetail> _future;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _future = context.read<TaskCubit>().getPaystubDetail(widget.paystubId);
  }

  void _retry() {
    setState(() {
      _future = context.read<TaskCubit>().getPaystubDetail(widget.paystubId);
    });
  }

  Future<void> _openPdf(PaystubDetail detail) async {
    setState(() => _downloading = true);
    try {
      await context.read<TaskCubit>().downloadAndOpenPayStub(detail.id);
    } on PayStubDownloadException catch (error) {
      if (mounted) showVeloraToast(context, error.message);
    } catch (_) {
      if (mounted) showVeloraToast(context, 'Unable to open the paystub PDF.');
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return VeloraScaffold(
      body: FutureBuilder<PaystubDetail>(
        future: _future,
        builder: (context, snapshot) {
          final detail = snapshot.data;
          void back() => Navigator.of(context).pop();

          if (snapshot.hasError) {
            return VeloraPage(
              header: VeloraHeader(title: 'Paystub', onBack: back),
              children: [
                VeloraErrorState(message: 'We couldn\'t load this paystub.', onRetry: _retry),
              ],
            );
          }
          if (detail == null) {
            return VeloraPage(
              header: VeloraHeader(title: 'Paystub', onBack: back),
              children: const [VeloraLoadingState()],
            );
          }

          final taxes = <(String, String)>[
            if (detail.federalTax != null) ('Federal income tax', detail.federalTax!),
            if (detail.stateTax != null) ('State income tax', detail.stateTax!),
            if (detail.fica != null) ('Social Security & Medicare', detail.fica!),
          ];

          return VeloraPage(
            header: VeloraHeader(
              title: 'Paystub',
              subtitle: detail.payDate.isEmpty ? detail.status : 'Paid ${detail.payDate}',
              onBack: back,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              bottom: Padding(
                padding: const EdgeInsets.only(top: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      detail.netPay != null ? 'NET PAY' : 'GROSS PAY',
                      style: VeloraText.body(12,
                          weight: FontWeight.w700, color: VeloraColors.onHeaderMuted, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        detail.netPay ?? detail.grossPay,
                        style: VeloraText.display(42, color: Colors.white, letterSpacing: -0.03),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(detail.status,
                        style: VeloraText.body(13, color: VeloraColors.onHeaderMuted)),
                  ],
                ),
              ),
            ),
            children: [
              VeloraCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  children: [
                    KeyValueRow(showDivider: false, label: 'Work period', value: detail.periodLabel),
                    if (detail.program.isNotEmpty) KeyValueRow(label: 'Program', value: detail.program),
                  ],
                ),
              ),
              VeloraCard(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SectionCaption('Earnings', padding: EdgeInsets.only(top: 8, bottom: 2)),
                    KeyValueRow(showDivider: false, label: 'Hours worked', value: detail.hoursWorked),
                    KeyValueRow(label: 'Hourly rate', value: detail.rate),
                    KeyValueRow(label: 'Gross pay', value: detail.grossPay, emphasize: true),
                  ],
                ),
              ),
              if (taxes.isNotEmpty)
                VeloraCard(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionCaption('Taxes withheld', padding: EdgeInsets.only(top: 8, bottom: 2)),
                      for (var i = 0; i < taxes.length; i++)
                        KeyValueRow(showDivider: i > 0, label: taxes[i].$1, value: taxes[i].$2),
                      if (detail.estimatedBreakdown)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 8),
                          child: Text(
                            'Estimated breakdown. Your PDF paystub has the exact amounts.',
                            style: VeloraText.body(12, color: VeloraColors.muted),
                          ),
                        ),
                    ],
                  ),
                ),
              if (detail.visitSummary.isNotEmpty)
                VeloraCard(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionCaption('Visits', padding: EdgeInsets.only(top: 8, bottom: 2)),
                      for (var i = 0; i < detail.visitSummary.length; i++)
                        KeyValueRow(
                          showDivider: i > 0,
                          label: detail.visitSummary[i].key,
                          value: detail.visitSummary[i].value,
                        ),
                    ],
                  ),
                ),
              if (detail.stubAvailable)
                VeloraButton(
                  label: 'View or save PDF',
                  icon: VeloraIcons.download,
                  variant: VeloraButtonVariant.ghost,
                  isLoading: _downloading,
                  onPressed: () => _openPdf(detail),
                ),
              Center(
                child: VeloraTextLink(
                  label: 'Question about this paystub? Message the office',
                  size: 13.5,
                  onTap: () => AppNavigator.openInbox(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
