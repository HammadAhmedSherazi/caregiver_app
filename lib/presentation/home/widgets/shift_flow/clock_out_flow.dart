import 'package:flutter/material.dart';

import '../../../../data/models/home_dashboard_model.dart';
import 'confirm_clock_out_dialog.dart';
import 'shift_completed_preview_sheet.dart';
import 'submit_clock_out_sheet.dart';

/// Clock-out flow: confirm → preview sheet → summary sheet.
class ClockOutFlow {
  ClockOutFlow._();

  static Future<bool> run(
    BuildContext context, {
    required ActiveShift shift,
  }) async {
    final confirmed = await ConfirmClockOutDialog.show(context);
    if (!context.mounted || !confirmed) return false;

    final viewSummary = await ShiftCompletedPreviewSheet.show(
      context,
      shift: shift,
    );
    if (!context.mounted || !viewSummary) return false;

    final completed = await ShiftCompletedSummarySheet.show(
      context,
      shift: shift,
    );
    return completed;
  }
}
