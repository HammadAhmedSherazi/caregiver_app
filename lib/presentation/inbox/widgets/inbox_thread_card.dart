import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../../data/models/inbox_thread_model.dart';
import '../../home/widgets/home_svg_icon.dart';
import '../../task/widgets/task_cards.dart';
import '../../widgets/user_avatar.dart';
import '../../../core/constants/app_assets.dart';

/// Figma node `1:2685` — swipeable inbox thread row.
class InboxThreadCard extends StatelessWidget {
  const InboxThreadCard({
    super.key,
    required this.thread,
    required this.onTap,
    required this.onDismissed,
  });

  final InboxThread thread;
  final VoidCallback onTap;
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
          key: ValueKey(thread.id),
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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: SizedBox(
                height: _cardHeight,
                child: DecoratedBox(
                  decoration: taskCardDecoration(),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UserAvatar(
                          imageUrl: thread.avatarUrl,
                          name: thread.contactName,
                          size: 51,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                thread.contactName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.responsiveStyle(
                                  AppTextStyles.titleMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Expanded(
                                child: Text(
                                  thread.preview,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.responsiveStyle(
                                    AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.homeMutedText,
                                      letterSpacing: -0.28,
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                thread.timestampLabel,
                                style: context.responsiveStyle(
                                  AppTextStyles.homeNavLabel.copyWith(
                                    fontSize: 12,
                                    color: AppColors.homeDarkText,
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
        ),
      ),
    );
  }
}
