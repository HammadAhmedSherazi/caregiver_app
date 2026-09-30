import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/velora_format.dart';
import '../../../data/models/api/compliance_form_model.dart';
import '../../../data/models/api/velora/velora_models.dart';
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
            title: current != null && (current.velora?.mode ?? CheckInMode.clocks) == CheckInMode.clocks
                ? tr('{0} sign-off', [current.periodLabel])
                : tr('Check-in'),
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
    final ext = form.velora;
    final mode = ext?.mode ?? CheckInMode.clocks;
    final clocks = mode == CheckInMode.clocks;
    final intro = switch (mode) {
      CheckInMode.clocks => ext == null
          ? tr('Answer a few questions about the month and sign. It\'s what releases your pay. About 1 minute.')
          : tr('You already answered the questions after each visit. Just look over your month and sign. About 1 minute.'),
      CheckInMode.liveInDhs =>
        tr('You live with your client, so instead of clocking in you answer here once a month. About 3 minutes.'),
      CheckInMode.liveInMich =>
        tr('Your client\'s plan (MICH) checks in twice a month: once for the 1st–15th, once for the 16th to the end.'),
    };
    final timeline = {for (final t in ext?.timeline ?? const <CheckInTimelineStepModel>[]) t.step: t};
    String? line(int step) => timeline[step]?.title ?? timeline[step]?.label;
    final pill = form.isOverdue
        ? tr('Overdue')
        : ext?.dueLabel ?? (form.status.isEmpty ? tr('Due') : form.status);

    return VeloraCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(form.periodLabel, style: VeloraText.display(20))),
              const SizedBox(width: 10),
              StatusPill(pill, tone: form.isOverdue ? PillTone.danger : PillTone.warn),
            ],
          ),
          const SizedBox(height: 6),
          Text(intro, style: VeloraText.body(13, color: VeloraColors.muted, height: 1.5)),
          const SizedBox(height: 14),
          if (mode == CheckInMode.liveInMich && ext?.periodShort != null) ...[
            VeloraNote(
              icon: VeloraIcons.calendar,
              text: tr('Twice a month · this check-in covers {0}', [ext!.periodShort!]),
            ),
            const SizedBox(height: 14),
          ],
          if (clocks && ext != null) ...[
            _Summary(ext: ext),
            const SizedBox(height: 14),
          ],
          _Step(
            number: 1,
            active: true,
            title: line(1) ?? (clocks ? tr('You review and sign') : tr('You answer and sign')),
            subtitle: timeline[1]?.subtitle ??
                (ext?.dueLabel != null ? tr('By {0}', [ext!.dueLabel!]) : tr('Sign as soon as you can after the month ends')),
          ),
          _Step(
            number: 2,
            title: line(2) ?? tr('The office confirms your days'),
            subtitle: timeline[2]?.subtitle ?? tr('Hospital days are taken out automatically'),
          ),
          _Step(
            number: 3,
            title: line(3) ?? tr('You get paid'),
            subtitle: timeline[3]?.subtitle ??
                (ext?.payLabel != null ? tr('{0} · direct deposit', [ext!.payLabel!]) : tr('Direct deposit on the next payday')),
            last: true,
          ),
          const SizedBox(height: 14),
          VeloraButton(label: clocks ? tr('Review & sign') : tr('Start check-in'), onPressed: onStart),
        ],
      ),
    );
  }
}

/// "Visits with answers · Hospital stays · Care not given" (clock-in mode).
class _Summary extends StatelessWidget {
  const _Summary({required this.ext});

  final ComplianceFormExtensionModel ext;

  @override
  Widget build(BuildContext context) {
    final done = ext.visitsWithAnswersDone;
    final total = ext.visitsWithAnswersTotal;
    final stays = ext.hospitalStays.where((h) => h.wasInHospital).toList();
    final careDays = ext.careNotGivenDays ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: VeloraColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          if (done != null && total != null)
            KeyValueRow(showDivider: false, label: tr('Visits with answers'), value: tr('{0} of {1}', [done, total])),
          KeyValueRow(
            showDivider: done != null && total != null,
            label: tr('Hospital stays reported'),
            value: stays.isEmpty
                ? tr('None')
                : stays.length == 1 && stays.first.summaryLine != null
                    ? stays.first.summaryLine!
                    : tr('{0} reported', [stays.length]),
          ),
          KeyValueRow(
            label: tr('Care not given'),
            value: careDays == 0 ? tr('None') : (careDays == 1 ? tr('1 day') : tr('{0} days', [careDays])),
          ),
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

  /// "Signed Sep 1 · paid Sep 11" when the planned fields are there.
  static String _subtitle(ComplianceHistoryRecordModel record) {
    final signed = record.velora?.signedAt ?? record.submittedAt;
    if (signed == null) return record.status;
    final paid = record.velora?.paidAt;
    return paid == null
        ? tr('Signed {0}', [VeloraFormat.monthDay(signed.toLocal())])
        : tr('Signed {0} · paid {1}', [VeloraFormat.monthDay(signed.toLocal()), VeloraFormat.monthDay(paid.toLocal())]);
  }

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
                subtitle: _subtitle(record),
                trailing: record.velora?.netPay != null
                    ? Text(VeloraFormat.money(record.velora!.netPay!), style: VeloraText.body(15, weight: FontWeight.w700))
                    : null,
                showChevron: record.velora?.payId != null,
                onTap: record.velora?.payId != null
                    ? () => AppNavigator.openPaystub(context, id: '${record.velora!.payId}')
                    : null,
              ),
        ],
      ),
    );
  }
}
