import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../../data/models/task_page_model.dart';
import '../../home/widgets/home_icon_box.dart';
import 'payroll_widgets.dart';

class PayrollPaystubCard extends StatelessWidget {
  const PayrollPaystubCard({
    super.key,
    required this.stub,
    required this.onTap,
  });

  final PaystubItem stub;
  final VoidCallback onTap;

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
          decoration: payrollCardDecoration(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HomeIconBox(
                iconAsset: AppAssets.icTaskPayroll,
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
                        stub.periodLabel,
                        style: context.responsiveStyle(
                          AppTextStyles.homeCardTitle.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.8,
                          ),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        stub.hoursLabel,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    stub.netPay,
                    style: context.responsiveStyle(
                      AppTextStyles.homeCardTitle.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.28,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (stub.isPaid)
                    const PayrollPaidBadge()
                  else
                    Container(
                      height: 24,
                      constraints: const BoxConstraints(minWidth: 62),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.homePriority.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        'Pending',
                        style: context.responsiveStyle(
                          AppTextStyles.scheduleBadge.copyWith(
                            color: AppColors.homePriority,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
