import '../api/caregiver_api.dart';
import '../mappers/api_mappers.dart';
import '../models/home_dashboard_model.dart';

abstract class HomeRepository {
  Future<HomeDashboard> getDashboard();
}

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl({required this._api});

  final CaregiverApi _api;

  @override
  Future<HomeDashboard> getDashboard() async {
    final dashboardFuture = _api.getDashboard();
    final assignmentsFuture = _api.getAssignments();

    final dashboard = await dashboardFuture;
    final assignments = await assignmentsFuture;

    var careTasks = <CareTaskItem>[];
    final scheduleId = dashboard.activeVisit?.scheduleId ??
        dashboard.activeVisit?.id ??
        dashboard.nextShift?.visit.id;

    if (scheduleId != null) {
      try {
        final tasks = await _api.getVisitTasks(scheduleId);
        careTasks = tasks.map(visitTaskToCareTaskItem).toList();
      } catch (_) {
        careTasks = const [];
      }
    }

    return dashboardToHomeDashboard(
      dashboard: dashboard,
      assignments: assignments,
      careTasks: careTasks,
    );
  }
}
