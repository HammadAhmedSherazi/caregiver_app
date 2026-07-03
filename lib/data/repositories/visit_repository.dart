import '../api/caregiver_api.dart';
import '../mappers/api_mappers.dart';
import '../models/api/visit_model.dart';
import '../models/api/visit_task_model.dart';

abstract class VisitRepository {
  Future<VisitModel?> getActiveVisit();
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
  });
  Future<List<VisitTaskModel>> getTasks(int scheduleId);
  Future<VisitTaskModel> toggleTask({
    required int scheduleId,
    required int taskId,
    bool? isCompleted,
  });
}

class VisitRepositoryImpl implements VisitRepository {
  VisitRepositoryImpl({required CaregiverApi api}) : _api = api;

  final CaregiverApi _api;

  @override
  Future<VisitModel?> getActiveVisit() => _api.getActiveVisit();

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
  }) {
    return _api.clockOut(
      scheduleId: scheduleId,
      latitude: latitude,
      longitude: longitude,
      notes: notes,
    );
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
