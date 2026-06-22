import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/schedule_page_model.dart';
import '../../home/widgets/home_svg_icon.dart';
import 'schedule_status_badge.dart';

class ScheduleAppointmentCard extends StatelessWidget {
  const ScheduleAppointmentCard({
    super.key,
    required this.appointment,
  });

  final ScheduleAppointment appointment;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 154,
      padding: const EdgeInsets.fromLTRB(22, 15, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.authOnGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.homeCardShadow,
            blurRadius: 26,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TimelineIndicator(),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        appointment.timeLabel,
                        style: AppTextStyles.scheduleTime,
                      ),
                    ),
                    ScheduleStatusBadge(status: appointment.status),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  appointment.clientName,
                  style: AppTextStyles.scheduleClientName,
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: HomeSvgIcon(
                        asset: AppAssets.icHomeLocation,
                        width: 12,
                        height: 12,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        appointment.address,
                        style: AppTextStyles.scheduleAddress,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 13,
      child: Column(
        children: [
          const HomeSvgIcon(
            asset: AppAssets.icScheduleTimelineDot,
            width: 13,
            height: 13,
          ),
          Expanded(
            child: Container(
              width: 0.5,
              margin: const EdgeInsets.symmetric(vertical: 4),
              color: AppColors.scheduleTimelineLine,
            ),
          ),
        ],
      ),
    );
  }
}
