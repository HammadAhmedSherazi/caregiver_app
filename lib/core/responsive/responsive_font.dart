import 'package:flutter/material.dart';

import 'responsive_breakpoints.dart';

/// Width-based font scaling against the Figma design frame (430 logical px).
class ResponsiveFont {
  ResponsiveFont._();

  static const double designWidth = 430;

  static const double minFactor = 0.85;
  static const double maxFactor = 1.12;

  static double factor(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width >= ResponsiveBreakpoints.large) {
      return maxFactor;
    }
    if (width >= ResponsiveBreakpoints.tablet) {
      return (width / designWidth).clamp(0.95, maxFactor);
    }

    return (width / designWidth).clamp(minFactor, 1.0);
  }

  static double size(BuildContext context, double designFontSize) {
    return designFontSize * factor(context);
  }

  static TextStyle apply(BuildContext context, TextStyle style) {
    final fontSize = style.fontSize;
    if (fontSize == null) {
      return style;
    }

    final scale = factor(context);
    return style.copyWith(
      fontSize: fontSize * scale,
      letterSpacing:
          style.letterSpacing != null ? style.letterSpacing! * scale : null,
    );
  }
}
