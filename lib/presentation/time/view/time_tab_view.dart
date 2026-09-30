import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/velora_format.dart';
import '../../../data/models/api/schedule_item_model.dart';
import '../../../data/models/api/velora/velora_models.dart';
import '../../../data/models/api/visit_model.dart';
import '../../main/app_action_router.dart';
import '../../main/app_navigator.dart';
import '../../main/widgets/main_bottom_nav_bar.dart';
import '../../widgets/velora/velora.dart';
import '../cubit/time_cubit.dart';
import '../visit_summary.dart';
import 'fix_visit_view.dart';
import '../../../core/i18n/tr.dart';

/// Time tab: this week's visits and the month calendar (`GET /visits`).
class TimeTabView extends StatefulWidget {
  const TimeTabView({super.key});

  @override
  State<TimeTabView> createState() => _TimeTabViewState();
}

class _TimeTabViewState extends State<TimeTabView> {
  bool _month = false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return BlocBuilder<TimeCubit, TimeState>(
      builder: (context, state) {
        final clients = state.visits.map((v) => v.clientName).toSet();
        return VeloraPage(
          underTabBar: true,
          onRefresh: () => context.read<TimeCubit>().load(),
          header: VeloraHeader(
            title: tr('Time'),
            subtitle: clients.length == 1
                ? tr('Your visits with {0}', [clients.first])
                : tr('Your visits'),
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
            bottom: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _HeaderSegmented(
                labels: [tr('This week'), VeloraFormat.monthName(now.month)],
                selected: _month ? 1 : 0,
                onChanged: (i) => setState(() => _month = i == 1),
              ),
            ),
          ),
          children: [
            if (state.hasError)
              VeloraErrorState(
                message: state.errorMessage ?? tr('We couldn\'t load your visits.'),
                onRetry: () => context.read<TimeCubit>().load(),
              )
            else if (state.isLoading || state.status == TimeStatus.initial)
              VeloraLoadingState(message: tr('Loading your visits…'))
            else if (_month)
              ..._monthChildren(context, VisitPeriodSummary.month(state.visits), now, state.month?.approvedHours)
            else if (state.week case final week? when week.plan?.isSetDays ?? false)
              ..._setDaysWeekChildren(week, state.upcoming)
            else
              ..._weekChildren(context, VisitPeriodSummary.week(state.visits), now, state.upcoming),
          ],
        );
      },
    );
  }

  List<Widget> _weekChildren(
    BuildContext context,
    VisitPeriodSummary week,
    DateTime now,
    List<ScheduleItemModel> upcoming,
  ) {
    final start = week.days.first.date;
    final end = week.days.last.date;
    final shown = week.days.where((d) => !d.isFuture).toList().reversed.toList();

    return [
      _SummaryCard(
        leftCaption: tr('Days worked'),
        left: '${week.daysWorked}',
        rightCaption: tr('Hours'),
        right: VeloraFormat.duration(week.total),
        note: '${VeloraFormat.monthDay(start)} – ${VeloraFormat.monthDay(end)}'
            '${week.fixCount > 0 ? ' · ${tr('Days missing a clock-out count once they\'re fixed.')}' : ''}',
      ),
      VeloraCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          children: [
            for (var i = 0; i < shown.length; i++)
              _DayRow(day: shown[i], showDivider: i > 0),
          ],
        ),
      ),
      if (upcoming.isNotEmpty) _UpcomingCard(items: upcoming),
    ];
  }

  /// Set-days plan (e.g. Mon, Wed, Fri) from the planned `GET /time/week`:
  /// off days are "Not a set day" and a missed set day asks why.
  List<Widget> _setDaysWeekChildren(TimeWeekModel week, List<ScheduleItemModel> upcoming) {
    final plan = week.plan!;
    final range = week.weekStart != null && week.weekEnd != null
        ? '${VeloraFormat.monthDay(week.weekStart!)} – ${VeloraFormat.monthDay(week.weekEnd!)}'
        : week.label;
    final shown = week.days;
    return [
      _SummaryCard(
        leftCaption: tr('Set days done'),
        left: week.daysOf == null ? '${week.daysDone}' : tr('{0} of {1}', [week.daysDone, week.daysOf]),
        rightCaption: tr('Hours'),
        right: week.hoursLabel ?? (week.hours == null ? '—' : tr('{0} hrs', [week.hours!.toStringAsFixed(1)])),
        note: [plan.label ?? tr('Your client\'s plan has set days'), range].join(' · '),
      ),
      VeloraCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          children: [
            for (var i = 0; i < shown.length; i++) _PlanDayRow(day: shown[i], showDivider: i > 0),
          ],
        ),
      ),
      if (week.footnote != null)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(week.footnote!, style: VeloraText.body(12.5, color: VeloraColors.muted, height: 1.45)),
        ),
      if (upcoming.isNotEmpty) _UpcomingCard(items: upcoming),
    ];
  }

  List<Widget> _monthChildren(
    BuildContext context,
    VisitPeriodSummary month,
    DateTime now,
    ApprovedHoursModel? approved,
  ) {
    final visits = month.days.expand((d) => d.visits).toList();
    final completed = visits.where((v) => v.clockOutAt != null).length;
    final rate = visits.isEmpty ? 0.0 : completed / visits.length;

    return [
      _SummaryCard(
        leftCaption: tr('Days worked'),
        left: '${month.daysWorked}',
        rightCaption: tr('Hours'),
        right: VeloraFormat.duration(month.total),
      ),
      if (approved != null && approved.limit > 0) _ApprovedHoursCard(hours: approved),
      VeloraCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionCaption(
              tr('Clock-ins completed'),
              trailing: StatusPill(
                tr('{0} of {1}', [completed, visits.length]),
                tone: rate >= 0.85 || visits.isEmpty ? PillTone.good : PillTone.warn,
              ),
            ),
            const SizedBox(height: 12),
            _ThresholdBar(value: rate, threshold: 0.85),
            const SizedBox(height: 6),
            Text(
              visits.isEmpty
                  ? tr('No visits yet this month.')
                  : tr('{0}% this month. Please keep every visit clocked in and out — the state checks that at least 85% are.', [(rate * 100).round()]),
              style: VeloraText.body(12.5, color: VeloraColors.muted, height: 1.45),
            ),
          ],
        ),
      ),
      VeloraCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionCaption('${VeloraFormat.monthName(now.month)} ${now.year}'),
            const SizedBox(height: 10),
            _MonthCalendar(month: month),
            const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _Legend(color: VeloraColors.teal, label: tr('Worked')),
                _Legend(color: VeloraColors.amber, label: tr('Needs a fix')),
                _Legend(color: VeloraColors.muteBg, label: tr('Not worked'), bordered: true),
              ],
            ),
          ],
        ),
      ),
    ];
  }
}

class _HeaderSegmented extends StatelessWidget {
  const _HeaderSegmented({
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: Semantics(
                selected: i == selected,
                button: true,
                child: Material(
                  color: i == selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  child: InkWell(
                    onTap: () => onChanged(i),
                    borderRadius: BorderRadius.circular(11),
                    child: SizedBox(
                      height: 42,
                      child: Center(
                        child: Text(
                          labels[i],
                          style: VeloraText.body(
                            14,
                            weight: FontWeight.w700,
                            color: i == selected ? VeloraColors.brand : VeloraColors.onHeaderMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.leftCaption,
    required this.left,
    required this.rightCaption,
    required this.right,
    this.note,
  });

  final String leftCaption;
  final String left;
  final String rightCaption;
  final String right;
  final String? note;

  Widget _stat(String caption, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(caption.toUpperCase(), style: VeloraText.caption),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: VeloraText.display(30, letterSpacing: -0.03)),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return VeloraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _stat(leftCaption, left)),
              const SizedBox(width: 12),
              Expanded(child: _stat(rightCaption, right)),
            ],
          ),
          if (note != null) ...[
            const SizedBox(height: 12),
            Text(note!, style: VeloraText.body(12.5, color: VeloraColors.muted, height: 1.4)),
          ],
        ],
      ),
    );
  }
}

/// "104.8 of 120 hrs" — the client's approved hours for the month.
class _ApprovedHoursCard extends StatelessWidget {
  const _ApprovedHoursCard({required this.hours});

  final ApprovedHoursModel hours;

  static String _h(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final nearLimit = hours.percentUsed >= 90;
    return VeloraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCaption(
            tr('Approved hours'),
            trailing: Text(
              tr('{0} of {1} hrs', [_h(hours.used), _h(hours.limit)]),
              style: VeloraText.body(13, weight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 12),
          VeloraProgressBar(
            value: (hours.used / hours.limit).clamp(0, 1).toDouble(),
            height: 10,
            color: nearLimit ? VeloraColors.dangerStrong : VeloraColors.amber,
          ),
          const SizedBox(height: 10),
          Text(
            hours.warning ??
                tr('{0} hours left this month. Hours past what your client\'s plan approves can\'t be paid, so we\'ll warn you before you reach the limit.',
                    [_h(hours.remaining)]),
            style: VeloraText.body(12.5, color: nearLimit ? VeloraColors.dangerText : VeloraColors.muted, height: 1.45),
          ),
        ],
      ),
    );
  }
}

/// One day of a set-days week, as the server describes it.
class _PlanDayRow extends StatelessWidget {
  const _PlanDayRow({required this.day, required this.showDivider});

  final TimeWeekDayModel day;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final offDay = day.state == 'not_set_day' || day.state == 'day_off';
    final missed = day.state == 'missed';
    final fix = day.state == 'missing_clockout' || day.state == 'pending_fix';
    final (tileBg, tileBorder, tileFg) = missed
        ? (VeloraColors.dangerBg, VeloraColors.dangerBg, VeloraColors.dangerText)
        : fix
            ? (VeloraColors.warnBg, VeloraColors.noteBorder, VeloraColors.warnText)
            : day.isToday
                ? (Colors.white, VeloraColors.amber, VeloraColors.brand)
                : (VeloraColors.subtle, VeloraColors.line, VeloraColors.ink);
    final tone = switch (day.state) {
      'sent' => PillTone.good,
      'missed' => PillTone.danger,
      'missing_clockout' || 'pending_fix' => PillTone.warn,
      'not_started' => PillTone.info,
      _ => PillTone.mute,
    };
    final visit = day.visit;
    final title = visit?.clockInAt != null
        ? '${VeloraFormat.time(visit!.clockInAt!)} – ${visit.clockOutAt != null ? VeloraFormat.time(visit.clockOutAt!) : '?'}'
        : switch (day.state) {
            'not_set_day' => tr('Not a set day'),
            'missed' => tr('Set day · no visit'),
            'not_started' => tr('Set day · today'),
            _ => day.stateLabel,
          };
    final detail = visit == null
        ? day.note
        : [visit.hoursLabel, visit.servicesLabel].whereType<String>().where((t) => t.isNotEmpty).join(' · ');
    final cta = day.cta;

    return Opacity(
      opacity: offDay ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: showDivider ? const Border(top: BorderSide(color: VeloraColors.line)) : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: tileBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tileBorder, width: day.isToday ? 2 : 1),
              ),
              child: Column(
                children: [
                  Text(
                    (day.date != null ? VeloraFormat.weekdayShort(day.date!) : day.weekdayShort).toUpperCase(),
                    style: VeloraText.body(10, weight: FontWeight.w700, color: tileFg),
                  ),
                  Text('${day.dayNumber}', style: VeloraText.display(18, color: tileFg)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: VeloraText.body(14.5,
                              weight: FontWeight.w700, color: offDay ? VeloraColors.chevron : VeloraColors.ink),
                        ),
                      ),
                      if (!offDay) ...[const SizedBox(width: 8), StatusPill(day.stateLabel, tone: tone)],
                    ],
                  ),
                  if (detail != null && detail.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(detail, style: VeloraText.subtitle),
                  ],
                  if (cta?.action != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: _SmallButton(label: cta!.label, onTap: () => AppActionRouter.open(context, cta.action!)),
                    ),
                  ] else if (missed)
                    VeloraTextLink(label: tr('Tell us why'), size: 13, onTap: () => AppNavigator.openReportChange(context))
                  else if (day.state == 'not_started' && day.isToday) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: _SmallButton(
                        label: tr('Clock in from Home'),
                        onTap: () => AppNavigator.goToTab(context, MainTab.home),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day, required this.showDivider});

  final DayVisits day;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final fix = day.needsFix;
    final (tileBg, tileBorder, tileFg) = fix
        ? (VeloraColors.warnBg, VeloraColors.noteBorder, VeloraColors.warnText)
        : day.isToday
            ? (Colors.white, VeloraColors.amber, VeloraColors.brand)
            : (VeloraColors.subtle, VeloraColors.line, VeloraColors.ink);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: showDivider ? const Border(top: BorderSide(color: VeloraColors.line)) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: tileBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tileBorder, width: day.isToday ? 2 : 1),
            ),
            child: Column(
              children: [
                Text(
                  VeloraFormat.weekdayShort(day.date).toUpperCase(),
                  style: VeloraText.body(10, weight: FontWeight.w700, color: fix ? tileFg : VeloraColors.caption),
                ),
                Text('${day.date.day}', style: VeloraText.display(18, color: tileFg)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: day.visits.isEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            day.isToday ? tr('Not started') : tr('Day off'),
                            style: VeloraText.body(14.5, weight: FontWeight.w700, color: VeloraColors.muted),
                          ),
                        ),
                        StatusPill(
                          day.isToday ? tr('Today') : tr('Not worked'),
                          tone: day.isToday ? PillTone.info : PillTone.mute,
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < day.visits.length; i++) ...[
                        if (i > 0) const SizedBox(height: 10),
                        _VisitLine(visit: day.visits[i]),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _VisitLine extends StatelessWidget {
  const _VisitLine({required this.visit});

  final VisitModel visit;

  @override
  Widget build(BuildContext context) {
    final start = VeloraFormat.time(visit.clockInAt);
    final out = visit.clockOutAt;
    final worked = visit.worked;

    final (label, tone) = visit.isMissingClockOut
        ? (tr('No clock-out'), PillTone.warn)
        : visit.isOpenToday
            ? (tr('In progress'), PillTone.info)
            : (tr('Sent'), PillTone.good);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                out != null ? '$start – ${VeloraFormat.time(out)}' : '$start – ?',
                style: VeloraText.body(14.5, weight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            StatusPill(label, tone: tone),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          visit.isMissingClockOut
              ? tr('The clock was never stopped for this visit.')
              : [
                  if (worked != null) VeloraFormat.duration(worked),
                  visit.clientName,
                ].join(' · '),
          style: VeloraText.subtitle,
        ),
        if (visit.isMissingClockOut) ...[
          const SizedBox(height: 8),
          _SmallButton(
            label: tr('Add clock-out time'),
            onTap: () => AppNavigator.openFixVisit(
              context,
              args: FixVisitArgs.fromVisit(visit),
            ),
          ),
        ] else if (visit.isOpenToday) ...[
          const SizedBox(height: 8),
          _SmallButton(
            label: tr('Clock out from Home'),
            onTap: () => AppNavigator.goToTab(context, MainTab.home),
          ),
        ],
      ],
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: VeloraColors.brand,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 40),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(label, style: VeloraText.body(13, weight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

class _ThresholdBar extends StatelessWidget {
  const _ThresholdBar({required this.value, required this.threshold});

  final double value;
  final double threshold;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final x = c.maxWidth * threshold;
        return SizedBox(
          height: 30,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              VeloraProgressBar(value: value, height: 10),
              Positioned(
                left: x - 1,
                top: 12,
                child: Container(width: 2, height: 8, color: VeloraColors.amberIcon),
              ),
              Positioned(
                left: x - 20,
                top: 19,
                width: 40,
                child: Text(
                  '${(threshold * 100).round()}%',
                  textAlign: TextAlign.center,
                  style: VeloraText.body(10.5, weight: FontWeight.w700, color: VeloraColors.warnText),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({required this.month});

  final VisitPeriodSummary month;

  @override
  Widget build(BuildContext context) {
    final first = month.days.first.date;
    final leading = first.weekday - 1;
    const heads = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return GridView.count(
      crossAxisCount: 7,
      mainAxisSpacing: 5,
      crossAxisSpacing: 5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final h in heads)
          Center(
            child: Text(h, style: VeloraText.body(10.5, weight: FontWeight.w700, color: VeloraColors.caption)),
          ),
        for (var i = 0; i < leading; i++) const SizedBox.shrink(),
        for (final day in month.days) _CalendarCell(day: day),
      ],
    );
  }
}

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({required this.day});

  final DayVisits day;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = day.needsFix
        ? (VeloraColors.amber, VeloraColors.amberInk, null)
        : day.worked
            ? (VeloraColors.teal, Colors.white, null)
            : day.isToday
                ? (Colors.white, VeloraColors.brand, VeloraColors.brand)
                : day.isFuture
                    ? (Colors.white, VeloraColors.chevron, VeloraColors.line)
                    : (VeloraColors.muteBg, VeloraColors.chevron, null);
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9),
        border: border != null ? Border.all(color: border, width: day.isToday ? 2 : 1) : null,
      ),
      child: Text('${day.date.day}', style: VeloraText.body(12, weight: FontWeight.w600, color: fg)),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, this.bordered = false});

  final Color color;
  final String label;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: bordered ? Border.all(color: VeloraColors.fieldBorder) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: VeloraText.body(11.5, color: VeloraColors.muted)),
      ],
    );
  }
}

/// Next scheduled visits from `GET /schedule?upcoming=1`.
class _UpcomingCard extends StatelessWidget {
  const _UpcomingCard({required this.items});

  final List<ScheduleItemModel> items;

  @override
  Widget build(BuildContext context) {
    final sorted = [...items]..sort((a, b) => a.scheduledStart.compareTo(b.scheduledStart));
    return VeloraCard(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCaption(tr('Coming up'), padding: EdgeInsets.only(top: 8, bottom: 2)),
          for (var i = 0; i < sorted.length && i < 6; i++)
            Builder(
              builder: (context) {
                final item = sorted[i];
                final start = item.scheduledStart.toLocal();
                final end = item.scheduledEnd.toLocal();
                return VeloraListRow(
                  showDivider: i > 0,
                  showChevron: false,
                  leading: Container(
                    width: 46,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: VeloraColors.mint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          VeloraFormat.weekdayShort(start).toUpperCase(),
                          style: VeloraText.body(10, weight: FontWeight.w700, color: VeloraColors.teal),
                        ),
                        Text('${start.day}', style: VeloraText.display(18, color: VeloraColors.brand)),
                      ],
                    ),
                  ),
                  title: '${VeloraFormat.time(start)} – ${VeloraFormat.time(end)}',
                  subtitle: [
                    item.clientName,
                    if (item.address.isNotEmpty) item.address,
                  ].join(' · '),
                );
              },
            ),
        ],
      ),
    );
  }
}
