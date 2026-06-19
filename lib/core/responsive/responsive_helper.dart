import 'package:flutter/material.dart';

import 'responsive_breakpoints.dart';
import 'screen_size.dart';

class ResponsiveHelper {
  ResponsiveHelper._();

  static ScreenSize screenSizeOf(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width >= ResponsiveBreakpoints.large) {
      return ScreenSize.expanded;
    }
    if (width >= ResponsiveBreakpoints.tablet) {
      return ScreenSize.medium;
    }
    return ScreenSize.compact;
  }

  static bool isCompact(BuildContext context) =>
      screenSizeOf(context) == ScreenSize.compact;

  static bool isMedium(BuildContext context) =>
      screenSizeOf(context) == ScreenSize.medium;

  static bool isExpanded(BuildContext context) =>
      screenSizeOf(context) == ScreenSize.expanded;

  static bool isTabletOrLarger(BuildContext context) =>
      screenSizeOf(context) != ScreenSize.compact;

  static T value<T>(
    BuildContext context, {
    required T compact,
    T? medium,
    T? expanded,
  }) {
    return switch (screenSizeOf(context)) {
      ScreenSize.compact => compact,
      ScreenSize.medium => medium ?? compact,
      ScreenSize.expanded => expanded ?? medium ?? compact,
    };
  }
}
