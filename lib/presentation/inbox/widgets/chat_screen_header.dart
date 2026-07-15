import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../home/widgets/home_svg_icon.dart';
import '../../widgets/header_back_button.dart';
import '../../widgets/user_avatar.dart';

/// Figma node `1:2779` — chat screen header with avatar and call action.
class ChatScreenHeader extends StatelessWidget {
  const ChatScreenHeader({
    super.key,
    required this.title,
    this.avatarUrl,
    this.avatarName,
    required this.onBack,
    this.onCall,
    this.height = 171,
  });

  final String title;
  final String? avatarUrl;
  final String? avatarName;
  final VoidCallback onBack;
  final VoidCallback? onCall;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: ColoredBox(
        color: AppColors.homeHeader,
        child: SizedBox(
          height: height,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: 92,
                top: -222,
                width: 416,
                height: 353,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.authGlowTop,
                          AppColors.authGlowTop.withValues(alpha: 0.35),
                          AppColors.authGlowTop.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(19, 16, 24, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HeaderBackButton(onTap: onBack),
                      const SizedBox(width: 12),
                      UserAvatar(
                        imageUrl: avatarUrl,
                        name: avatarName ?? title,
                        size: 45,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            title,
                            style: context.responsiveStyle(
                              AppTextStyles.homeWelcome.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // if (onCall != null)
                      //   Padding(
                      //     padding: const EdgeInsets.only(top: 8),
                      //     child: GestureDetector(
                      //       onTap: onCall,
                      //       behavior: HitTestBehavior.opaque,
                      //       child: const HomeSvgIcon(
                      //         asset: AppAssets.icCallBulkWhite,
                      //         width: 24,
                      //         height: 24,
                      //       ),
                      //     ),
                      //   ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
