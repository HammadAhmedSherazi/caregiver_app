import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/velora_format.dart';
import '../../../data/models/api/compliance_form_model.dart';
import '../../main/app_navigator.dart';
import '../../main/widgets/main_bottom_nav_bar.dart';
import '../../task/cubit/task_cubit.dart';
import '../../widgets/velora/velora.dart';
import '../cubit/checkin_cubit.dart';
import '../../../core/i18n/tr.dart';

/// Check-in tab: the open monthly sign-off and past check-ins.
class CheckInTabView extends StatelessWidget {
  const CheckInTabView({super.key});

  Future<void> _start(BuildContext context, ComplianceFormListItemModel form) async {
    final submitted = await AppNavigator.openCheckInFlow(
      context,
      formId: form.id,
      periodLabel: form.periodLabel,
    );
    if (submitted == true && context.mounted) {
      context.read<CheckInCubit>().load();
      context.read<TaskCubit>().loadTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CheckInCubit, CheckInState>(
      builder: (context, state) {
        final current = state.pending.isNotEmpty ? state.pending.first : null;
        return VeloraPage(
          underTabBar: true,
          onRefresh: () => context.read<CheckInCubit>().load(),
          header: VeloraHeader(
            title: current != null ? tr('{0} sign-off', [current.periodLabel]) : tr('Check-in'),
            subtitle: tr('Your check-in with the office'),
          ),
          children: [
            if (state.hasError)
              VeloraErrorState(
                message: state.errorMessage ?? tr('We couldn\'t load your check-ins.'),
                onRetry: () => context.read<CheckInCubit>().load(),
              )
            else if (state.isLoading || state.status == CheckInStatus.initial)
              VeloraLoadingState(message: tr('Loading your check-ins…'))
            else ...[
              if (current != null)
                _OverviewCard(form: current, onStart: () => _start(context, current))
              else
                VeloraDoneCard(
                  title: tr('You\'re all caught up'),
                  message: tr('There\'s no check-in to sign right now. We\'ll let you know when the next one opens.'),
                ),
              if (state.pending.length > 1)
                VeloraCard(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SectionCaption(tr('Also open'), padding: EdgeInsets.only(top: 8, bottom: 4)),
                      for (final form in state.pending.skip(1))
                        VeloraListRow(
                          leading: IconTile(
                            VeloraIcons.clipboardCheck,
                            tone: form.isOverdue ? IconTileTone.amber : IconTileTone.mint,
                            size: 36,
                            iconSize: 16,
                            radius: 11,
                          ),
                          title: form.periodLabel,
                          subtitle: form.isOverdue ? tr('Overdue') : form.status,
                          onTap: () => _start(context, form),
                        ),
                    ],
                  ),
                ),
              _HistoryCard(records: state.history),
              VeloraCard(
                child: Row(
                  children: [
                    const IconTile(VeloraIcons.phone),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr('Need help with this?'), style: VeloraText.body(14, weight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(tr('The office can walk you through it.'), style: VeloraText.subtitle),
                        ],
                      ),
                    ),
                    VeloraTextLink(
                      label: tr('Message'),
                      size: 13,
                      onTap: () => AppNavigator.openInbox(context),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.form, required this.onStart});

  final ComplianceFormListItemModel form;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return VeloraCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(form.periodLabel, style: VeloraText.display(20))),
              const SizedBox(width: 10),
              StatusPill(
                form.isOverdue ? tr('Overdue') : (form.status.isEmpty ? tr('Due') : form.status),
                tone: form.isOverdue ? PillTone.danger : PillTone.warn,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            tr('Answer a few questions about the month and sign. It\'s what releases your pay. About 1 minute.'),
            style: VeloraText.body(13, color: VeloraColors.muted, height: 1.5),
          ),
          const SizedBox(height: 14),
          _Step(
            number: 1,
            active: true,
            title: tr('You answer and sign'),
            subtitle: tr('Sign as soon as you can after the month ends'),
          ),
          _Step(
            number: 2,
            title: tr('The office confirms your days'),
            subtitle: tr('Hospital days are taken out automatically'),
          ),
          _Step(
            number: 3,
            title: tr('You get paid'),
            subtitle: tr('Direct deposit on the next payday'),
            last: true,
          ),
          const SizedBox(height: 14),
          VeloraButton(label: tr('Review & sign'), onPressed: onStart),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    required this.subtitle,
    this.active = false,
    this.last = false,
  });

  final int number;
  final String title;
  final String subtitle;
  final bool active;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active ? VeloraColors.amber : VeloraColors.mint,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$number',
                    style: VeloraText.display(
                      13,
                      color: active ? VeloraColors.amberInk : VeloraColors.teal,
                    ),
                  ),
                ),
                if (!last)
                  Expanded(child: Container(width: 2, color: VeloraColors.line)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 4 : 14, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: VeloraText.body(14, weight: FontWeight.w700)),
                  Text(subtitle, style: VeloraText.subtitle),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.records});

  final List<ComplianceHistoryRecordModel> records;

  @override
  Widget build(BuildContext context) {
    return VeloraCard(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCaption(
            tr('Past check-ins'),
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            trailing: VeloraTextLink(
              label: tr('See pay'),
              onTap: () => AppNavigator.goToTab(context, MainTab.pay),
            ),
          ),
          if (records.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(tr('No past check-ins yet.'), style: VeloraText.subtitle),
            )
          else
            for (final record in records.take(6))
              VeloraListRow(
                leading: IconTile(
                  record.submittedAt != null ? VeloraIcons.check : VeloraIcons.alertCircle,
                  tone: record.submittedAt != null ? IconTileTone.good : IconTileTone.amber,
                  size: 36,
                  iconSize: 16,
                  radius: 11,
                ),
                title: record.periodLabel,
                subtitle: record.submittedAt != null
                    ? tr('Signed {0}', [VeloraFormat.monthDay(record.submittedAt!.toLocal())])
                    : record.status,
                showChevron: false,
              ),
        ],
      ),
    );
  }
}
