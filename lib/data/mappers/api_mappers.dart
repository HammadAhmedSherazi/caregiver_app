import '../models/api/assignment_model.dart';
import '../models/api/compliance_form_model.dart';
import '../models/api/conversation_model.dart';
import '../models/api/dashboard_model.dart';
import '../models/api/document_model.dart';
import '../models/api/earnings_summary_model.dart';
import '../models/api/notification_item_model.dart';
import '../models/api/pay_detail_model.dart';
import '../models/api/pay_item_model.dart';
import '../models/api/schedule_item_model.dart';
import '../models/api/visit_model.dart';
import '../models/api/visit_task_model.dart';
import '../models/chat_message_model.dart';
import '../models/client_model.dart';
import '../models/home_dashboard_model.dart';
import '../models/inbox_thread_model.dart';
import '../models/notification_model.dart';
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

NotificationKind notificationTypeToKind(String type) {
  switch (type) {
    case 'secure_message':
    case 'communication_sent':
    case 'communication_failed':
    case 'communication_received':
      return NotificationKind.message;
    default:
      return NotificationKind.schedule;
  }
}

AppNotification notificationItemToAppNotification(NotificationItemModel item) {
  return AppNotification(
    id: item.id.toString(),
    title: item.title,
    body: item.body,
    timestampLabel: item.timeAgo,
    kind: notificationTypeToKind(item.type),
    isRead: item.read,
  );
}

InboxThread conversationToInboxThread(ConversationSummaryModel conversation) {
  return InboxThread(
    id: conversation.id.toString(),
    contactName: conversation.counterpart.name,
    preview: conversation.lastMessage,
    timestampLabel: conversation.timeAgo,
    avatarUrl: conversation.counterpart.avatarUrl,
  );
}

ChatMessage conversationMessageToChatMessage(ConversationMessageModel message) {
  return ChatMessage(
    id: message.id.toString(),
    text: message.body,
    direction: message.isMine
        ? ChatMessageDirection.outgoing
        : ChatMessageDirection.incoming,
    timestampLabel: message.time,
  );
}

CareTaskItem visitTaskToCareTaskItem(VisitTaskModel task) {
  return CareTaskItem(
    id: task.id,
    label: task.label,
    isCompleted: task.isCompleted,
  );
}

HomeDashboard dashboardToHomeDashboard({
  required DashboardModel dashboard,
  required List<AssignmentModel> assignments,
  List<CareTaskItem> careTasks = const [],
}) {
  final now = DateTime.now();
  final assignedVisits = assignments
      .map(
        (assignment) => assignmentToAssignedVisit(
          assignment,
          scheduleLabel: assignment.authorization.label,
        ),
      )
      .toList();

  final activeVisit = dashboard.activeVisit != null &&
          dashboard.activeVisit!.isActive
      ? dashboard.activeVisit
      : null;
  final nextShiftItem = dashboard.nextShift?.visit;
  final activeShift = _buildActiveShiftFromDashboard(
    activeVisit: activeVisit,
    nextShift: nextShiftItem,
    startsInMinutes: dashboard.nextShift?.startsInMinutes ?? 0,
    assignments: assignments,
    assignedVisits: assignedVisits,
    careTasks: careTasks,
    now: now,
  );

  final scheduleEntries = dashboard.todaySchedule
      .take(4)
      .map(scheduleItemToScheduleEntry)
      .toList();

  final pendingTasks = dashboard.todaySchedule
      .take(3)
      .map(
        (item) => PendingTask(
          timeLabel: formatTimeLabel(item.scheduledStart),
          title: item.clientName,
        ),
      )
      .toList();

  final caregiver = dashboard.caregiver;
  final firstName = caregiver.firstName ??
      (caregiver.name.isNotEmpty ? caregiver.name.split(' ').first : 'Caregiver');

  return HomeDashboard(
    caregiverName: firstName,
    dateLabel: dashboard.today.label.isNotEmpty
        ? dashboard.today.label
        : formatDateLabel(now),
    avatarUrl: caregiver.avatarUrl,
    activeShift: activeShift,
    schedule: scheduleEntries,
    taskSummary: TaskSummary(
      completedTasks: dashboard.tasks.done,
      totalTasks: dashboard.tasks.total,
      remainingHours: '${dashboard.tasks.remainingHours}h',
    ),
    pendingTasks: pendingTasks,
    unreadNotifications: dashboard.badges.unreadNotifications,
    unreadConversations: dashboard.badges.unreadConversations,
  );
}

ActiveShift? _buildActiveShiftFromDashboard({
  required VisitModel? activeVisit,
  required ScheduleItemModel? nextShift,
  required int startsInMinutes,
  required List<AssignmentModel> assignments,
  required List<AssignedVisit> assignedVisits,
  required List<CareTaskItem> careTasks,
  required DateTime now,
}) {
  if (activeVisit == null && nextShift == null) return null;

  final clientId = activeVisit?.clientId ?? nextShift!.clientId;
  final matchingAssignment = assignments
      .where((assignment) => assignment.id == clientId)
      .firstOrNull;

  final clientName =
      activeVisit?.clientName ?? nextShift?.clientName ?? 'Client';
  final address = nextShift?.address ??
      matchingAssignment?.address ??
      'Address unavailable';

  final shiftStatus =
      activeVisit != null ? ShiftStatus.inProgress : ShiftStatus.pending;
  final shiftStartedAt = activeVisit?.clockInAt;
  final startedAtLabel = shiftStartedAt != null
      ? 'Started ${formatTimeLabel(shiftStartedAt)}'
      : null;

  var scheduledTimeDisplay = '—';
  var timeRange = 'No upcoming shift';
  var visitDateTime = formatDateLabel(now);
  var visitDate = formatDateLabel(now);
  var minutesUntilStart = startsInMinutes.clamp(0, 999);
  var progress = 0.0;

  if (nextShift != null) {
    scheduledTimeDisplay =
        '${formatTimeLabel(nextShift.scheduledStart)} – ${formatTimeLabel(nextShift.scheduledEnd)}';
    timeRange = scheduledTimeDisplay;
    visitDateTime =
        '${formatDateLabel(nextShift.scheduledStart)} · ${formatTimeLabel(nextShift.scheduledStart)}';
    visitDate = formatDateLabel(nextShift.scheduledStart);
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

  final scheduleId = activeVisit?.scheduleId ??
      activeVisit?.id ??
      (activeVisit == null ? nextShift?.id : null);

  return ActiveShift(
    visitId: activeVisit?.id,
    clientId: clientId,
    scheduleId: scheduleId,
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
    careTasks: careTasks,
  );
}

PaystubDetail payDetailToPaystubDetail(PayDetailModel detail) {
  return PaystubDetail(
    id: detail.id.toString(),
    periodLabel: detail.period,
    grossPay: formatCurrency(detail.gross),
    payDate: detail.payDate ?? '—',
    hoursWorked: '${detail.hours.toStringAsFixed(1)} hrs',
    rate: '${formatCurrency(detail.rate)} / hr',
    status: detail.status,
    program: '',
    stubAvailable: true,
    visitSummary: detail.visitSummary
        .map((item) => MapEntry(item.clientName, '${item.hours} hrs'))
        .toList(),
    netPay: formatCurrency(detail.breakdown.net),
    federalTax: formatCurrency(detail.breakdown.federalTax),
    stateTax: formatCurrency(detail.breakdown.stateTax),
    fica: formatCurrency(detail.breakdown.fica),
    estimatedBreakdown: detail.breakdown.estimated,
  );
}

PayrollSummary earningsSummaryToPayrollSummary(
  EarningsSummaryModel summary,
  List<PayItemModel> payItems,
) {
  final ytd = summary.yearToDate;
  final qb = summary.quickbooks;
  final gusto = summary.gusto;

  return PayrollSummary(
    year: summary.year,
    yearToDateAmount: formatCurrency(ytd.gross),
    hoursLabel:
        '${ytd.hours.toStringAsFixed(1)} hours · ${ytd.paystubCount} paystubs',
    paystubCount: ytd.paystubCount,
    quickbooksStatus: qb.connected == true ? '${qb.label} connected' : qb.label,
    gustoStatus: gusto.ready == true ? '${gusto.label} ready' : gusto.label,
    paystubs: payItems.map(payItemToPaystub).toList(),
  );
}

ComplianceQuestion complianceQuestionToUi(ComplianceQuestionModel question) {
  return ComplianceQuestion(id: question.key, prompt: question.text);
}

TaskItem complianceFormToTaskItem(ComplianceFormListItemModel form) {
  return TaskItem(
    id: form.id.toString(),
    type: TaskItemType.complianceForm,
    title: '${form.periodLabel} Compliance',
    subtitle: form.isOverdue ? 'Overdue' : form.status,
    status: form.submitted
        ? TaskItemStatus.submitted
        : (form.isOverdue ? TaskItemStatus.overdue : TaskItemStatus.pending),
    actionLabel: 'Complete form',
    isHighPriority: form.isOverdue,
  );
}

TaskItem documentToTaskItem(DocumentModel document) {
  return TaskItem(
    id: document.id.toString(),
    type: TaskItemType.documentUpload,
    title: document.name,
    subtitle: document.type,
    status: document.verificationStatus == 'Pending'
        ? TaskItemStatus.pending
        : TaskItemStatus.submitted,
    actionLabel: 'View',
  );
}

extension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
