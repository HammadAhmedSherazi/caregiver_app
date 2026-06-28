import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../../data/models/task_page_model.dart';
import '../../home/widgets/home_icon_box.dart';
import '../../home/widgets/home_svg_icon.dart';
import '../../home/widgets/vertical_overlap.dart';
import '../../widgets/get_request_view.dart';
import '../../widgets/skeletons/api_tab_skeletons.dart';
import '../cubit/task_cubit.dart';
import '../cubit/task_state.dart';
import '../widgets/task_cards.dart';
import '../widgets/task_filter_chips.dart';
import '../widgets/task_screen_header.dart';
import '../widgets/task_search_bar.dart';
import 'client_tasks_view.dart';
import '../../clients/view/clients_list_view.dart';
import 'compliance_form_view.dart';
import 'compliance_history_view.dart';
import 'payroll_view.dart';
import 'upload_document_view.dart';

class TaskTabView extends StatefulWidget {
  const TaskTabView({super.key});

  @override
  State<TaskTabView> createState() => _TaskTabViewState();
}

class _TaskTabViewState extends State<TaskTabView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openTask(BuildContext context, TaskItem task, TaskPageData data) {
    switch (task.type) {
      case TaskItemType.complianceForm:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ComplianceFormView(
              title: task.title,
              questions: data.monthlyComplianceQuestions,
              isMonthly: true,
            ),
          ),
        );
      case TaskItemType.documentUpload:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const UploadDocumentView(),
          ),
        );
      case TaskItemType.visitSignature:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ComplianceFormView(
              title: 'Sign Visit Note',
              questions: data.complianceQuestions,
            ),
          ),
        );
      case TaskItemType.visit:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ClientTasksView(
              data: ClientTasksData(
                clientName: task.clientName ?? task.title,
                completedCount:
                    task.status == TaskItemStatus.submitted ? 1 : 0,
                totalCount: 1,
                progressPercent:
                    task.status == TaskItemStatus.submitted ? 100 : 0,
                complianceTitle: '',
                complianceSubtitle: '',
                careTasks: const [],
              ),
            ),
          ),
        );
    }
  }

  String _iconForTask(TaskItemType type) {
    return switch (type) {
      TaskItemType.complianceForm => AppAssets.icTaskForm,
      TaskItemType.documentUpload => AppAssets.icTaskUpload,
      TaskItemType.visitSignature => AppAssets.icTaskSignature,
      TaskItemType.visit => AppAssets.icHomeUserOutline,
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskCubit, TaskState>(
      builder: (context, state) {
        return GetRequestView(
          isLoading: state.isLoading,
          hasError: state.hasError,
          onRetry: () => context.read<TaskCubit>().loadTasks(),
          skeleton: const TaskTabSkeleton(),
          child: _buildContent(context, state),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, TaskState state) {
        final data = state.data;
        if (data == null) {
          return const SizedBox.shrink();
        }

        final cubit = context.read<TaskCubit>();
        final tasks = state.visibleTasks;
        final actionTasks = state.filter == TaskFilter.visits
            ? const <TaskItem>[]
            : tasks.where((t) => t.type != TaskItemType.visit).toList();
        final visitTasks = state.filter == TaskFilter.visits
            ? tasks
            : (state.filter == TaskFilter.all ? data.visitTasks : <TaskItem>[]);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TaskScreenHeader(
                  title: 'All Tasks',
                  subtitle: '${data.pendingCount} Pending',
                  height: 187,
                ),
                VerticalOverlap(
                  overlap: 30,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TaskSearchBar(
                      controller: _searchController,
                      onChanged: cubit.setSearchQuery,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: cubit.loadTasks,
                color: AppColors.homePrimary,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
                  children: [
                    TaskFilterChips(
                      selected: state.filter,
                      onChanged: cubit.setFilter,
                    ),
                    const SizedBox(height: 24),
                    for (final task in actionTasks) ...[
                      TaskActionCard(
                        task: task,
                        iconAsset: _iconForTask(task.type),
                        onAction: () => _openTask(context, task, data),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (visitTasks.isNotEmpty) ...[
                      Text(
                        "Today's Schedule",
                        style: context.responsiveStyle(
                          AppTextStyles.homeCardTitle.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      for (final task in visitTasks) ...[
                        TaskVisitCard(
                          task: task,
                          onTap: () => _openTask(context, task, data),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                    _TaskQuickLinks(
                      onPayroll: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const PayrollView(),
                          ),
                        );
                      },
                      onHistory: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ComplianceHistoryView(
                              summary: data.complianceHistorySummary,
                              records: data.complianceHistory,
                            ),
                          ),
                        );
                      },
                      onClients: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ClientsListView(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
  }
}

class _TaskQuickLinks extends StatelessWidget {
  const _TaskQuickLinks({
    required this.onPayroll,
    required this.onHistory,
    required this.onClients,
  });

  final VoidCallback onPayroll;
  final VoidCallback onHistory;
  final VoidCallback onClients;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        _QuickLinkTile(
          iconAsset: AppAssets.icHomeUserOutline,
          title: 'My Clients',
          subtitle: 'Assigned clients & profiles',
          onTap: onClients,
        ),
        const SizedBox(height: 12),
        _QuickLinkTile(
          iconAsset: AppAssets.icTaskPayroll,
          title: 'Payroll',
          subtitle: 'View paystubs & earnings',
          onTap: onPayroll,
        ),
        const SizedBox(height: 12),
        _QuickLinkTile(
          iconAsset: AppAssets.icTaskForm,
          title: 'Compliance History',
          subtitle: 'Past submissions & records',
          onTap: onHistory,
        ),
      ],
    );
  }
}

class _QuickLinkTile extends StatelessWidget {
  const _QuickLinkTile({
    required this.iconAsset,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String iconAsset;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: taskCardDecoration(),
        child: Row(
          children: [
            HomeIconBox(iconAsset: iconAsset),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.responsiveStyle(AppTextStyles.homeCardTitle),
                  ),
                  Text(
                    subtitle,
                    style: context.responsiveStyle(
                      AppTextStyles.homeCardSubtitle,
                    ),
                  ),
                ],
              ),
            ),
            const HomeSvgIcon(
              asset: AppAssets.arrowForward,
              width: 24,
              height: 24,
              color: AppColors.authButtonText,
            ),
          ],
        ),
      ),
    );
  }
}
