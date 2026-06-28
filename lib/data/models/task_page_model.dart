import 'package:equatable/equatable.dart';

enum TaskFilter { all, compliance, documents, visits }

enum TaskItemStatus { pending, overdue, submitted, paid }

enum TaskItemType { complianceForm, documentUpload, visitSignature, visit }

class TaskItem extends Equatable {
  const TaskItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.actionLabel,
    this.clientName,
    this.initials,
    this.avatarUrl,
    this.timeLabel,
    this.isHighPriority = false,
  });

  final String id;
  final TaskItemType type;
  final String title;
  final String subtitle;
  final TaskItemStatus status;
  final String actionLabel;
  final String? clientName;
  final String? initials;
  final String? avatarUrl;
  final String? timeLabel;
  final bool isHighPriority;

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        subtitle,
        status,
        actionLabel,
        clientName,
        initials,
        avatarUrl,
        timeLabel,
        isHighPriority,
      ];
}

class ClientCareTask extends Equatable {
  const ClientCareTask({
    required this.id,
    required this.timeLabel,
    required this.title,
    required this.isCompleted,
  });

  final String id;
  final String timeLabel;
  final String title;
  final bool isCompleted;

  @override
  List<Object?> get props => [id, timeLabel, title, isCompleted];
}

class ClientTasksData extends Equatable {
  const ClientTasksData({
    required this.clientName,
    required this.completedCount,
    required this.totalCount,
    required this.progressPercent,
    required this.careTasks,
    required this.complianceTitle,
    required this.complianceSubtitle,
  });

  final String clientName;
  final int completedCount;
  final int totalCount;
  final int progressPercent;
  final List<ClientCareTask> careTasks;
  final String complianceTitle;
  final String complianceSubtitle;

  @override
  List<Object?> get props => [
        clientName,
        completedCount,
        totalCount,
        progressPercent,
        careTasks,
        complianceTitle,
        complianceSubtitle,
      ];
}

class ComplianceQuestion extends Equatable {
  const ComplianceQuestion({
    required this.id,
    required this.prompt,
    this.selectedYes,
  });

  final String id;
  final String prompt;
  final bool? selectedYes;

  ComplianceQuestion copyWith({bool? selectedYes}) {
    return ComplianceQuestion(
      id: id,
      prompt: prompt,
      selectedYes: selectedYes ?? this.selectedYes,
    );
  }

  @override
  List<Object?> get props => [id, prompt, selectedYes];
}

class ComplianceHistorySummary extends Equatable {
  const ComplianceHistorySummary({
    required this.submittedCount,
    required this.overdueCount,
    required this.onTimePercent,
  });

  final int submittedCount;
  final int overdueCount;
  final int onTimePercent;

  @override
  List<Object?> get props => [submittedCount, overdueCount, onTimePercent];
}

class ComplianceHistoryRecord extends Equatable {
  const ComplianceHistoryRecord({
    required this.id,
    required this.periodLabel,
    required this.submittedLabel,
    required this.isSubmitted,
    required this.hasAttachment,
  });

  final String id;
  final String periodLabel;
  final String submittedLabel;
  final bool isSubmitted;
  final bool hasAttachment;

  @override
  List<Object?> get props =>
      [id, periodLabel, submittedLabel, isSubmitted, hasAttachment];
}

class PaystubItem extends Equatable {
  const PaystubItem({
    required this.id,
    required this.periodLabel,
    required this.hoursLabel,
    required this.grossPay,
    required this.status,
    required this.stubAvailable,
  });

  final String id;
  final String periodLabel;
  final String hoursLabel;
  final String grossPay;
  final String status;
  final bool stubAvailable;

  bool get isPaid => status == 'Paid';

  @override
  List<Object?> get props =>
      [id, periodLabel, hoursLabel, grossPay, status, stubAvailable];
}

class PayrollSummary extends Equatable {
  const PayrollSummary({
    required this.year,
    required this.yearToDateAmount,
    required this.hoursLabel,
    required this.paystubCount,
    required this.quickbooksStatus,
    required this.gustoStatus,
    required this.paystubs,
  });

  final int year;
  final String yearToDateAmount;
  final String hoursLabel;
  final int paystubCount;
  final String quickbooksStatus;
  final String gustoStatus;
  final List<PaystubItem> paystubs;

  @override
  List<Object?> get props => [
        year,
        yearToDateAmount,
        hoursLabel,
        paystubCount,
        quickbooksStatus,
        gustoStatus,
        paystubs,
      ];
}

class PaystubDetail extends Equatable {
  const PaystubDetail({
    required this.id,
    required this.periodLabel,
    required this.grossPay,
    required this.payDate,
    required this.hoursWorked,
    required this.rate,
    required this.status,
    required this.program,
    required this.stubAvailable,
    required this.visitSummary,
  });

  final String id;
  final String periodLabel;
  final String grossPay;
  final String payDate;
  final String hoursWorked;
  final String rate;
  final String status;
  final String program;
  final bool stubAvailable;
  final List<MapEntry<String, String>> visitSummary;

  bool get isPaid => status == 'Paid';

  @override
  List<Object?> get props => [
        id,
        periodLabel,
        grossPay,
        payDate,
        hoursWorked,
        rate,
        status,
        program,
        stubAvailable,
        visitSummary,
      ];
}

class TaskPageData extends Equatable {
  const TaskPageData({
    required this.pendingCount,
    required this.allTasks,
    required this.visitTasks,
    required this.clientTasks,
    required this.complianceQuestions,
    required this.monthlyComplianceQuestions,
    required this.complianceHistorySummary,
    required this.complianceHistory,
    required this.payroll,
  });

  final int pendingCount;
  final List<TaskItem> allTasks;
  final List<TaskItem> visitTasks;
  final ClientTasksData clientTasks;
  final List<ComplianceQuestion> complianceQuestions;
  final List<ComplianceQuestion> monthlyComplianceQuestions;
  final ComplianceHistorySummary complianceHistorySummary;
  final List<ComplianceHistoryRecord> complianceHistory;
  final PayrollSummary payroll;

  List<TaskItem> tasksForFilter(TaskFilter filter) {
    return switch (filter) {
      TaskFilter.all => allTasks,
      TaskFilter.compliance => allTasks
          .where((t) =>
              t.type == TaskItemType.complianceForm ||
              t.type == TaskItemType.visitSignature)
          .toList(),
      TaskFilter.documents =>
        allTasks.where((t) => t.type == TaskItemType.documentUpload).toList(),
      TaskFilter.visits => visitTasks,
    };
  }

  @override
  List<Object?> get props => [
        pendingCount,
        allTasks,
        visitTasks,
        clientTasks,
        complianceQuestions,
        monthlyComplianceQuestions,
        complianceHistorySummary,
        complianceHistory,
        payroll,
      ];
}
