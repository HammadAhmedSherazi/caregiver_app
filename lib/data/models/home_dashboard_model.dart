import 'package:equatable/equatable.dart';

enum ShiftStatus { pending, inProgress }

class HomeDashboard extends Equatable {
  const HomeDashboard({
    required this.caregiverName,
    required this.dateLabel,
    this.activeShift,
    required this.schedule,
    required this.taskSummary,
    required this.pendingTasks,
  });

  final String caregiverName;
  final String dateLabel;
  final ActiveShift? activeShift;
  final List<ScheduleEntry> schedule;
  final TaskSummary taskSummary;
  final List<PendingTask> pendingTasks;

  bool get hasShiftCard => activeShift != null;

  HomeDashboard copyWith({
    ActiveShift? activeShift,
    bool clearActiveShift = false,
  }) {
    return HomeDashboard(
      caregiverName: caregiverName,
      dateLabel: dateLabel,
      activeShift: clearActiveShift ? null : (activeShift ?? this.activeShift),
      schedule: schedule,
      taskSummary: taskSummary,
      pendingTasks: pendingTasks,
    );
  }

  @override
  List<Object?> get props => [
        caregiverName,
        dateLabel,
        activeShift,
        schedule,
        taskSummary,
        pendingTasks,
      ];
}

class ActiveShift extends Equatable {
  const ActiveShift({
    required this.clientName,
    required this.address,
    required this.timeRange,
    required this.minutesUntilStart,
    required this.progress,
    this.clientInitials = 'JD',
    this.authorizedHours = '4h / week',
    this.scheduledTimeDisplay = '9:00 – 1:00 PM',
    this.serviceType = 'Personal Care',
    this.visitDateTime = 'Mon · 9:00 AM',
    this.visitDate = 'Mon, May 18, 2026',
    this.gpsAddress = '123 Main St, Brooklyn, NY 11201',
    this.status = ShiftStatus.pending,
    this.startedAtLabel,
    this.shiftStartedAt,
    this.careTasks = const [],
    this.assignedVisits = const [],
    this.serviceTypeOptions = const [],
  });

  final String clientName;
  final String address;
  final String timeRange;
  final int minutesUntilStart;
  final double progress;
  final String clientInitials;
  final String authorizedHours;
  final String scheduledTimeDisplay;
  final String serviceType;
  final String visitDateTime;
  final String visitDate;
  final String gpsAddress;
  final ShiftStatus status;
  final String? startedAtLabel;
  final DateTime? shiftStartedAt;
  final List<String> careTasks;
  final List<AssignedVisit> assignedVisits;
  final List<String> serviceTypeOptions;

  bool get isInProgress => status == ShiftStatus.inProgress;

  /// Small label above the client name on the home shift card.
  String get cardHeading {
    if (isInProgress) return 'Active Shift';
    if (minutesUntilStart <= 0) return 'Ready to Start';
    return 'Upcoming Shift';
  }

  /// Start Shift is only offered before clock-in.
  bool get showStartShiftButton => status == ShiftStatus.pending;

  /// Countdown ring only when a future scheduled start exists.
  bool get showProgressRing =>
      status == ShiftStatus.pending && minutesUntilStart > 0;

  /// Footer line under the action area.
  String get cardScheduleLabel {
    if (scheduledTimeDisplay != '—') return scheduledTimeDisplay;
    return timeRange;
  }

  ActiveShift copyWith({
    String? clientName,
    String? address,
    String? serviceType,
    ShiftStatus? status,
    String? startedAtLabel,
    DateTime? shiftStartedAt,
  }) {
    return ActiveShift(
      clientName: clientName ?? this.clientName,
      address: address ?? this.address,
      timeRange: timeRange,
      minutesUntilStart: minutesUntilStart,
      progress: progress,
      clientInitials: clientInitials,
      authorizedHours: authorizedHours,
      scheduledTimeDisplay: scheduledTimeDisplay,
      serviceType: serviceType ?? this.serviceType,
      visitDateTime: visitDateTime,
      visitDate: visitDate,
      gpsAddress: gpsAddress,
      status: status ?? this.status,
      startedAtLabel: startedAtLabel ?? this.startedAtLabel,
      shiftStartedAt: shiftStartedAt ?? this.shiftStartedAt,
      assignedVisits: assignedVisits,
      serviceTypeOptions: serviceTypeOptions,
      careTasks: careTasks,
    );
  }

  @override
  List<Object?> get props => [
        clientName,
        address,
        timeRange,
        minutesUntilStart,
        progress,
        clientInitials,
        authorizedHours,
        scheduledTimeDisplay,
        serviceType,
        visitDateTime,
        visitDate,
        gpsAddress,
        status,
        startedAtLabel,
        shiftStartedAt,
        careTasks,
        assignedVisits,
        serviceTypeOptions,
      ];
}

class AssignedVisit extends Equatable {
  const AssignedVisit({
    required this.clientName,
    required this.initials,
    required this.scheduleLabel,
    required this.scheduledLabel,
    required this.serviceType,
  });

  final String clientName;
  final String initials;
  final String scheduleLabel;
  final String scheduledLabel;
  final String serviceType;

  @override
  List<Object?> get props => [
        clientName,
        initials,
        scheduleLabel,
        scheduledLabel,
        serviceType,
      ];
}

class ScheduleEntry extends Equatable {
  const ScheduleEntry({
    required this.clientName,
    required this.initials,
    required this.timeLabel,
    this.isHighPriority = false,
  });

  final String clientName;
  final String initials;
  final String timeLabel;
  final bool isHighPriority;

  @override
  List<Object?> get props => [clientName, initials, timeLabel, isHighPriority];
}

class TaskSummary extends Equatable {
  const TaskSummary({
    required this.completedTasks,
    required this.totalTasks,
    required this.remainingHours,
  });

  final int completedTasks;
  final int totalTasks;
  final String remainingHours;

  @override
  List<Object?> get props => [completedTasks, totalTasks, remainingHours];
}

class PendingTask extends Equatable {
  const PendingTask({
    required this.timeLabel,
    required this.title,
  });

  final String timeLabel;
  final String title;

  @override
  List<Object?> get props => [timeLabel, title];
}
