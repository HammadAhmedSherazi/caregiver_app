import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/i18n/tr.dart';
import '../../data/models/api/velora/velora_models.dart';

import '../checkin/view/checkin_flow_view.dart';
import '../documents/view/document_viewer_view.dart';
import '../documents/view/upload_view.dart';
import '../help/view/help_view.dart';
import '../help/view/privacy_view.dart';
import '../inbox/view/inbox_view.dart';
import '../pay/view/paystub_view.dart';
import '../profile/view/my_info_view.dart';
import '../profile/view/profile_view.dart';
import '../report/view/report_change_view.dart';
import '../task/cubit/task_cubit.dart';
import '../time/view/fix_visit_view.dart';
import 'widgets/main_bottom_nav_bar.dart';

/// Central place for the design's page-to-page links (see the "Button map").
class AppNavigator {
  AppNavigator._();

  static Future<T?> _push<T>(BuildContext context, Widget page) {
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(builder: (_) => page),
    );
  }

  static ValueChanged<MainTab>? _tabSelector;

  /// Registered by the main shell while it is mounted.
  static void registerTabSelector(ValueChanged<MainTab> selector) {
    _tabSelector = selector;
  }

  static void unregisterTabSelector(ValueChanged<MainTab> selector) {
    if (_tabSelector == selector) _tabSelector = null;
  }

  /// Switches the bottom tab without touching the route stack.
  static void selectTab(MainTab tab) => _tabSelector?.call(tab);

  /// Pops any pushed pages back to the shell, then switches the tab.
  static void goToTab(BuildContext context, MainTab tab) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    selectTab(tab);
  }

  static Future<void> openInbox(BuildContext context) =>
      _push(context, const InboxView());

  static Future<void> openProfile(BuildContext context) =>
      _push(context, const ProfileView());

  static Future<void> openMyInfo(BuildContext context) =>
      _push(context, const MyInfoView());

  static Future<void> openHelp(BuildContext context) =>
      _push(context, const HelpView());

  static Future<void> openPrivacy(BuildContext context) =>
      _push(context, const PrivacyView());

  static Future<void> openReportChange(BuildContext context) =>
      _push(context, const ReportChangeView());

  static Future<void> openFixVisit(
    BuildContext context, {
    required FixVisitArgs args,
  }) =>
      _push(context, FixVisitView(args: args));

  /// Returns `true` when a document was uploaded.
  static Future<bool?> openUpload(
    BuildContext context, {
    String? initialType,
    int? replacesDocumentId,
    bool directDeposit = false,
  }) =>
      _push<bool>(
        context,
        UploadView(
          initialType: initialType,
          replacesDocumentId: replacesDocumentId,
          directDeposit: directDeposit,
        ),
      );

  static Future<void> openPaystub(BuildContext context, {required String id}) =>
      _push(context, PaystubView(paystubId: id));

  /// Returns `true` when the check-in was submitted.
  static Future<bool?> openCheckInFlow(
    BuildContext context, {
    required int formId,
    required String periodLabel,
  }) =>
      _push<bool>(
        context,
        CheckInFlowView(formId: formId, periodLabel: periodLabel),
      );

  // ------------------------------------------------ Document viewer (PDFs)

  /// Paystub PDF (`GET /pay/{id}/stub`). Back returns to the paystub.
  static Future<void> openPaystubPdf(
    BuildContext context, {
    required String id,
    required String periodLabel,
  }) {
    final cubit = context.read<TaskCubit>();
    return _push(
      context,
      DocumentViewerView(
        title: periodLabel.isEmpty ? tr('Paystub') : tr('Paystub · {0}', [periodLabel]),
        fileName: 'Paystub-$id.pdf',
        load: () => cubit.loadPayStubPdf(id),
      ),
    );
  }

  /// W-2, pay schedule or check-in receipt from Docs › From the office
  /// (`GET /documents/office/{id}/download`, 🚧 planned).
  static Future<void> openOfficeDocument(BuildContext context, OfficeDocumentModel document) {
    final cubit = context.read<TaskCubit>();
    final safeName = document.title.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');
    return _push(
      context,
      DocumentViewerView(
        title: document.title,
        fileName: '${safeName.isEmpty ? document.id : safeName}.pdf',
        load: () => cubit.loadOfficeDocumentPdf(document.id),
      ),
    );
  }

  /// Check-in receipt right after signing (`GET /compliance-forms/{id}/receipt`,
  /// 🚧 planned).
  static Future<void> openCheckInReceipt(
    BuildContext context, {
    required int formId,
    required String periodLabel,
  }) {
    final cubit = context.read<TaskCubit>();
    return _push(
      context,
      DocumentViewerView(
        title: tr('{0} check-in', [periodLabel]),
        fileName: 'Check-in-receipt-$formId.pdf',
        load: () => cubit.loadCheckInReceiptPdf(formId),
      ),
    );
  }
}
