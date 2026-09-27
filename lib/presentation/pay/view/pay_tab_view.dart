import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/task_page_model.dart';
import '../../main/app_navigator.dart';
import '../../main/widgets/main_bottom_nav_bar.dart';
import '../../task/cubit/task_cubit.dart';
import '../../task/cubit/task_state.dart';
import '../../widgets/velora/velora.dart';
import '../../../core/i18n/tr.dart';

/// Pay tab: year-to-date and paystubs (`GET /earnings/summary`, `GET /pay`).
///
/// The design's "Next payday" card needs a payday / sign-off deadline API
/// that doesn't exist yet (API REQUIRED), so it is replaced by year-to-date.
class PayTabView extends StatelessWidget {
  const PayTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskCubit, TaskState>(
      builder: (context, state) {
        final payroll = state.data?.payroll;
        return VeloraPage(
          underTabBar: true,
          onRefresh: () => context.read<TaskCubit>().loadTasks(),
          header: VeloraHeader(
            title: tr('Pay'),
            subtitle: tr('Your paystubs and earnings'),
          ),
          children: [
            if (state.hasError && payroll == null)
              VeloraErrorState(
                message: tr('We couldn\'t load your pay.'),
                onRetry: () => context.read<TaskCubit>().loadTasks(),
              )
            else if (payroll == null)
              VeloraLoadingState(message: tr('Loading your pay…'))
            else ...[
              _YearCard(payroll: payroll),
              _PaystubsCard(payroll: payroll),
              const _HowPayWorksCard(),
            ],
          ],
        );
      },
    );
  }
}

class _YearCard extends StatelessWidget {
  const _YearCard({required this.payroll});

  final PayrollSummary payroll;

  @override
  Widget build(BuildContext context) {
    return VeloraCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCaption(tr('{0} so far', [payroll.year])),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              payroll.yearToDateAmount,
              style: VeloraText.display(34, letterSpacing: -0.03),
            ),
          ),
          const SizedBox(height: 2),
          Text(tr('Gross earnings · {0}', [payroll.hoursLabel]), style: VeloraText.body(13.5, color: VeloraColors.muted)),
          const SizedBox(height: 14),
          VeloraButton(
            label: tr('Go to check-in'),
            icon: VeloraIcons.clipboardCheck,
            onPressed: () => AppNavigator.goToTab(context, MainTab.checkIn),
          ),
        ],
      ),
    );
  }
}

class _PaystubsCard extends StatelessWidget {
  const _PaystubsCard({required this.payroll});

  final PayrollSummary payroll;

  @override
  Widget build(BuildContext context) {
    return VeloraCard(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCaption(
            tr('Paystubs'),
            padding: const EdgeInsets.only(top: 8, bottom: 2),
            trailing: Text(
              tr('{0} this year', [payroll.paystubCount]),
              style: VeloraText.body(12, color: VeloraColors.muted),
            ),
          ),
          if (payroll.paystubs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(tr('Your paystubs will show here after your first payday.'), style: VeloraText.subtitle),
            )
          else
            for (var i = 0; i < payroll.paystubs.length; i++)
              _PaystubRow(stub: payroll.paystubs[i], latest: i == 0, showDivider: i > 0),
          DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: VeloraColors.line)),
            ),
            child: Center(
              child: VeloraTextLink(
                label: tr('Tax forms (W-2)'),
                size: 13,
                onTap: () => AppNavigator.goToTab(context, MainTab.docs),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaystubRow extends StatelessWidget {
  const _PaystubRow({
    required this.stub,
    required this.latest,
    required this.showDivider,
  });

  final PaystubItem stub;
  final bool latest;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return VeloraListRow(
      showDivider: showDivider,
      leading: IconTile(
        VeloraIcons.document,
        tone: latest ? IconTileTone.good : IconTileTone.mute,
        iconSize: 18,
      ),
      title: stub.periodLabel,
      subtitle: '${stub.status} · ${stub.hoursLabel.split(' · ').first}',
      trailing: Text(
        stub.grossPay,
        style: VeloraText.body(15, weight: FontWeight.w700)
            .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      ),
      onTap: () => AppNavigator.openPaystub(context, id: stub.id),
    );
  }
}

class _HowPayWorksCard extends StatelessWidget {
  const _HowPayWorksCard();

  @override
  Widget build(BuildContext context) {
    final steps = [
      (tr('Work the month.'), tr('Clock in and out at every visit.')),
      (tr('Finish your check-in'), tr('after the month ends, so the office can confirm your days.')),
      (tr('Get paid'), tr('by direct deposit on the next payday.')),
    ];
    return VeloraCard(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCaption(tr('How pay works'), padding: EdgeInsets.only(top: 8, bottom: 2)),
          for (var i = 0; i < steps.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: i > 0 ? const Border(top: BorderSide(color: VeloraColors.line)) : null,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: VeloraColors.mint,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text('${i + 1}', style: VeloraText.display(13, color: VeloraColors.teal)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: '${steps[i].$1} ',
                        style: VeloraText.body(13.5, weight: FontWeight.w700, height: 1.45),
                        children: [
                          TextSpan(
                            text: steps[i].$2,
                            style: VeloraText.body(13.5, color: VeloraColors.muted, height: 1.45),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
