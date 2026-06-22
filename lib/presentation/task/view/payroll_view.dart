import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/task_page_model.dart';
import '../../home/widgets/vertical_overlap.dart';
import '../cubit/task_cubit.dart';
import '../widgets/payroll_paystub_card.dart';
import '../widgets/payroll_widgets.dart';
import '../widgets/task_primary_button.dart';
import '../widgets/task_screen_header.dart';
import 'payroll_detail_view.dart';

class PayrollView extends StatelessWidget {
  const PayrollView({
    super.key,
    required this.payroll,
  });

  final PayrollSummary payroll;

  static const _headerHeight = 209.0;
  static const _heroOverlap = 48.0;

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
                title: 'Payroll',
                subtitle: '${payroll.year}',
                onBack: () => Navigator.of(context).pop(),
                height: _headerHeight,
              ),
              VerticalOverlap(
                overlap: _heroOverlap,
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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
              children: [
                const PayrollSectionTitle(title: 'Paystubs'),
                const SizedBox(height: 16),
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
                const SizedBox(height: 9),
                TaskPrimaryButton(
                  label: 'Download all (PDF)',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
