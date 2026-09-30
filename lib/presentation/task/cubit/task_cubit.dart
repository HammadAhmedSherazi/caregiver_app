import 'dart:typed_data';

import '../../../core/base/base_cubit.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/api/compliance_form_model.dart';
import '../../../data/models/api/velora/velora_models.dart';
import '../../../data/models/selected_document.dart';
import '../../../data/models/task_page_model.dart';
import '../../../data/repositories/task_repository.dart';
import 'task_state.dart';
import '../../../core/i18n/tr.dart';

class TaskCubit extends BaseCubit<TaskState> {
  TaskCubit({required this.repository}) : super(const TaskState());

  final TaskRepository repository;

  /// Clears cached data (called on sign-out).
  void reset() {
    _generation++;
    _inFlight = null;
    emit(const TaskState());
  }

  int _generation = 0;

  Future<void>? _inFlight;

  /// Loads the task page (compliance forms, payroll, history, …).
  ///
  /// Several tabs (Home, Check-in, Pay) read this data, so concurrent calls
  /// share one request and a refresh keeps the previous data on screen.
  Future<void> loadTasks() {
    return _inFlight ??= _loadTasks().whenComplete(() => _inFlight = null);
  }

  Future<void> _loadTasks() async {
    final generation = _generation;
    final hasData = state.data != null;
    if (!hasData) {
      emit(state.copyWith(status: TaskStatus.loading, clearError: true));
    }

    try {
      final data = await repository.getTaskPage();
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: TaskStatus.success,
          data: data,
          clearError: true,
        ),
      );
    } catch (error, stackTrace) {
      logError('Failed to load tasks', error: error, stackTrace: stackTrace);
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: hasData ? TaskStatus.success : TaskStatus.failure,
          errorMessage: tr('Failed to load tasks. Please try again.'),
        ),
      );
    }
  }

  void setFilter(TaskFilter filter) {
    emit(state.copyWith(filter: filter));
  }

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  Future<PaystubDetail> getPaystubDetail(String id) {
    return repository.getPaystubDetail(id);
  }

  Future<PayrollSummary> loadPayrollSummary() {
    return repository.getPayrollSummary();
  }

  Future<ComplianceHistoryPage> loadComplianceHistory() {
    return repository.getComplianceHistoryPage();
  }

  /// Full `GET /compliance-forms/{id}`, including the planned `check_in`
  /// block (prefill, days, counts) that drives the "Your days" step.
  Future<ComplianceFormDetailModel> loadComplianceDetail(int id) {
    return repository.getComplianceForm(id);
  }

  /// 🚧 Planned. `PUT /compliance-forms/{id}/draft` ("Save & exit").
  Future<void> saveCheckInDraft(int formId, CheckInDraftRequest request) async {
    await repository.saveCheckInDraft(formId, request);
  }

  /// 🚧 Planned. `POST /compliance-forms/{id}/submit` with the typed name.
  Future<ComplianceFormDetailModel> submitCheckIn(int formId, CheckInSubmitRequest request) {
    request.validate();
    return repository.submitCheckIn(formId, request);
  }

  Future<void> submitComplianceForm({
    required int formId,
    required Map<String, bool> answers,
    required String signature,
    String? additionalNotes,
  }) async {
    await repository.submitComplianceForm(
      id: formId,
      answers: answers,
      signature: signature,
      additionalNotes: additionalNotes,
    );
  }

  Future<void> uploadDocument({
    required SelectedDocument document,
    required String type,
    int? clientId,
    String? notes,
    DocumentUploadExtras? extras,
  }) async {
    await repository.uploadDocument(
      document: document,
      type: type,
      clientId: clientId,
      notes: notes,
      extras: extras,
    );
  }

  /// PDF bytes for the document viewer: `GET /pay/{id}/stub` (live).
  Future<Uint8List> loadPayStubPdf(String id) => _loadPdf(
        () => repository.downloadPayStub(id),
        notFound: tr('Pay stub is not available.'),
        forbidden: tr('You do not have access to this pay stub.'),
        fallback: tr('Unable to download pay stub.'),
      );

  /// 🚧 Planned. `GET /documents/office/{id}/download` (W-2, pay schedule,
  /// check-in receipt listed in Docs › From the office).
  Future<Uint8List> loadOfficeDocumentPdf(String id) => _loadPdf(
        () => repository.downloadOfficeDocument(id),
        notFound: tr('This document is no longer available.'),
        forbidden: tr('You do not have access to this document.'),
        fallback: tr('Unable to download this document.'),
      );

  /// 🚧 Planned. `GET /compliance-forms/{id}/receipt` (404 until submitted).
  Future<Uint8List> loadCheckInReceiptPdf(int formId) => _loadPdf(
        () => repository.downloadCheckInReceipt(formId),
        notFound: tr('The receipt is ready once your check-in is sent.'),
        forbidden: tr('You do not have access to this receipt.'),
        fallback: tr('Unable to download the receipt.'),
      );

  Future<Uint8List> _loadPdf(
    Future<List<int>> Function() download, {
    required String notFound,
    required String forbidden,
    required String fallback,
  }) async {
    try {
      return Uint8List.fromList(await download());
    } on ApiNotLiveException {
      throw DocumentDownloadException(
        tr('This document can\'t be opened from the app yet. Please message the office for a copy.'),
        notLive: true,
      );
    } on NotFoundException {
      throw DocumentDownloadException(notFound);
    } on ForbiddenException {
      throw DocumentDownloadException(forbidden);
    } on ApiException catch (error) {
      throw DocumentDownloadException(error.message.isNotEmpty ? error.message : fallback);
    }
  }
}

/// A PDF for the document viewer could not be loaded.
class DocumentDownloadException implements Exception {
  DocumentDownloadException(this.message, {this.notLive = false});

  final String message;

  /// The endpoint is 🚧 planned and `VELORA_API` is off.
  final bool notLive;

  @override
  String toString() => message;
}
