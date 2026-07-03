import '../../../core/base/base_cubit.dart';
import '../../../data/models/schedule_page_model.dart';
import '../../../data/repositories/schedule_repository.dart';
import 'schedule_state.dart';

class ScheduleCubit extends BaseCubit<ScheduleState> {
  ScheduleCubit({required this.repository}) : super(const ScheduleState());

  final ScheduleRepository repository;

  void setViewMode(ScheduleViewMode mode) {
    final data = state.data;
    if (data == null) return;

    loadSchedule(
      selectedDate: data.selectedDate,
      viewMode: mode,
    );
  }

  Future<void> loadSchedule({
    DateTime? selectedDate,
    ScheduleViewMode? viewMode,
  }) async {
    emit(state.copyWith(status: ScheduleStatus.loading, clearError: true));

    try {
      final currentMode = viewMode ?? state.data?.viewMode ?? ScheduleViewMode.day;
      final data = await repository.getSchedulePage(
        selectedDate: selectedDate,
        viewMode: currentMode,
      );
      emit(
        state.copyWith(
          status: ScheduleStatus.success,
          data: data,
        ),
      );
    } catch (error, stackTrace) {
      logError('Failed to load schedule', error: error, stackTrace: stackTrace);
      emit(
        state.copyWith(
          status: ScheduleStatus.failure,
          errorMessage: 'Failed to load schedule. Please try again.',
        ),
      );
    }
  }

  Future<void> selectDate(DateTime date) => loadSchedule(selectedDate: date);
}
