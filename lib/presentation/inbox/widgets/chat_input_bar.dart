import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../home/widgets/home_svg_icon.dart';

/// Figma node `1:2779` — message composer bar.
class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.enabled = true,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.homeCardShadow,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  style: context.responsiveStyle(
                    AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.homeDarkText,
                      letterSpacing: -0.14,
                    ),
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Write your message',
                    hintStyle: context.responsiveStyle(
                      AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.homeDarkText,
                        letterSpacing: -0.14,
                      ),
                    ),
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: enabled ? onSend : null,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.homePrimary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const HomeSvgIcon(
                  asset: AppAssets.icSend,
                  width: 18,
                  height: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
