import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_breakpoints.dart';
import '../../../core/responsive/responsive_helper.dart';

/// Centers content with responsive padding and optional max width.
/// Use on tablet/large screens to preserve mobile-designed layouts.
class AdaptiveContent extends StatelessWidget {
  const AdaptiveContent({
    super.key,
    required this.child,
    this.maxWidth = ResponsiveBreakpoints.formMaxWidth,
    this.alignTop = false,
    this.scrollable = false,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final bool alignTop;
  final bool scrollable;
  final EdgeInsetsGeometry? padding;

  EdgeInsetsGeometry _resolvePadding(BuildContext context) {
    return padding ??
        EdgeInsets.all(
          ResponsiveHelper.value(
            context,
            compact: 24,
            medium: 32,
            expanded: 48,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    );

    final aligned = Align(
      alignment: alignTop ? Alignment.topCenter : Alignment.center,
      child: content,
    );

    if (!scrollable) {
      return Padding(
        padding: _resolvePadding(context),
        child: aligned,
      );
    }

    return SingleChildScrollView(
      padding: _resolvePadding(context),
      child: aligned,
    );
  }
}
