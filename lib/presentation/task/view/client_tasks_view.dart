import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../../data/models/task_page_model.dart';
import '../../home/widgets/vertical_overlap.dart';
import '../widgets/client_task_widgets.dart';
import '../widgets/task_screen_header.dart';
import 'compliance_form_view.dart';

class ClientTasksView extends StatefulWidget {
  const ClientTasksView({
    super.key,
    required this.data,
  });

  final ClientTasksData data;

  @override
  State<ClientTasksView> createState() => _ClientTasksViewState();
}

class _ClientTasksViewState extends State<ClientTasksView> {
  late List<ClientCareTask> _tasks;

  static const _headerHeight = 244.0;
  static const _progressOverlap = 64.0;

  @override
  void initState() {
    super.initState();
    _tasks = List.of(widget.data.careTasks);
  }

  int get _completedCount => _tasks.where((t) => t.isCompleted).length;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final progress = data.progressPercent / 100;

    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TaskScreenHeader(
                title: 'Tasks',
                subtitle: 'Assigned to you',
                onBack: () => Navigator.of(context).pop(),
                height: _headerHeight,
              ),
              VerticalOverlap(
                overlap: _progressOverlap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClientTasksProgressCard(
                    completedCount: _completedCount,
                    totalCount: data.totalCount,
                    progressPercent: data.progressPercent,
                    progress: progress,
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 40),
              children: [
                Text(
                  'Daily Care · ${data.clientName}',
                  style: context.responsiveStyle(
                    AppTextStyles.homeCardTitle.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.homeDarkText,
                      letterSpacing: -0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                for (var i = 0; i < _tasks.length; i++) ...[
                  ClientCareTaskCard(
                    task: _tasks[i],
                    onToggle: () {
                      setState(() {
                        _tasks[i] = ClientCareTask(
                          id: _tasks[i].id,
                          timeLabel: _tasks[i].timeLabel,
                          title: _tasks[i].title,
                          isCompleted: !_tasks[i].isCompleted,
                        );
                      });
                    },
                  ),
                  if (i < _tasks.length - 1) const SizedBox(height: 10),
                ],
                const SizedBox(height: 24),
                ClientComplianceTaskCard(
                  title: data.complianceTitle,
                  subtitle: data.complianceSubtitle,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ComplianceFormView(
                          title: data.complianceTitle,
                          questions: const [
                            ComplianceQuestion(
                              id: 'v1',
                              prompt:
                                  'Did you complete all assigned care tasks?',
                            ),
                            ComplianceQuestion(
                              id: 'v2',
                              prompt:
                                  'Were there any incidents or concerns?',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
