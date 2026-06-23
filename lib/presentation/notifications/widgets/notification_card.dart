import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../../data/models/notification_model.dart';
import '../../home/widgets/home_icon_box.dart';
import '../../home/widgets/home_svg_icon.dart';
import '../../task/widgets/task_cards.dart';

/// Figma node `1:2736` — swipeable notification row.
class NotificationCard extends StatelessWidget {
  const NotificationCard({
    super.key,
    required this.notification,
    required this.onDismissed,
  });

  final AppNotification notification;
  final VoidCallback onDismissed;

  static const _cardHeight = 118.0;
  static const _deleteActionWidth = 97.0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Dismissible(
          key: ValueKey(notification.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => onDismissed(),
          background: Container(
            alignment: Alignment.centerRight,
            color: AppColors.homePrimary,
            child: const SizedBox(
              width: _deleteActionWidth,
              child: Center(
                child: HomeSvgIcon(
                  asset: AppAssets.icTrash,
                  width: 24,
                  height: 24,
                ),
              ),
            ),
          ),
          child: SizedBox(
            height: _cardHeight,
            child: DecoratedBox(
              decoration: taskCardDecoration(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _NotificationLeading(kind: notification.kind),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notification.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.responsiveStyle(
                              AppTextStyles.titleMedium.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: Text(
                              notification.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.responsiveStyle(
                                AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.homeMutedText,
                                ),
                              ),
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              notification.timestampLabel,
                              style: context.responsiveStyle(
                                AppTextStyles.homeNavLabel.copyWith(
                                  fontSize: 12,
                                  color: AppColors.homeMutedText,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationLeading extends StatelessWidget {
  const _NotificationLeading({required this.kind});

  final NotificationKind kind;

  @override
  Widget build(BuildContext context) {
    final (icon, tint) = switch (kind) {
      NotificationKind.schedule => (
          AppAssets.icHomeNavSchedule,
          AppColors.homePrimary,
        ),
      NotificationKind.compliance => (
          AppAssets.icTaskForm,
          AppColors.homePriority,
        ),
      NotificationKind.message => (
          AppAssets.icHomeMessage,
          AppColors.homeAccent,
        ),
    };

    return HomeIconBox(
      width: 48,
      height: 48,
      iconAsset: icon,
      iconSize: 22,
      boxColor: tint.withValues(alpha: 0.12),
      color: tint,
    );
  }
}
