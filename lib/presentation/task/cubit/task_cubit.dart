import '../../../core/base/base_cubit.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/pay_stub_file_helper.dart';
import '../../../data/models/task_page_model.dart';
import '../../../data/repositories/task_repository.dart';
import 'task_state.dart';

class TaskCubit extends BaseCubit<TaskState> {
  TaskCubit({required this.repository}) : super(const TaskState());

  final TaskRepository repository;

  Future<void> loadTasks() async {
    emit(state.copyWith(status: TaskStatus.loading, clearError: true));

    try {
      final data = await repository.getTaskPage();
      emit(
        state.copyWith(
          status: TaskStatus.success,
          data: data,
        ),
      );
    } catch (error, stackTrace) {
      logError('Failed to load tasks', error: error, stackTrace: stackTrace);
      emit(
        state.copyWith(
          status: TaskStatus.failure,
          errorMessage: 'Failed to load tasks. Please try again.',
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

  Future<void> downloadAndOpenPayStub(String id) async {
    try {
      final bytes = await repository.downloadPayStub(id);
      await PayStubFileHelper.saveAndOpen(
        bytes: bytes,
        fileName: 'paystub_$id.pdf',
      );
    } on NotFoundException {
      throw PayStubDownloadException('Pay stub is not available.');
    } on ForbiddenException {
      throw PayStubDownloadException('You do not have access to this pay stub.');
    } on ApiException catch (error) {
      throw PayStubDownloadException(
        error.message.isNotEmpty
            ? error.message
            : 'Unable to download pay stub.',
      );
    }
  }
}

class PayStubDownloadException implements Exception {
  PayStubDownloadException(this.message);

  final String message;

  @override
  String toString() => message;
}
