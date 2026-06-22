import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../widgets/header_back_button.dart';

class TaskScreenHeader extends StatelessWidget {
  const TaskScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.height = 187,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
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
                      if (onBack != null) ...[
                        HeaderBackButton(onTap: onBack!),
                        const SizedBox(width: 24),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: context.responsiveStyle(
                                AppTextStyles.homeWelcome,
                              ),
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                style: context.responsiveStyle(
                                  AppTextStyles.homeDate,
                                ),
                              ),
                          ],
                        ),
                      ),
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
