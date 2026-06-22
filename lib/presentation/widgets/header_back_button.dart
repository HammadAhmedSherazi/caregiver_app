import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/extensions/context_extensions.dart';
import '../home/widgets/home_svg_icon.dart';

/// Back arrow aligned to the first header title line (Figma `1:2988`).
class HeaderBackButton extends StatelessWidget {
  const HeaderBackButton({
    super.key,
    required this.onTap,
    this.titleStyle,
  });

  final VoidCallback onTap;
  final TextStyle? titleStyle;

  static const _iconSize = 34.0;

  /// Figma: back control sits ~9px below the title block top.
  static const _figmaTitleTopInset = 9.0;

  @override
  Widget build(BuildContext context) {
    final style = context.responsiveStyle(titleStyle ?? AppTextStyles.homeWelcome);
    final textLineHeight =
        (style.fontSize ?? 20) * (style.height ?? 1.43);

    final topInset = textLineHeight >= _iconSize
        ? _figmaTitleTopInset
        : ((textLineHeight - _iconSize) / 2).clamp(0.0, _figmaTitleTopInset);

    return Padding(
      padding: EdgeInsets.only(top: topInset),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: const HomeSvgIcon(
          asset: AppAssets.icHomeBackArrow,
          width: _iconSize,
          height: _iconSize,
        ),
      ),
    );
  }
}
