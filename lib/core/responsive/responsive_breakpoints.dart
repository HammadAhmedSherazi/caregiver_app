class ResponsiveBreakpoints {
  ResponsiveBreakpoints._();

  /// Phone → tablet boundary
  static const double tablet = 600;

  /// Tablet → large screen boundary
  static const double large = 1024;

  /// Max width for form/auth content on tablet & large screens. Unbounded:
  /// tablets use the full width (see VeloraSpacing.maxContentWidth).
  static const double formMaxWidth = double.infinity;

  /// Max width for general page content on large screens.
  static const double contentMaxWidth = double.infinity;

  /// Max width for grid/list content on expanded screens.
  static const double gridMaxWidth = double.infinity;
}
