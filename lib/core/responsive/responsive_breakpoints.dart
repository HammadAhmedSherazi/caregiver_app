class ResponsiveBreakpoints {
  ResponsiveBreakpoints._();

  /// Phone → tablet boundary
  static const double tablet = 600;

  /// Tablet → large screen boundary
  static const double large = 1024;

  /// Max width for form/auth content on tablet & large screens.
  /// Keeps mobile-designed UI centered instead of stretching edge-to-edge.
  static const double formMaxWidth = 480;

  /// Max width for general page content on large screens.
  static const double contentMaxWidth = 720;

  /// Max width for grid/list content on expanded screens.
  static const double gridMaxWidth = 960;
}
