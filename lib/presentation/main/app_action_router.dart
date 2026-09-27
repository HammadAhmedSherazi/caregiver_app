import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/api/velora/velora_models.dart';
import '../checkin/cubit/checkin_cubit.dart';
import '../time/cubit/time_cubit.dart';
import '../time/view/fix_visit_view.dart';
import 'app_navigator.dart';
import 'widgets/main_bottom_nav_bar.dart';

/// Single place that turns a server `action` (`{ screen, params }`) into
/// navigation — used by dashboard items, notifications and push taps
/// (MOBILE_API_VELORA.md §0).
class AppActionRouter {
  AppActionRouter._();

  /// Maps the contract's `upload.params.document_type` to the Upload
  /// screen's type ids.
  static const _uploadTypes = {
    'photo_id': 'id',
    'tax_or_pay_form': 'tax',
    'doctor_or_hospital_note': 'med',
    'state_letter': 'state',
    'other': 'other',
  };

  /// Opens the screen for [action]. Returns `false` for unknown screen keys
  /// (newer server keys are ignored rather than crashing older apps).
  static Future<bool> open(BuildContext context, AppActionModel action) async {
    final screen = action.screen;
    if (screen == null) return false;

    switch (screen) {
      case AppScreen.home:
        AppNavigator.goToTab(context, MainTab.home);
      case AppScreen.time:
        AppNavigator.goToTab(context, MainTab.time);
      case AppScreen.pay:
        AppNavigator.goToTab(context, MainTab.pay);
      case AppScreen.docs:
        AppNavigator.goToTab(context, MainTab.docs);
      case AppScreen.report:
        await AppNavigator.openReportChange(context);
      case AppScreen.inbox:
        await AppNavigator.openInbox(context);
      case AppScreen.profile:
        await AppNavigator.openProfile(context);
      case AppScreen.paystub:
        final payId = action.stringParam('pay_id');
        if (payId == null) {
          AppNavigator.goToTab(context, MainTab.pay);
        } else {
          await AppNavigator.openPaystub(context, id: payId);
        }
      case AppScreen.upload:
        await AppNavigator.openUpload(
          context,
          initialType: _uploadTypes[action.stringParam('document_type')],
          replacesDocumentId: action.intParam('replaces_document_id'),
        );
      case AppScreen.checkIn:
        await _openCheckIn(context, action.intParam('form_id'));
      case AppScreen.fixClockout:
        await _openFixClockout(context, action.intParam('visit_id'));
    }
    return true;
  }

  static Future<void> _openCheckIn(BuildContext context, int? formId) async {
    final forms = context.read<CheckInCubit>().state.forms;
    final form = forms.where((f) => f.id == formId).firstOrNull;
    if (form == null || form.submitted) {
      AppNavigator.goToTab(context, MainTab.checkIn);
      return;
    }
    await AppNavigator.openCheckInFlow(context, formId: form.id, periodLabel: form.periodLabel);
  }

  static Future<void> _openFixClockout(BuildContext context, int? visitId) async {
    final visit = context.read<TimeCubit>().state.visits.where((v) => v.id == visitId).firstOrNull;
    if (visit == null) {
      // Not in the loaded history — show the Time tab, which lists it.
      AppNavigator.goToTab(context, MainTab.time);
      return;
    }
    await AppNavigator.openFixVisit(context, args: FixVisitArgs.fromVisit(visit));
  }
}
