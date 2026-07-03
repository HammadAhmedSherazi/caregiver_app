import '../../../core/base/base_cubit.dart';
import '../../../core/network/api_exception.dart';
import '../../../data/models/home_dashboard_model.dart';
import '../../../data/repositories/home_repository.dart';
import '../../../data/repositories/visit_repository.dart';
import 'home_state.dart';

class HomeCubit extends BaseCubit<HomeState> {
  HomeCubit({
    required this.repository,
    required this.visitRepository,
  }) : super(const HomeState());

  final HomeRepository repository;
  final VisitRepository visitRepository;

  Future<void> loadDashboard() async {
    emit(state.copyWith(status: HomeStatus.loading, clearError: true));

    try {
      final dashboard = await repository.getDashboard();
      emit(
        state.copyWith(
          status: HomeStatus.success,
          dashboard: dashboard,
          isEndingShift: (dashboard.activeShift?.isInProgress ?? false)
              ? state.isEndingShift
              : false,
        ),
      );
    } catch (error, stackTrace) {
      logError('Failed to load dashboard', error: error, stackTrace: stackTrace);
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: 'Failed to load dashboard. Please try again.',
        ),
      );
    }
  }

  Future<void> refresh() => loadDashboard();

  void reset() {
    emit(const HomeState());
  }

  void clearActionError() {
    emit(state.copyWith(clearError: true, clearInfo: true));
  }

  Future<void> completeClockIn({
    required String clientName,
    required String serviceType,
    int? clientId,
    int? scheduleId,
    double? latitude,
    double? longitude,
  }) async {
    final dashboard = state.dashboard;
    final currentShift = dashboard?.activeShift;
    if (dashboard == null || currentShift == null) return;

    try {
      final visit = await visitRepository.clockIn(
        clientId: clientId,
        scheduleId: scheduleId,
        latitude: latitude,
        longitude: longitude,
      );

      final shift = currentShift.copyWith(
        clientName: visit.clientName,
        serviceType: serviceType,
        status: ShiftStatus.inProgress,
        startedAtLabel: 'Started now · $serviceType',
        shiftStartedAt: visit.clockInAt,
      );

      emit(
        state.copyWith(
          dashboard: dashboard.copyWith(activeShift: shift),
        ),
      );
    } on ApiException catch (error) {
      emit(state.copyWith(errorMessage: error.message));
    } catch (error, stackTrace) {
      logError('Clock in failed', error: error, stackTrace: stackTrace);
      emit(
        state.copyWith(
          errorMessage: 'Clock in failed. Please try again.',
        ),
      );
    }
  }

  void beginEndShift() {
    emit(state.copyWith(isEndingShift: true));
  }

  void cancelEndShift() {
    emit(state.copyWith(isEndingShift: false));
  }

  Future<void> endShift({
    int? visitId,
    int? scheduleId,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    final dashboard = state.dashboard;
    if (dashboard == null || state.isClockingOut) return;

    emit(state.copyWith(isClockingOut: true, clearError: true, clearInfo: true));

    try {
      await visitRepository.clockOut(
        scheduleId: scheduleId,
        latitude: latitude,
        longitude: longitude,
        notes: notes,
      );

      final refreshed = await repository.getDashboard();
      final stillOpen = refreshed.activeShift?.isInProgress ?? false;
      final anotherVisit =
          stillOpen && refreshed.activeShift?.visitId != visitId;

      emit(
        state.copyWith(
          dashboard: refreshed,
          isEndingShift: false,
          isClockingOut: false,
          infoMessage: anotherVisit
              ? 'Clock-out saved. Another open visit for ${refreshed.activeShift!.clientName} still needs to be ended.'
              : null,
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          errorMessage: error.message,
          isClockingOut: false,
        ),
      );
    } catch (error, stackTrace) {
      logError('Clock out failed', error: error, stackTrace: stackTrace);
      emit(
        state.copyWith(
          errorMessage: 'Clock out failed. Please try again.',
          isEndingShift: false,
          isClockingOut: false,
        ),
      );
    }
  }

  Future<void> toggleCareTask(int taskId) async {
    final dashboard = state.dashboard;
    final shift = dashboard?.activeShift;
    final scheduleId = shift?.scheduleId;
    if (dashboard == null || shift == null || scheduleId == null) return;

    try {
      final updated = await visitRepository.toggleTask(
        scheduleId: scheduleId,
        taskId: taskId,
      );
      final tasks = shift.careTasks
          .map(
            (task) => task.id == taskId
                ? task.copyWith(isCompleted: updated.isCompleted)
                : task,
          )
          .toList();

      emit(
        state.copyWith(
          dashboard: dashboard.copyWith(
            activeShift: shift.copyWith(careTasks: tasks),
          ),
        ),
      );
    } on ApiException catch (error) {
      emit(state.copyWith(errorMessage: error.message));
    } catch (error, stackTrace) {
      logError('Task toggle failed', error: error, stackTrace: stackTrace);
      emit(state.copyWith(errorMessage: 'Unable to update task.'));
    }
  }
}
