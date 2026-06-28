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

  void clearActionError() {
    emit(state.copyWith(clearError: true));
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
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    final dashboard = state.dashboard;
    if (dashboard == null) return;

    try {
      await visitRepository.clockOut(
        latitude: latitude,
        longitude: longitude,
        notes: notes,
      );

      final dashboard = await repository.getDashboard();

      emit(
        state.copyWith(
          dashboard: dashboard,
          isEndingShift: false,
        ),
      );
    } on ApiException catch (error) {
      emit(state.copyWith(errorMessage: error.message));
    } catch (error, stackTrace) {
      logError('Clock out failed', error: error, stackTrace: stackTrace);
      emit(
        state.copyWith(
          errorMessage: 'Clock out failed. Please try again.',
          isEndingShift: false,
        ),
      );
    }
  }
}
