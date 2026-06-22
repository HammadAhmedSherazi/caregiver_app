import '../models/task_page_model.dart';

abstract class TaskRepository {
  Future<TaskPageData> getTaskPage();
  Future<PaystubDetail> getPaystubDetail(String id);
}

class TaskRepositoryImpl implements TaskRepository {
  @override
  Future<TaskPageData> getTaskPage() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));

    const visitTasks = [
      TaskItem(
        id: 'visit-1',
        type: TaskItemType.visit,
        title: 'John Doe',
        subtitle: '9:00 AM · 4h',
        status: TaskItemStatus.pending,
        actionLabel: 'View tasks',
        clientName: 'John Doe',
        initials: 'JD',
        avatarUrl: 'https://i.pravatar.cc/150?u=john-doe-care',
        timeLabel: '9:00 AM · 4h',
        isHighPriority: true,
      ),
      TaskItem(
        id: 'visit-2',
        type: TaskItemType.visit,
        title: 'John Doe',
        subtitle: '9:00 AM · 4h',
        status: TaskItemStatus.pending,
        actionLabel: 'View tasks',
        clientName: 'John Doe',
        initials: 'JD',
        avatarUrl: 'https://i.pravatar.cc/150?u=john-doe-care-2',
        timeLabel: '9:00 AM · 4h',
      ),
      TaskItem(
        id: 'visit-3',
        type: TaskItemType.visit,
        title: 'John Doe',
        subtitle: '9:00 AM · 4h',
        status: TaskItemStatus.pending,
        actionLabel: 'View tasks',
        clientName: 'John Doe',
        initials: 'JD',
        avatarUrl: 'https://i.pravatar.cc/150?u=john-doe-care-3',
        timeLabel: '9:00 AM · 4h',
      ),
    ];

    const allTasks = [
      TaskItem(
        id: 'compliance-1',
        type: TaskItemType.complianceForm,
        title: 'May Compliance Form Due',
        subtitle: 'Due today',
        status: TaskItemStatus.pending,
        actionLabel: 'Complete form',
      ),
      TaskItem(
        id: 'document-1',
        type: TaskItemType.documentUpload,
        title: "Upload Updated Driver's License",
        subtitle: 'Due in 3 days',
        status: TaskItemStatus.pending,
        actionLabel: 'Upload now',
      ),
      TaskItem(
        id: 'signature-1',
        type: TaskItemType.visitSignature,
        title: 'Sign Visit Note · Apr 28',
        subtitle: 'Overdue',
        status: TaskItemStatus.overdue,
        actionLabel: 'Sign now',
      ),
      ...visitTasks,
    ];

    return TaskPageData(
      pendingCount: 3,
      allTasks: allTasks,
      visitTasks: visitTasks,
      clientTasks: const ClientTasksData(
        clientName: 'John Doe',
        completedCount: 2,
        totalCount: 4,
        progressPercent: 98,
        complianceTitle: 'Compliance Foam',
        complianceSubtitle: 'Signature required',
        careTasks: [
          ClientCareTask(
            id: 'care-1',
            timeLabel: '9:30 AM',
            title: 'Bathing assistance',
            isCompleted: true,
          ),
          ClientCareTask(
            id: 'care-2',
            timeLabel: '9:30 AM',
            title: 'Meal preparation',
            isCompleted: true,
          ),
          ClientCareTask(
            id: 'care-3',
            timeLabel: '9:30 AM',
            title: 'Medication reminder',
            isCompleted: false,
          ),
          ClientCareTask(
            id: 'care-4',
            timeLabel: '9:30 AM',
            title: 'Light housekeeping',
            isCompleted: false,
          ),
        ],
      ),
      complianceQuestions: const [
        ComplianceQuestion(
          id: 'q1',
          prompt: 'Did you complete all assigned care tasks?',
          selectedYes: true,
        ),
        ComplianceQuestion(
          id: 'q2',
          prompt: 'Were there any incidents or concerns?',
          selectedYes: true,
        ),
      ],
      monthlyComplianceQuestions: const [
        ComplianceQuestion(
          id: 'mq1',
          prompt: '1. Did you provide services during May 2026?',
          selectedYes: true,
        ),
        ComplianceQuestion(
          id: 'mq2',
          prompt: '2. Was the client hospitalized during this month?',
          selectedYes: false,
        ),
        ComplianceQuestion(
          id: 'mq3',
          prompt: '3. Were there any missed or skipped visits?',
          selectedYes: false,
        ),
        ComplianceQuestion(
          id: 'mq4',
          prompt: "4. Did the client's condition change significantly?",
          selectedYes: true,
        ),
        ComplianceQuestion(
          id: 'mq5',
          prompt: '5. Were all scheduled services provided as planned?',
          selectedYes: true,
        ),
        ComplianceQuestion(
          id: 'mq6',
          prompt: '6. Do you certify the information above is accurate?',
          selectedYes: true,
        ),
      ],
      complianceHistorySummary: const ComplianceHistorySummary(
        submittedCount: 11,
        overdueCount: 1,
        onTimePercent: 92,
      ),
      complianceHistory: const [
        ComplianceHistoryRecord(
          id: 'hist-1',
          periodLabel: 'April 2026',
          submittedLabel: 'Submitted May 02, 2026',
          isSubmitted: true,
          hasAttachment: true,
        ),
        ComplianceHistoryRecord(
          id: 'hist-2',
          periodLabel: 'March 2026',
          submittedLabel: 'Submitted Apr 01, 2026',
          isSubmitted: true,
          hasAttachment: true,
        ),
        ComplianceHistoryRecord(
          id: 'hist-3',
          periodLabel: 'February 2026',
          submittedLabel: 'Submitted Mar 03, 2026',
          isSubmitted: true,
          hasAttachment: true,
        ),
        ComplianceHistoryRecord(
          id: 'hist-4',
          periodLabel: 'January 2026',
          submittedLabel: 'Not submitted',
          isSubmitted: false,
          hasAttachment: false,
        ),
      ],
      payroll: const PayrollSummary(
        year: 2026,
        yearToDateAmount: r'$7,112.5',
        hoursLabel: '284.5 hours · 4 paystubs',
        paystubCount: 4,
        quickbooksStatus: 'QuickBooks · Connected',
        gustoStatus: 'Gusto · Ready',
        paystubs: [
          PaystubItem(
            id: 'pay-1',
            periodLabel: 'Apr 14 – Apr 27, 2026',
            hoursLabel: '72.5 hrs · Gross \$1812.50',
            netPay: r'$1456.20',
            isPaid: true,
          ),
          PaystubItem(
            id: 'pay-2',
            periodLabel: 'Mar 31 – Apr 13, 2026',
            hoursLabel: '68 hrs · Gross \$1700.00',
            netPay: r'$1368.40',
            isPaid: true,
          ),
          PaystubItem(
            id: 'pay-3',
            periodLabel: 'Mar 17 – Mar 30, 2026',
            hoursLabel: '74 hrs · Gross \$1850.00',
            netPay: r'$1487.60',
            isPaid: true,
          ),
          PaystubItem(
            id: 'pay-4',
            periodLabel: 'Mar 03 – Mar 16, 2026',
            hoursLabel: '70 hrs · Gross \$1750.00',
            netPay: r'$1408.10',
            isPaid: true,
          ),
        ],
      ),
    );
  }

  @override
  Future<PaystubDetail> getPaystubDetail(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return const PaystubDetail(
      periodLabel: 'Apr 14 – Apr 27, 2026',
      netPay: r'$1456.20',
      payDate: 'Apr 30, 2026',
      hoursWorked: '72.5 hrs',
      rate: r'$25.00 / hr',
      grossPay: r'$1812.50',
      federalTax: r'-$195.97',
      stateTax: r'-$89.08',
      fica: r'-$71.26',
      visitSummary: [
        MapEntry('John Doe', '40.5 hrs'),
        MapEntry('Evelyn Carter', '32 hrs'),
      ],
    );
  }
}
