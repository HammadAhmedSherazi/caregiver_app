import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../../data/models/task_page_model.dart';
import '../../home/widgets/home_icon_box.dart';
import '../../home/widgets/home_svg_icon.dart';
import 'task_cards.dart';

BoxDecoration complianceFormHeroDecoration() {
  return BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
    boxShadow: const [
      BoxShadow(
        color: AppColors.homeCardShadow,
        blurRadius: 26,
        offset: Offset(0, 24),
      ),
    ],
  );
}

class ComplianceFormHeroCard extends StatelessWidget {
  const ComplianceFormHeroCard({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      // height: 90,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: complianceFormHeroDecoration(),
      child: Row(
        children: [
          const HomeIconBox(
            iconAsset: AppAssets.icTaskForm,
            width: 48,
            height: 47,
            iconSize: 20,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: context.responsiveStyle(
                    AppFonts.base(
                      fontSize: 14,
                      fontWeight: AppFonts.bold,
                      color: AppColors.homeDarkText,
                      height: 1.43,
                      letterSpacing: -0.7,
                    ),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: context.responsiveStyle(
                    AppFonts.base(
                      fontSize: 14,
                      fontWeight: AppFonts.regular,
                      color: AppColors.homeDarkText.withValues(alpha: 0.35),
                      height: 1.43,
                      letterSpacing: -0.28,
                    ),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ComplianceQuestionCard extends StatelessWidget {
  const ComplianceQuestionCard({
    super.key,
    required this.question,
    required this.onChanged,
  });

  final ComplianceQuestion question;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 162,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(23, 17, 23, 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.homeCardShadow,
            blurRadius: 26,
            offset: Offset(0, 24),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.prompt,
            style: context.responsiveStyle(
              AppTextStyles.homeCardTitle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const Spacer(),
          TaskYesNoToggle(
            selectedYes: question.selectedYes,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class ComplianceNotesSection extends StatelessWidget {
  const ComplianceNotesSection({
    super.key,
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: context.responsiveStyle(
              AppTextStyles.homeCardTitle.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: -0.8,
                color: AppColors.homeDarkText,
              ),
            ),
            children: [
              const TextSpan(text: 'Additional notes '),
              TextSpan(
                text: '(optional)',
                style: context.responsiveStyle(
                  AppTextStyles.homeCardSubtitle.copyWith(
                    fontSize: 16,
                    letterSpacing: -0.8,
                    color: AppColors.homeDarkText.withValues(alpha: 0.44),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 119,
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: AppColors.homeCardShadow,
                blurRadius: 26,
                offset: Offset(0, 24),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: context.responsiveStyle(
              AppTextStyles.homeCardSubtitle.copyWith(
                fontSize: 14,
                letterSpacing: -0.28,
                color: AppColors.homeDarkText,
              ),
            ),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              hintText: 'Add any additional context...',
              hintStyle: context.responsiveStyle(
                AppTextStyles.homeCardSubtitle.copyWith(
                  fontSize: 14,
                  letterSpacing: -0.28,
                  color: AppColors.homeDarkText.withValues(alpha: 0.35),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ComplianceSignatureCard extends StatelessWidget {
  const ComplianceSignatureCard({
    super.key,
    required this.hasSignature,
    required this.onSign,
    required this.onClear,
  });

  final bool hasSignature;
  final VoidCallback onSign;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.homeCardShadow,
            blurRadius: 26,
            offset: Offset(0, 24),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Digital signature',
            style: context.responsiveStyle(
              AppTextStyles.homeCardTitle.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: hasSignature ? null : onSign,
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: AppColors.homePrimary,
                radius: 13,
              ),
              child: Container(
                height: 188,
                width: double.infinity,
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: AppColors.homeIconTint,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: hasSignature
                          ? const HomeSvgIcon(
                              asset: AppAssets.icTaskSubmittedCheck,
                              width: 32,
                              height: 32,
                            )
                          : Text(
                              'Signed here with finger',
                              style: context.responsiveStyle(
                                AppTextStyles.homeCardSubtitle.copyWith(
                                  fontSize: 14,
                                  letterSpacing: -0.28,
                                  color: AppColors.homeDarkText
                                      .withValues(alpha: 0.35),
                                ),
                              ),
                            ),
                    ),
                    if (hasSignature)
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: GestureDetector(
                          onTap: onClear,
                          behavior: HitTestBehavior.opaque,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const HomeSvgIcon(
                                asset: AppAssets.icHomeRetry,
                                width: 10,
                                height: 10,
                                color: AppColors.homePrimary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Clear',
                                style: context.responsiveStyle(
                                  AppFonts.base(
                                    fontSize: 12,
                                    fontWeight: AppFonts.regular,
                                    color: AppColors.homePrimary,
                                    height: 1.43,
                                    letterSpacing: -0.24,
                                  ),
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
          ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.radius,
  });

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.5, 0.5, size.width - 1, size.height - 1),
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rect);

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, end.clamp(0.0, metric.length)),
          paint,
        );
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.radius != radius;
  }
}
