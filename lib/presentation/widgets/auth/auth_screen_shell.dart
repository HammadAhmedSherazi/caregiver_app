import 'package:flutter/material.dart';

import '../../../core/responsive/responsive_breakpoints.dart';
import '../../../core/responsive/responsive_helper.dart';
import 'auth_gradient_background.dart';

/// Wraps auth/onboarding screens with the shared gradient background.
/// On tablet/large screens, content stays mobile-width and centered.
class AuthScreenShell extends StatelessWidget {
  const AuthScreenShell({
    super.key,
    required this.child,
    this.maxContentWidth = ResponsiveBreakpoints.formMaxWidth,
    this.showCurveLine = false,
  });

  final Widget child;
  final double maxContentWidth;
  final bool showCurveLine;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AuthGradientBackground(
        showCurveLine: showCurveLine,
        child: SafeArea(
          child: ResponsiveHelper.isTabletOrLarger(context)
              ? Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxContentWidth),
                    child: child,
                  ),
                )
              : child,
        ),
      ),
    );
  }
}
