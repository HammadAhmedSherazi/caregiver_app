import '../models/home_dashboard_model.dart';

abstract class HomeRepository {
  Future<HomeDashboard> getDashboard();
}

class HomeRepositoryImpl implements HomeRepository {
  @override
  Future<HomeDashboard> getDashboard() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));

    const assignedVisits = [
      AssignedVisit(
        clientName: 'John Doe',
        initials: 'JD',
        scheduleLabel: 'Today · 9:00 AM · Personal Care',
        scheduledLabel: 'Today · 9:00 AM',
        serviceType: 'Personal Care',
      ),
      AssignedVisit(
        clientName: 'Evelyn Carter',
        initials: 'EC',
        scheduleLabel: 'Today · 2:00 PM · Homemaking',
        scheduledLabel: 'Today · 2:00 PM',
        serviceType: 'Homemaking',
      ),
    ];

    return const HomeDashboard(
      caregiverName: 'Mitchell',
      dateLabel: 'Tuesday, Apr 22',
      activeShift: ActiveShift(
        clientName: 'John Doe',
        address: '248 Oak Street, Brooklyn',
        timeRange: '9:00 AM – 1:00 PM',
        minutesUntilStart: 35,
        progress: 0.62,
        assignedVisits: assignedVisits,
      ),
      schedule: [
        ScheduleEntry(
          clientName: 'John Doe',
          initials: 'JD',
          timeLabel: '9:00 AM · 4h',
          isHighPriority: true,
        ),
        ScheduleEntry(
          clientName: 'John Doe',
          initials: 'JD',
          timeLabel: '9:00 AM · 4h',
        ),
        ScheduleEntry(
          clientName: 'John Doe',
          initials: 'JD',
          timeLabel: '9:00 AM · 4h',
        ),
        ScheduleEntry(
          clientName: 'John Doe',
          initials: 'JD',
          timeLabel: '9:00 AM · 4h',
        ),
      ],
      taskSummary: TaskSummary(
        completedTasks: 12,
        totalTasks: 15,
        remainingHours: '4.5h',
      ),
      pendingTasks: [
        PendingTask(
          timeLabel: '9:30 AM',
          title: 'Medication reminder',
        ),
        PendingTask(
          timeLabel: '9:30 AM',
          title: 'Light housekeeping',
        ),
      ],
    );
  }
}
