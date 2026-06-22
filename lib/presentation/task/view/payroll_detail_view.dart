import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../../data/models/task_page_model.dart';
import '../../home/widgets/vertical_overlap.dart';
import '../widgets/payroll_widgets.dart';
import '../widgets/task_primary_button.dart';
import '../widgets/task_screen_header.dart';

class PayrollDetailView extends StatelessWidget {
  const PayrollDetailView({
    super.key,
    required this.detail,
  });

  final PaystubDetail detail;

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
                subtitle: detail.periodLabel,
                onBack: () => Navigator.of(context).pop(),
                height: _headerHeight,
              ),
              VerticalOverlap(
                overlap: _heroOverlap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: PayrollHeroCard(
                    label: 'Net pay',
                    amount: detail.netPay,
                    height: 141,
                    footer: const PayrollPaidBadge(),
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
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const PayrollSectionTitle(title: 'Breakdown'),
                const SizedBox(height: 16),
                PayrollInfoCard(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  child: Column(
                    children: [
                      PayrollDetailRow(
                        label: 'Gross pay',
                        value: detail.grossPay,
                      ),
                      const SizedBox(height: 20),
                      PayrollDetailRow(
                        label: 'Federal tax',
                        value: detail.federalTax,
                      ),
                      const SizedBox(height: 20),
                      PayrollDetailRow(
                        label: 'State tax',
                        value: detail.stateTax,
                      ),
                      const SizedBox(height: 20),
                      PayrollDetailRow(
                        label: 'FICA',
                        value: detail.fica,
                      ),
                      const SizedBox(height: 16),
                      const Divider(
                        height: 1,
                        color: Color(0x1A000000),
                      ),
                      const SizedBox(height: 16),
                      PayrollDetailRow(
                        label: 'Net pay',
                        value: detail.netPay,
                        emphasized: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                PayrollInfoCard(
                  padding: const EdgeInsets.fromLTRB(16, 23, 16, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VISIT SUMMARY',
                        style: context.responsiveStyle(
                          AppFonts.base(
                            fontSize: 10,
                            fontWeight: AppFonts.semiBold,
                            color: AppColors.homeDarkText,
                            height: 1.43,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
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
                const SizedBox(height: 32),
                TaskPrimaryButton(
                  label: 'Download PDF',
                  onPressed: () {},
                ),
                const SizedBox(height: 20),
                const Divider(color: AppColors.homeDialogDivider),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Email paystub',
                    style: context.responsiveStyle(
                      AppTextStyles.homeCardSubtitle.copyWith(
                        color: const Color(0xFF444444),
                      ),
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
