import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_helper.dart';
import '../../../core/responsive/screen_size.dart';

typedef ResponsiveWidgetBuilder = Widget Function(BuildContext context);

/// Switches UI by screen size without repeating breakpoint checks.
///
/// [tablet] and [expanded] fall back to [mobile] when not provided.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.expanded,
  });

  final ResponsiveWidgetBuilder mobile;
  final ResponsiveWidgetBuilder? tablet;
  final ResponsiveWidgetBuilder? expanded;

  @override
  Widget build(BuildContext context) {
    return switch (ResponsiveHelper.screenSizeOf(context)) {
      ScreenSize.compact => mobile(context),
      ScreenSize.medium => (tablet ?? mobile)(context),
      ScreenSize.expanded => (expanded ?? tablet ?? mobile)(context),
    };
  }
}
