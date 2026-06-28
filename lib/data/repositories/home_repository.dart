import '../api/caregiver_api.dart';
import '../mappers/api_mappers.dart';
import '../models/api/assignment_model.dart';
import '../models/api/schedule_item_model.dart';
import '../models/api/visit_model.dart';
import '../models/home_dashboard_model.dart';

abstract class HomeRepository {
  Future<HomeDashboard> getDashboard();
}

class HomeRepositoryImpl implements HomeRepository {
  HomeRepositoryImpl({required CaregiverApi api}) : _api = api;

  final CaregiverApi _api;

  @override
  Future<HomeDashboard> getDashboard() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayQuery = _formatQueryDate(today);

    final profileFuture = _api.getMe();
    final assignmentsFuture = _api.getAssignments();
    final activeVisitFuture = _api.getActiveVisit();
    final todayScheduleFuture = _api.getSchedule(
      from: todayQuery,
      to: todayQuery,
      upcoming: false,
    );
    final upcomingScheduleFuture = _api.getSchedule(upcoming: true);

    final profile = await profileFuture;
    final assignments = await assignmentsFuture;
    final activeVisit = await activeVisitFuture;
    final todaySchedule = await todayScheduleFuture;
    final upcomingSchedule = await upcomingScheduleFuture;

    final assignedVisits = assignments
        .map(
          (assignment) => assignmentToAssignedVisit(
            assignment,
            scheduleLabel: assignment.authorization.label,
          ),
        )
        .toList();

    final todayItems = todaySchedule.data;
    final scheduleItems =
        todayItems.isNotEmpty ? todayItems : upcomingSchedule.data;
    final nextShift = _pickNextShift(scheduleItems, now);
    final activeShift = _buildActiveShift(
      activeVisit: activeVisit,
      nextShift: nextShift,
      assignments: assignments,
      assignedVisits: assignedVisits,
      now: now,
    );

    final scheduleEntries = todayItems
        .take(4)
        .map(scheduleItemToScheduleEntry)
        .toList();

    final pendingSource =
        todayItems.isNotEmpty ? todayItems : upcomingSchedule.data;

    return HomeDashboard(
      caregiverName: profile.name.split(' ').first,
      dateLabel: formatDateLabel(now),
      activeShift: activeShift,
      schedule: scheduleEntries,
      taskSummary: TaskSummary(
        completedTasks: 0,
        totalTasks: pendingSource.length,
        remainingHours: '${pendingSource.length} shifts',
      ),
      pendingTasks: pendingSource
          .take(3)
          .map(
            (item) => PendingTask(
              timeLabel: formatTimeLabel(item.scheduledStart),
              title: item.clientName,
            ),
          )
          .toList(),
    );
  }

  ActiveShift? _buildActiveShift({
    required VisitModel? activeVisit,
    required ScheduleItemModel? nextShift,
    required List<AssignmentModel> assignments,
    required List<AssignedVisit> assignedVisits,
    required DateTime now,
  }) {
    if (activeVisit == null && nextShift == null) {
      return null;
    }

    final clientId = activeVisit?.clientId ?? nextShift!.clientId;
    final matchingAssignment = _findAssignment(assignments, clientId);

    final clientName =
        activeVisit?.clientName ?? nextShift?.clientName ?? 'Client';
    final address = nextShift?.address ??
        matchingAssignment?.address ??
        'Address unavailable';

    final shiftStatus = activeVisit != null
        ? ShiftStatus.inProgress
        : ShiftStatus.pending;

    final shiftStartedAt = activeVisit?.clockInAt;
    final startedAtLabel = shiftStartedAt != null
        ? 'Started ${formatTimeLabel(shiftStartedAt)}'
        : null;

    var timeRange = 'No upcoming shift';
    var scheduledTimeDisplay = '—';
    var visitDateTime = formatDateLabel(now);
    var visitDate = formatDateLabel(now);
    var minutesUntilStart = 0;
    var progress = 0.0;

    if (nextShift != null) {
      scheduledTimeDisplay =
          '${formatTimeLabel(nextShift.scheduledStart)} – ${formatTimeLabel(nextShift.scheduledEnd)}';
      timeRange = scheduledTimeDisplay;
      visitDateTime =
          '${formatDateLabel(nextShift.scheduledStart)} · ${formatTimeLabel(nextShift.scheduledStart)}';
      visitDate = formatDateLabel(nextShift.scheduledStart);
      final minutesUntil = nextShift.scheduledStart.difference(now).inMinutes;
      minutesUntilStart = minutesUntil > 0 ? minutesUntil.clamp(0, 999) : 0;
      if (minutesUntilStart > 0 && shiftStatus == ShiftStatus.pending) {
        progress =
            (1 - (minutesUntilStart / 120).clamp(0.0, 1.0)).clamp(0.05, 0.95);
      } else if (shiftStatus == ShiftStatus.pending) {
        progress = 1.0;
      }
    }

    if (activeVisit != null) {
      final elapsed = now.difference(activeVisit.clockInAt).inMinutes;
      progress = (elapsed / 240).clamp(0.0, 1.0);
    }

    return ActiveShift(
      clientName: clientName,
      address: address,
      timeRange: timeRange,
      minutesUntilStart: minutesUntilStart,
      progress: progress,
      clientInitials: initialsFromName(clientName),
      authorizedHours: matchingAssignment != null
          ? '${matchingAssignment.authorization.days} days · ${matchingAssignment.authorization.label}'
          : '—',
      scheduledTimeDisplay: scheduledTimeDisplay,
      serviceType:
          matchingAssignment?.program ?? nextShift?.title ?? 'Care visit',
      visitDateTime: visitDateTime,
      visitDate: visitDate,
      gpsAddress: address,
      status: shiftStatus,
      startedAtLabel: startedAtLabel,
      shiftStartedAt: shiftStartedAt,
      assignedVisits: assignedVisits,
      serviceTypeOptions: assignments.map((a) => a.program).toSet().toList(),
      careTasks: const [],
    );
  }

  ScheduleItemModel? _pickNextShift(
    List<ScheduleItemModel> items,
    DateTime now,
  ) {
    if (items.isEmpty) return null;

    final sorted = [...items]
      ..sort((a, b) => a.scheduledStart.compareTo(b.scheduledStart));

    for (final item in sorted) {
      if (_isRelevantShift(item, now)) {
        return item;
      }
    }

    return null;
  }

  bool _isRelevantShift(ScheduleItemModel item, DateTime now) {
    final status = item.status.toLowerCase();
    if (status == 'completed' || status == 'cancelled') {
      return false;
    }
    return item.scheduledEnd.isAfter(now);
  }

  AssignmentModel? _findAssignment(
    List<AssignmentModel> assignments,
    int clientId,
  ) {
    for (final assignment in assignments) {
      if (assignment.id == clientId) {
        return assignment;
      }
    }
    return null;
  }

  String _formatQueryDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
