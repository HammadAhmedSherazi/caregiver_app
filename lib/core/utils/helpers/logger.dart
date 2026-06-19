import 'dart:developer' as developer;

class AppLogger {
  AppLogger._();

  static void debug(String message, {String? tag}) {
    developer.log(message, name: tag ?? 'DEBUG');
  }

  static void info(String message, {String? tag}) {
    developer.log(message, name: tag ?? 'INFO');
  }

  static void warning(String message, {String? tag}) {
    developer.log(message, name: tag ?? 'WARNING');
  }

  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: tag ?? 'ERROR',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
