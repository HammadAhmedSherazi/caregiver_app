import 'package:flutter/material.dart';

import '../../responsive/responsive_font.dart';
import '../../responsive/responsive_helper.dart';
import '../../responsive/screen_size.dart';

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);

  TextTheme get textTheme => theme.textTheme;

  ColorScheme get colorScheme => theme.colorScheme;

  MediaQueryData get mediaQuery => MediaQuery.of(this);

  Size get screenSize => mediaQuery.size;

  double get screenWidth => screenSize.width;

  double get screenHeight => screenSize.height;

  bool get isKeyboardVisible => mediaQuery.viewInsets.bottom > 0;

  ScreenSize get screenSizeClass => ResponsiveHelper.screenSizeOf(this);

  bool get isCompactScreen => screenSizeClass == ScreenSize.compact;

  bool get isTabletScreen => screenSizeClass == ScreenSize.medium;

  bool get isLargeScreen => screenSizeClass == ScreenSize.expanded;

  bool get isTabletOrLarger => !isCompactScreen;

  /// Scales a Figma design font size to the current device width.
  double sp(double designFontSize) => ResponsiveFont.size(this, designFontSize);

  /// Applies width-based scaling to an [TextStyle]'s font size and letter spacing.
  TextStyle responsiveStyle(TextStyle style) => ResponsiveFont.apply(this, style);

  void hideKeyboard() => FocusScope.of(this).unfocus();
}
