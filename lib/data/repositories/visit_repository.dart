import '../api/caregiver_api.dart';
import '../models/api/schedule_item_model.dart';
import '../models/api/visit_model.dart';
import '../models/api/visit_task_model.dart';
import '../api/velora_api.dart';
import '../models/api/velora/velora_models.dart';
import '../local/language_store.dart';

abstract class VisitRepository {
  Future<VisitModel?> getActiveVisit();

  /// Recent visits (`GET /visits`), newest first as returned by the API.
  Future<List<VisitModel>> getVisitHistory({int perPage = 50});

  /// Upcoming scheduled visits (`GET /schedule?upcoming=1`).
  Future<List<ScheduleItemModel>> getUpcomingSchedule({int perPage = 20});
  Future<VisitModel> clockIn({
    int? clientId,
    int? scheduleId,
    double? latitude,
    double? longitude,
  });
  Future<VisitModel> clockOut({
    int? scheduleId,
    double? latitude,
    double? longitude,
    String? notes,
    ClockOutAnswers? answers,
  });

  // 🚧 PLANNED — NOT LIVE (MOBILE_API_VELORA.md). Throw ApiNotLiveException
  // while ApiConfig.veloraApiEnabled is false.

  /// `GET /time/week`.
  Future<TimeWeekModel> getTimeWeek({DateTime? date});

  /// `GET /time/month` (`YYYY-MM`).
  Future<TimeMonthModel> getTimeMonth({String? month});

  /// `GET /visits/{schedule}`.
  Future<VisitDetailModel> getVisitDetail(int scheduleId);

  /// 🚧 Planned. `GET /services/catalog` — cached per language (labels
  /// follow `Accept-Language`).
  Future<ServiceCatalogModel> getServiceCatalog({bool refresh = false});

  /// `POST /visits/{schedule}/fix-clockout`.
  Future<FixClockoutResultModel> fixClockout(int scheduleId, FixClockoutRequest request);
  Future<List<VisitTaskModel>> getTasks(int scheduleId);
  Future<VisitTaskModel> toggleTask({
    required int scheduleId,
    required int taskId,
    bool? isCompleted,
  });
}

class VisitRepositoryImpl implements VisitRepository {
  VisitRepositoryImpl({required this._api, required this._velora, this._languageStore});

  final CaregiverApi _api;
  final VeloraApi _velora;
  final LanguageStore? _languageStore;
  ServiceCatalogModel? _catalog;
  String? _catalogLanguage;

  @override
  Future<VisitModel?> getActiveVisit() => _api.getActiveVisit();

  @override
  Future<List<VisitModel>> getVisitHistory({int perPage = 50}) async {
    final response = await _api.getVisits(perPage: perPage);
    return response.data;
  }

  @override
  Future<List<ScheduleItemModel>> getUpcomingSchedule({int perPage = 20}) async {
    final response = await _api.getSchedule(upcoming: true, perPage: perPage);
    return response.data;
  }

  @override
  Future<VisitModel> clockIn({
    int? clientId,
    int? scheduleId,
    double? latitude,
    double? longitude,
  }) {
    return _api.clockIn(
      clientId: clientId,
      scheduleId: scheduleId,
      latitude: latitude,
      longitude: longitude,
    );
  }

  @override
  Future<VisitModel> clockOut({
    int? scheduleId,
    double? latitude,
    double? longitude,
    String? notes,
    ClockOutAnswers? answers,
  }) {
    return _api.clockOut(
      scheduleId: scheduleId,
      latitude: latitude,
      longitude: longitude,
      notes: notes,
      answers: answers,
    );
  }

  @override
  Future<TimeWeekModel> getTimeWeek({DateTime? date}) => _velora.getTimeWeek(date: date);

  @override
  Future<TimeMonthModel> getTimeMonth({String? month}) => _velora.getTimeMonth(month: month);

  @override
  Future<VisitDetailModel> getVisitDetail(int scheduleId) => _velora.getVisitDetail(scheduleId);

  @override
  Future<ServiceCatalogModel> getServiceCatalog({bool refresh = false}) async {
    final language = _languageStore?.current;
    final cached = _catalog;
    if (cached != null && !refresh && _catalogLanguage == language) return cached;
    final catalog = await _velora.getServiceCatalog();
    _catalogLanguage = language;
    return _catalog = catalog;
  }

  @override
  Future<FixClockoutResultModel> fixClockout(int scheduleId, FixClockoutRequest request) {
    return _velora.fixClockout(scheduleId, request);
  }

  @override
  Future<List<VisitTaskModel>> getTasks(int scheduleId) {
    return _api.getVisitTasks(scheduleId);
  }

  @override
  Future<VisitTaskModel> toggleTask({
    required int scheduleId,
    required int taskId,
    bool? isCompleted,
  }) {
    return _api.toggleVisitTask(
      scheduleId: scheduleId,
      taskId: taskId,
      isCompleted: isCompleted,
    );
  }
}
