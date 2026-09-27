import 'package:equatable/equatable.dart';

import '../../../core/base/base_cubit.dart';
import '../../../data/models/api/compliance_form_model.dart';
import '../../../data/repositories/task_repository.dart';

enum CheckInStatus { initial, loading, success, failure }

class CheckInState extends Equatable {
  const CheckInState({
    this.status = CheckInStatus.initial,
    this.forms = const [],
    this.history = const [],
    this.errorMessage,
  });

  final CheckInStatus status;
  final List<ComplianceFormListItemModel> forms;
  final List<ComplianceHistoryRecordModel> history;
  final String? errorMessage;

  bool get isLoading => status == CheckInStatus.loading;
  bool get hasError => status == CheckInStatus.failure;

  /// Open check-ins, overdue first.
  List<ComplianceFormListItemModel> get pending {
    final open = forms.where((f) => !f.submitted).toList()
      ..sort((a, b) {
        if (a.isOverdue != b.isOverdue) return a.isOverdue ? -1 : 1;
        return a.period.compareTo(b.period);
      });
    return open;
  }

  CheckInState copyWith({
    CheckInStatus? status,
    List<ComplianceFormListItemModel>? forms,
    List<ComplianceHistoryRecordModel>? history,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CheckInState(
      status: status ?? this.status,
      forms: forms ?? this.forms,
      history: history ?? this.history,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, forms, history, errorMessage];
}

/// Monthly check-ins (compliance forms): `GET /compliance-forms` and
/// `GET /compliance-forms/history`.
class CheckInCubit extends BaseCubit<CheckInState> {
  CheckInCubit({required this.repository}) : super(const CheckInState());

  final TaskRepository repository;
  int _generation = 0;

  void reset() {
    _generation++;
    emit(const CheckInState());
  }

  Future<void> load() async {
    final generation = _generation;
    final hasData = state.status == CheckInStatus.success;
    if (!hasData) {
      emit(state.copyWith(status: CheckInStatus.loading, clearError: true));
    }

    try {
      final formsFuture = repository.getComplianceForms();
      final historyFuture = repository.getComplianceHistory();
      final forms = await formsFuture;
      final history = await historyFuture;
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: CheckInStatus.success,
          forms: forms,
          history: history.records,
          clearError: true,
        ),
      );
    } catch (error, stackTrace) {
      logError('Failed to load check-ins', error: error, stackTrace: stackTrace);
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: hasData ? CheckInStatus.success : CheckInStatus.failure,
          errorMessage: 'Failed to load your check-ins. Please try again.',
        ),
      );
    }
  }
}
