import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_fonts.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions/context_extensions.dart';

const _heroGlowAngle = -56.95 * math.pi / 180;

BoxDecoration payrollCardDecoration({Color color = AppColors.surface}) {
  return BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(20),
    boxShadow: const [
      BoxShadow(
        color: AppColors.homeCardShadow,
        blurRadius: 26,
        offset: Offset(0, 24),
      ),
    ],
  );
}

BoxDecoration payrollHeroDecoration() {
  return BoxDecoration(
    color: AppColors.payrollHeroCard,
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

class PayrollHeroCard extends StatelessWidget {
  const PayrollHeroCard({
    super.key,
    required this.label,
    required this.amount,
    this.subtitle,
    this.badges = const [],
    this.footer,
    this.height = 184,
  });

  final String label;
  final String amount;
  final String? subtitle;
  final List<String> badges;
  final Widget? footer;
  final double height;

  static const _badgeWidths = <double>[133, 85];

  @override
  Widget build(BuildContext context) {
    final labelStyle = context.responsiveStyle(
      AppFonts.base(
        fontSize: 10,
        fontWeight: AppFonts.semiBold,
        color: Colors.white,
        height: 1.43,
        letterSpacing: -0.2,
      ),
    );
    final amountStyle = context.responsiveStyle(
      AppFonts.base(
        fontSize: 36,
        fontWeight: AppFonts.semiBold,
        color: Colors.white,
        height: 1.43,
        letterSpacing: 2.16,
      ),
    );
    final subtitleStyle = context.responsiveStyle(
      AppFonts.base(
        fontSize: 10,
        fontWeight: AppFonts.semiBold,
        color: Colors.white,
        height: 1.43,
        letterSpacing: 0.1,
      ),
    );

    return Container(
      height: height,
      width: double.infinity,
      decoration: payrollHeroDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          const _PayrollHeroGlow(),
          Positioned(
            left: 16,
            top: 19,
            right: 16,
            child: Text(
              label.toUpperCase(),
              style: labelStyle,
            ),
          ),
          Positioned(
            left: 16,
            top: 37,
            right: 16,
            child: Text(
              amount,
              style: amountStyle,
            ),
          ),
          if (subtitle != null)
            Positioned(
              left: 16,
              top: 86,
              right: 16,
              child: Text(
                subtitle!.toUpperCase(),
                style: subtitleStyle,
              ),
            ),
          if (footer != null)
            Positioned(
              left: 16,
              top: 100,
              child: footer!,
            )
          else if (badges.isNotEmpty)
            Positioned(
              left: 16,
              top: 146,
              child: Row(
                children: [
                  for (var i = 0; i < badges.length; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    _HeroBadge(
                      label: badges[i],
                      width: i < _badgeWidths.length ? _badgeWidths[i] : null,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PayrollHeroGlow extends StatelessWidget {
  const _PayrollHeroGlow();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: -76,
      top: -80,
      width: 391.36,
      height: 370.16,
      child: Center(
        child: Transform.rotate(
          angle: _heroGlowAngle,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
            child: Container(
              width: 239,
              height: 311.41,
              decoration: BoxDecoration(
                color: const Color(0xFF5297FF).withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(155),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.label,
    this.width,
  });

  final String label;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      width: width,
      padding: width == null ? const EdgeInsets.symmetric(horizontal: 12) : null,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: context.responsiveStyle(
          AppFonts.base(
            fontSize: 10,
            fontWeight: AppFonts.regular,
            color: Colors.white,
            height: 2.4,
          ),
        ),
      ),
    );
  }
}

class PayrollPaidBadge extends StatelessWidget {
  const PayrollPaidBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      constraints: const BoxConstraints(minWidth: 62),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.scheduleScheduledText.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        'Paid',
        style: context.responsiveStyle(
          AppFonts.base(
            fontSize: 10,
            fontWeight: AppFonts.medium,
            color: AppColors.scheduleScheduledText,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class PayrollDetailRow extends StatelessWidget {
  const PayrollDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: context.responsiveStyle(
              AppTextStyles.homeCardTitle.copyWith(
                fontWeight: emphasized ? FontWeight.w500 : FontWeight.w400,
                fontSize: 16,
                letterSpacing: -0.32,
                color:
                    emphasized ? AppColors.homeDarkText : AppColors.homeSheetLabel,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: context.responsiveStyle(
              AppTextStyles.homeCardTitle.copyWith(
                fontWeight: FontWeight.w400,
                fontSize: 16,
                letterSpacing: -0.8,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PayrollSectionTitle extends StatelessWidget {
  const PayrollSectionTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: context.responsiveStyle(
        AppTextStyles.homeCardTitle.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.homeDarkText,
        ),
      ),
    );
  }
}

class PayrollInfoCard extends StatelessWidget {
  const PayrollInfoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 20, 16, 20),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: payrollCardDecoration(),
      child: child,
    );
  }
}
