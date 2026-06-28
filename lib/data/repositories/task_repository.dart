import '../api/caregiver_api.dart';
import '../mappers/api_mappers.dart';
import '../models/api/pay_item_model.dart';
import '../models/task_page_model.dart';

abstract class TaskRepository {
  Future<TaskPageData> getTaskPage();
  Future<PayrollSummary> getPayrollSummary();
  Future<PaystubDetail> getPaystubDetail(String id);
  Future<List<int>> downloadPayStub(String id);
}

class TaskRepositoryImpl implements TaskRepository {
  TaskRepositoryImpl({required CaregiverApi api}) : _api = api;

  final CaregiverApi _api;
  List<PayItemModel>? _cachedPayItems;

  @override
  Future<TaskPageData> getTaskPage() async {
    final payFuture = getPayrollSummary();
    final visitFuture = _api.getVisits();

    final payroll = await payFuture;
    final visitResponse = await visitFuture;
    final visitTasks = visitResponse.data.map(visitToTaskItem).toList();

    return TaskPageData(
      pendingCount: visitTasks.where((v) => v.status == TaskItemStatus.pending).length,
      allTasks: visitTasks,
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
      complianceQuestions: const [],
      monthlyComplianceQuestions: const [],
      complianceHistorySummary: const ComplianceHistorySummary(
        submittedCount: 0,
        overdueCount: 0,
        onTimePercent: 0,
      ),
      complianceHistory: const [],
      payroll: payroll,
    );
  }

  @override
  Future<PayrollSummary> getPayrollSummary() async {
    final payResponse = await _api.getPay();
    _cachedPayItems = payResponse.data;
    return _buildPayrollSummary(payResponse.data);
  }

  @override
  Future<PaystubDetail> getPaystubDetail(String id) async {
    final items = _cachedPayItems ?? (await _api.getPay()).data;
    final match = items.where((item) => item.id.toString() == id).firstOrNull;
    if (match == null) {
      throw StateError('Pay stub not found');
    }
    return payItemToPaystubDetail(match);
  }

  @override
  Future<List<int>> downloadPayStub(String id) {
    return _api.downloadPayStub(int.parse(id));
  }

  PayrollSummary _buildPayrollSummary(List<PayItemModel> items) {
    final now = DateTime.now();
    final yearItems = items.where((item) {
      final parts = item.periodKey.split('-');
      if (parts.length != 2) return true;
      return int.tryParse(parts.first) == now.year;
    }).toList();

    final totalHours =
        yearItems.fold<double>(0, (sum, item) => sum + item.hours);
    final totalGross =
        yearItems.fold<double>(0, (sum, item) => sum + item.gross);

    final paidCount = yearItems.where((item) => item.status == 'Paid').length;

    return PayrollSummary(
      year: now.year,
      yearToDateAmount: formatCurrency(totalGross),
      hoursLabel:
          '${totalHours.toStringAsFixed(1)} hours · ${yearItems.length} paystubs',
      paystubCount: yearItems.length,
      quickbooksStatus: yearItems.isEmpty
          ? 'No paystubs yet'
          : '$paidCount paid · ${yearItems.length} periods',
      gustoStatus: yearItems.isEmpty ? '—' : yearItems.first.program,
      paystubs: yearItems.map(payItemToPaystub).toList(),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
