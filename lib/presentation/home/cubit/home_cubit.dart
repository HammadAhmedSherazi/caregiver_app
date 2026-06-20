import '../../../core/base/base_cubit.dart';
import '../../../data/models/home_dashboard_model.dart';
import '../../../data/repositories/home_repository.dart';
import 'home_state.dart';

class HomeCubit extends BaseCubit<HomeState> {
  HomeCubit({required this.repository}) : super(const HomeState());

  final HomeRepository repository;

  Future<void> loadDashboard() async {
    emit(state.copyWith(status: HomeStatus.loading, errorMessage: null));

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

  void completeClockIn({
    required String clientName,
    required String serviceType,
  }) {
    final dashboard = state.dashboard;
    if (dashboard == null) return;

    final shift = dashboard.activeShift.copyWith(
      clientName: clientName,
      serviceType: serviceType,
      status: ShiftStatus.inProgress,
      startedAtLabel: 'Started 9:00 AM · $serviceType',
      shiftStartedAt: DateTime.now(),
    );

    emit(
      state.copyWith(
        dashboard: dashboard.copyWith(activeShift: shift),
      ),
    );
  }

  void beginEndShift() {
    emit(state.copyWith(isEndingShift: true));
  }

  void cancelEndShift() {
    emit(state.copyWith(isEndingShift: false));
  }

  void endShift() {
    final dashboard = state.dashboard;
    if (dashboard == null) return;

    final shift = dashboard.activeShift.copyWith(
      status: ShiftStatus.pending,
      shiftStartedAt: null,
    );

    emit(
      state.copyWith(
        dashboard: dashboard.copyWith(activeShift: shift),
        isEndingShift: false,
      ),
    );
  }
}
