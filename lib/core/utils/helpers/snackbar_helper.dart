import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';

class SnackbarHelper {
  SnackbarHelper._();

  static void show(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
    Duration duration = AppConstants.snackBarDuration,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          duration: duration,
        ),
      );
  }

  static void showSuccess(BuildContext context, String message) {
    show(context, message: message, backgroundColor: Colors.green);
  }

  static void showError(BuildContext context, String message) {
    show(context, message: message, backgroundColor: Colors.red);
  }
}
