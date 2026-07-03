import '../api/caregiver_api.dart';
import '../mappers/api_mappers.dart';
import '../models/api/compliance_form_model.dart';
import '../models/api/pay_item_model.dart';
import '../models/selected_document.dart';
import '../models/task_page_model.dart';

abstract class TaskRepository {
  Future<TaskPageData> getTaskPage();
  Future<PayrollSummary> getPayrollSummary();
  Future<PaystubDetail> getPaystubDetail(String id);
  Future<List<int>> downloadPayStub(String id);
  Future<ComplianceFormDetailModel> getComplianceForm(int id);
  Future<ComplianceFormDetailModel> submitComplianceForm({
    required int id,
    required Map<String, bool> answers,
    required String signature,
    String? additionalNotes,
  });
  Future<ComplianceHistoryModel> getComplianceHistory();
  Future<ComplianceHistoryPage> getComplianceHistoryPage();
  Future<void> uploadDocument({
    required SelectedDocument document,
    required String type,
    int? clientId,
    String? notes,
  });
}

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl({required CaregiverApi api}) : _api = api;

  final CaregiverApi _api;

  @override
  Future<TaskPageData> getTaskPage() async {
    final payFuture = getPayrollSummary();
    final visitFuture = _api.getVisits();
    final complianceFuture = _api.getComplianceForms();
    final documentsFuture = _api.getDocuments();
    final historyFuture = _api.getComplianceHistory();

    final payroll = await payFuture;
    final visitResponse = await visitFuture;
    final complianceResponse = await complianceFuture;
    final documentsResponse = await documentsFuture;
    final history = await historyFuture;

    final visitTasks = visitResponse.data.map(visitToTaskItem).toList();
    final complianceTasks =
        complianceResponse.data.map(complianceFormToTaskItem).toList();
    final documentTasks =
        documentsResponse.data.map(documentToTaskItem).toList();

    final allTasks = [...complianceTasks, ...documentTasks, ...visitTasks];
    final pendingCompliance = complianceResponse.data
        .where((form) => !form.submitted)
        .toList();
    final monthlyQuestions = pendingCompliance.isNotEmpty
        ? (await getComplianceForm(pendingCompliance.first.id))
            .questions
            .map(complianceQuestionToUi)
            .toList()
        : <ComplianceQuestion>[];

    return TaskPageData(
      pendingCount: allTasks
          .where(
            (task) =>
                task.status == TaskItemStatus.pending ||
                task.status == TaskItemStatus.overdue,
          )
          .length,
      allTasks: allTasks,
      visitTasks: visitTasks,
      clientTasks: const ClientTasksData(
        clientName: '',
        completedCount: 0,
        totalCount: 0,
        progressPercent: 0,
        complianceTitle: '',
        complianceSubtitle: '',
        careTasks: [],
      ),
      complianceQuestions: monthlyQuestions,
      monthlyComplianceQuestions: monthlyQuestions,
      complianceHistorySummary: _mapComplianceHistory(history).summary,
      complianceHistory: _mapComplianceHistory(history).records,
      payroll: payroll,
    );
  }

  ComplianceHistoryPage _mapComplianceHistory(ComplianceHistoryModel history) {
    return ComplianceHistoryPage(
      summary: ComplianceHistorySummary(
        submittedCount: history.summary.submitted,
        overdueCount: history.summary.overdue,
        onTimePercent: history.summary.onTimePct,
      ),
      records: history.records.map(_mapComplianceHistoryRecord).toList(),
    );
  }

  ComplianceHistoryRecord _mapComplianceHistoryRecord(
    ComplianceHistoryRecordModel record,
  ) {
    return ComplianceHistoryRecord(
      id: record.id.toString(),
      periodLabel: record.periodLabel,
      submittedLabel:
          record.submittedAt != null ? 'Submitted' : record.status,
      isSubmitted: record.status == 'Submitted',
      hasAttachment: record.status == 'Submitted',
    );
  }

  @override
  Future<ComplianceHistoryPage> getComplianceHistoryPage() async {
    final history = await _api.getComplianceHistory();
    return _mapComplianceHistory(history);
  }

  @override
  Future<PayrollSummary> getPayrollSummary() async {
    final earningsFuture = _api.getEarningsSummary();
    final payFuture = _api.getPay();
    final earnings = await earningsFuture;
    final payResponse = await payFuture;
    return earningsSummaryToPayrollSummary(earnings, payResponse.data);
  }

  @override
  Future<PaystubDetail> getPaystubDetail(String id) async {
    final detail = await _api.getPayDetail(int.parse(id));
    return payDetailToPaystubDetail(detail);
  }

  @override
  Future<List<int>> downloadPayStub(String id) {
    return _api.downloadPayStub(int.parse(id));
  }

  @override
  Future<ComplianceFormDetailModel> getComplianceForm(int id) {
    return _api.getComplianceForm(id);
  }

  @override
  Future<ComplianceFormDetailModel> submitComplianceForm({
    required int id,
    required Map<String, bool> answers,
    required String signature,
    String? additionalNotes,
  }) {
    return _api.submitComplianceForm(
      id: id,
      answers: answers,
      signature: signature,
      additionalNotes: additionalNotes,
    );
  }

  @override
  Future<ComplianceHistoryModel> getComplianceHistory() {
    return _api.getComplianceHistory();
  }

  @override
  Future<void> uploadDocument({
    required SelectedDocument document,
    required String type,
    int? clientId,
    String? notes,
  }) async {
    final path = document.filePath;
    if (path == null) {
      throw StateError('Document file path is required for upload.');
    }

    await _api.uploadDocument(
      filePath: path,
      fileName: document.fileName,
      type: type,
      clientId: clientId,
      notes: notes,
      mimeType: document.mimeType,
    );
  }
}
