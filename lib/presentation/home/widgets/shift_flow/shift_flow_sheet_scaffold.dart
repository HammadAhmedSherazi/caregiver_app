import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/extensions/context_extensions.dart';
import '../home_svg_icon.dart';

Future<bool?> showShiftFlowSheet({
  required BuildContext context,
  required Widget child,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.homeDialogOverlay,
    builder: (_) => child,
  );
}

class ShiftFlowSheetScaffold extends StatelessWidget {
  const ShiftFlowSheetScaffold({
    super.key,
    required this.body,
    this.title,
    this.titleLines,
    this.subtitle,
    this.header,
    required this.action,
  });

  final String? title;
  final List<String>? titleLines;
  final String? subtitle;
  final Widget? header;
  final Widget body;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: ShiftFlowCloseButton(
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ),
            if (header != null)
              header!
            else ...[
              if (titleLines != null)
                ...titleLines!.map(
                  (line) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      line,
                      textAlign: TextAlign.center,
                      style: context.responsiveStyle(AppTextStyles.homeAddress),
                    ),
                  ),
                )
              else if (title != null)
                Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: context.responsiveStyle(AppTextStyles.homeAddress),
                ),
              if (subtitle != null) ...[
                const SizedBox(height: 12),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: context.responsiveStyle(AppTextStyles.homeCardSubtitle),
                ),
              ],
            ],
            const SizedBox(height: 24),
            body,
            const SizedBox(height: 24),
            action,
          ],
        ),
      ),
    );
  }
}

class ShiftFlowCloseButton extends StatelessWidget {
  const ShiftFlowCloseButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      icon: Transform.rotate(
        angle: 0.785398,
        child: const HomeSvgIcon(
          asset: AppAssets.icHomeClose,
          width: 28,
          height: 28,
        ),
      ),
    );
  }
}

class ShiftFlowPrimaryButton extends StatelessWidget {
  const ShiftFlowPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.homePrimary,
          foregroundColor: AppColors.authOnGradient,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: context.responsiveStyle(
            AppTextStyles.homeCardTitle.copyWith(
              color: AppColors.authOnGradient,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class ShiftFlowDetailCard extends StatelessWidget {
  const ShiftFlowDetailCard({
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
      decoration: BoxDecoration(
        color: AppColors.homeSheetDetailsBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.homeSheetDetailsBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.homeCardShadow,
            blurRadius: 26,
            offset: Offset(0, 24),
          ),
        ],
      ),
      child: child,
    );
  }
}

class ShiftFlowDetailRow extends StatelessWidget {
  const ShiftFlowDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.trailing,
  });

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final labelStyle = context.responsiveStyle(
      AppTextStyles.homeCardTitle.copyWith(
        fontWeight: FontWeight.w400,
        fontSize: 16,
        letterSpacing: -0.32,
        color: AppColors.homeSheetLabel,
      ),
    );
    final valueStyle = context.responsiveStyle(
      AppTextStyles.homeCardTitle.copyWith(
        fontSize: 16,
        letterSpacing: -0.8,
      ),
    );

    return Row(
      children: [
        Text(label, style: labelStyle),
        const Spacer(),
        if (trailing != null)
          trailing!
        else
          Flexible(
            child: Text(
              value,
              style: valueStyle,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

class ShiftFlowStatusBadge extends StatelessWidget {
  const ShiftFlowStatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.iconAsset,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final String? iconAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconAsset != null)
            HomeSvgIcon(asset: iconAsset!, width: 8, height: 8, color: textColor)
          else
            Icon(Icons.circle, size: 8, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: context.responsiveStyle(
              AppTextStyles.labelSmall.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: textColor,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ShiftFlowLocationBar extends StatelessWidget {
  const ShiftFlowLocationBar({super.key, required this.address});

  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.homeSheetDetailsBg,
        borderRadius: BorderRadius.circular(15),
      ),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          const HomeSvgIcon(
            asset: AppAssets.icHomeLocation,
            width: 12,
            height: 12,
            color: AppColors.homeDarkText,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              address,
              style: context.responsiveStyle(AppTextStyles.homeCardSubtitle),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class ShiftFlowOfflineBanner extends StatelessWidget {
  const ShiftFlowOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 11),
      decoration: BoxDecoration(
        color: AppColors.homeOfflineBannerBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.homeSheetDetailsBg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HomeSvgIcon(
            asset: AppAssets.icHomeInfo,
            width: 12,
            height: 12,
            color: AppColors.homeDarkText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'If you\'re offline, your clock-in will be saved locally and '
              'synced automatically when back online.',
              style: context.responsiveStyle(
                AppTextStyles.labelSmall.copyWith(
                  fontSize: 10,
                  color: AppColors.homeDarkText,
                  letterSpacing: -0.2,
                  height: 1.43,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
