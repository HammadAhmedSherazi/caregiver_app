import 'package:equatable/equatable.dart';

import '../../../core/base/base_cubit.dart';
import '../../../core/network/api_config.dart';
import '../../../data/models/api/velora/velora_models.dart';
import '../../../data/models/api/schedule_item_model.dart';
import '../../../data/models/api/visit_model.dart';
import '../../../data/repositories/visit_repository.dart';
import '../../../core/i18n/tr.dart';

enum TimeStatus { initial, loading, success, failure }

class TimeState extends Equatable {
  const TimeState({
    this.status = TimeStatus.initial,
    this.visits = const [],
    this.upcoming = const [],
    this.week,
    this.month,
    this.errorMessage,
  });

  final TimeStatus status;
  final List<VisitModel> visits;
  final List<ScheduleItemModel> upcoming;

  /// 🚧 Planned `GET /time/week` (work plan, set days, missed days).
  final TimeWeekModel? week;

  /// 🚧 Planned `GET /time/month` (approved hours).
  final TimeMonthModel? month;
  final String? errorMessage;

  bool get isLoading => status == TimeStatus.loading;
  bool get hasError => status == TimeStatus.failure;

  TimeState copyWith({
    TimeStatus? status,
    List<VisitModel>? visits,
    List<ScheduleItemModel>? upcoming,
    TimeWeekModel? week,
    TimeMonthModel? month,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TimeState(
      status: status ?? this.status,
      visits: visits ?? this.visits,
      upcoming: upcoming ?? this.upcoming,
      week: week ?? this.week,
      month: month ?? this.month,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, visits, upcoming, week, month, errorMessage];
}

/// Visit history (`GET /visits`) and upcoming schedule (`GET /schedule`)
/// for the Time tab.
class TimeCubit extends BaseCubit<TimeState> {
  TimeCubit({required this.repository}) : super(const TimeState());

  final VisitRepository repository;

  /// Clears cached data (called on sign-out).
  void reset() {
    _generation++;
    emit(const TimeState());
  }

  int _generation = 0;

  Future<void> load() async {
    final generation = _generation;
    final hasData = state.status == TimeStatus.success;
    if (!hasData) {
      emit(state.copyWith(status: TimeStatus.loading, clearError: true));
    }

    try {
      final upcomingFuture = repository
          .getUpcomingSchedule()
          .catchError((Object _) => const <ScheduleItemModel>[]);
      // The planned summaries only add to the live visit list; if they fail
      // the tab shows what `/visits` gives.
      final weekFuture = ApiConfig.veloraApiEnabled
          ? repository.getTimeWeek().then<TimeWeekModel?>((w) => w).catchError((Object _) => null)
          : Future<TimeWeekModel?>.value();
      final monthFuture = ApiConfig.veloraApiEnabled
          ? repository.getTimeMonth().then<TimeMonthModel?>((m) => m).catchError((Object _) => null)
          : Future<TimeMonthModel?>.value();
      final visits = await repository.getVisitHistory(perPage: 100);
      final upcoming = await upcomingFuture;
      final week = await weekFuture;
      final month = await monthFuture;
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: TimeStatus.success,
          visits: visits,
          upcoming: upcoming,
          week: week,
          month: month,
          clearError: true,
        ),
      );
    } catch (error, stackTrace) {
      logError('Failed to load visits', error: error, stackTrace: stackTrace);
      if (generation != _generation) return;
      emit(
        state.copyWith(
          status: hasData ? TimeStatus.success : TimeStatus.failure,
          errorMessage: tr('Failed to load your visits. Please try again.'),
        ),
      );
    }
  }
}
