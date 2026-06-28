import '../models/api/assignment_model.dart';
import '../models/api/pay_item_model.dart';
import '../models/api/schedule_item_model.dart';
import '../models/api/visit_model.dart';
import '../models/client_model.dart';
import '../models/home_dashboard_model.dart';
import '../models/schedule_page_model.dart';
import '../models/task_page_model.dart';

String initialsFromName(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    return parts.first.isNotEmpty ? parts.first[0].toUpperCase() : '?';
  }
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}

String formatTimeLabel(DateTime dateTime) {
  final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final period = dateTime.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}

String formatDateLabel(DateTime dateTime) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${weekdays[dateTime.weekday - 1]}, '
      '${months[dateTime.month - 1]} ${dateTime.day}';
}

String formatCurrency(double amount) {
  return '\$${amount.toStringAsFixed(2)}';
}

ClientModel assignmentToClient(AssignmentModel assignment) {
  return ClientModel(
    id: assignment.id.toString(),
    name: assignment.name,
    listSubtitle: assignment.address,
    scheduleBadge: assignment.authorization.label,
    address: assignment.address,
    clientPhone: assignment.phone,
    emergencyContact: ClientContact(
      label: '${assignment.program} · ${assignment.county}',
      phone: assignment.phone,
    ),
    dailyCarePlan: const [],
  );
}

ScheduleAppointment scheduleItemToAppointment(ScheduleItemModel item) {
  final status = switch (item.status) {
    'Scheduled' => ScheduleAppointmentStatus.scheduled,
    _ => ScheduleAppointmentStatus.upcoming,
  };

  return ScheduleAppointment(
    timeLabel: formatTimeLabel(item.scheduledStart),
    clientName: item.clientName,
    address: item.address,
    status: status,
  );
}

PaystubItem payItemToPaystub(PayItemModel item) {
  return PaystubItem(
    id: item.id.toString(),
    periodLabel: item.period,
    hoursLabel:
        '${item.hours.toStringAsFixed(1)} hrs · ${item.program} · ${formatCurrency(item.gross)}',
    grossPay: formatCurrency(item.gross),
    status: item.status,
    stubAvailable: item.stubAvailable,
  );
}

PaystubDetail payItemToPaystubDetail(PayItemModel item) {
  return PaystubDetail(
    id: item.id.toString(),
    periodLabel: item.period,
    grossPay: formatCurrency(item.gross),
    payDate: item.paidDate ?? '—',
    hoursWorked: '${item.hours.toStringAsFixed(1)} hrs',
    rate: '${formatCurrency(item.rate)} / hr',
    status: item.status,
    program: item.program,
    stubAvailable: item.stubAvailable,
    visitSummary: [
      if (item.clientName != null && item.clientName!.isNotEmpty)
        MapEntry(item.clientName!, '${item.hours.toStringAsFixed(1)} hrs'),
    ],
  );
}

TaskItem visitToTaskItem(VisitModel visit) {
  final subtitle = visit.totalHours != null
      ? '${formatTimeLabel(visit.clockInAt)} · ${visit.totalHours}h'
      : formatTimeLabel(visit.clockInAt);

  return TaskItem(
    id: visit.id.toString(),
    type: TaskItemType.visit,
    title: visit.clientName,
    subtitle: subtitle,
    status: visit.status == 'Completed'
        ? TaskItemStatus.submitted
        : TaskItemStatus.pending,
    actionLabel: 'View visit',
    clientName: visit.clientName,
    initials: initialsFromName(visit.clientName),
    timeLabel: subtitle,
  );
}

AssignedVisit assignmentToAssignedVisit(
  AssignmentModel assignment, {
  String scheduleLabel = 'Assigned client',
}) {
  return AssignedVisit(
    clientName: assignment.name,
    initials: initialsFromName(assignment.name),
    scheduleLabel: scheduleLabel,
    scheduledLabel: scheduleLabel,
    serviceType: assignment.program,
  );
}

ScheduleEntry scheduleItemToScheduleEntry(ScheduleItemModel item) {
  final durationHours =
      item.scheduledEnd.difference(item.scheduledStart).inMinutes / 60;

  return ScheduleEntry(
    clientName: item.clientName,
    initials: initialsFromName(item.clientName),
    timeLabel: '${formatTimeLabel(item.scheduledStart)} · ${durationHours.round()}h',
    isHighPriority: item.status == 'Scheduled',
  );
}
