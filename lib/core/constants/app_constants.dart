class AppConstants {
  AppConstants._();

  static const String appName = 'Velora Cares';

  /// Sent as `app_version` to `POST /devices`; keep in sync with pubspec.
  static const String appVersion = '1.0.0';
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration snackBarDuration = Duration(seconds: 3);
}
