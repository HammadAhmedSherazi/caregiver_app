import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/utils/velora_format.dart';
import '../../../data/models/api/visit_model.dart';
import '../../../data/models/home_dashboard_model.dart';
import '../../../data/models/task_page_model.dart';
import '../../../data/repositories/client_repository.dart';
import '../../clients/view/client_profile_view.dart';
import '../../../data/models/api/velora/velora_models.dart';
import '../../main/app_action_router.dart';
import '../../main/app_navigator.dart';
import '../../main/widgets/main_bottom_nav_bar.dart';
import '../../task/cubit/task_cubit.dart';
import '../../task/cubit/task_state.dart';
import '../../time/cubit/time_cubit.dart';
import '../../time/view/fix_visit_view.dart';
import '../../time/visit_summary.dart';
import '../../widgets/get_request_view.dart';
import '../../widgets/velora/velora.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../widgets/clock_out_sheet.dart';
import '../../../core/i18n/tr.dart';

/// Home tab: greeting, the visit card (clock in / timer / clock out),
/// this week, what needs attention, report a change and pay.
///
/// Data: `GET /dashboard` (HomeCubit), `GET /visits` (TimeCubit) and the
/// task page (TaskCubit: compliance forms, document requests, payroll).
class HomeTabView extends StatefulWidget {
  const HomeTabView({super.key});

  @override
  State<HomeTabView> createState() => _HomeTabViewState();
}

class _HomeTabViewState extends State<HomeTabView> {
  /// Summary shown in the visit card right after a successful clock-out.
  String? _savedSummary;

  Future<void> _refresh() async {
    await Future.wait([
      context.read<HomeCubit>().refresh(),
      context.read<TaskCubit>().loadTasks(),
      context.read<TimeCubit>().load(),
    ]);
  }

  Future<void> _clockOut(ActiveShift shift) async {
    final startedAt = shift.shiftStartedAt;
    final ok = await ClockOutSheet.show(context, shift: shift);
    if (!mounted || ok != true) return;

    final end = DateTime.now();
    setState(() {
      _savedSummary = startedAt == null
          ? tr('Sent to the office')
          : tr('{0} – {1} · {2} · sent to the office', [VeloraFormat.time(startedAt), VeloraFormat.time(end), VeloraFormat.duration(end.difference(startedAt))]);
    });
    unawaited(context.read<TimeCubit>().load());
  }

  @override
  Widget build(BuildContext context) {
    return PostActionListener<HomeCubit, HomeState>(
      listenWhen: (previous, current) =>
          current.errorMessage != null &&
          current.errorMessage != previous.errorMessage &&
          current.dashboard != null,
      errorMessage: (state) => state.errorMessage,
      onClearError: () => context.read<HomeCubit>().clearActionError(),
      child: BlocListener<HomeCubit, HomeState>(
        listenWhen: (previous, current) =>
            current.infoMessage != null &&
            current.infoMessage != previous.infoMessage,
        listener: (context, state) {
          final message = state.infoMessage;
          if (message == null || message.isEmpty) return;
          showVeloraToast(context, message);
          context.read<HomeCubit>().clearActionError();
        },
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            final dashboard = state.dashboard;
            return VeloraPage(
              underTabBar: true,
              onRefresh: _refresh,
              header: _HomeHeader(
                name: dashboard?.caregiverName ?? '',
                avatarUrl: dashboard?.avatarUrl,
                hasUnread: (dashboard?.unreadNotifications ?? 0) +
                        (dashboard?.unreadConversations ?? 0) >
                    0,
              ),
              children: [
                if (dashboard == null && state.hasError)
                  VeloraErrorState(
                    message: state.errorMessage ??
                        tr('We couldn\'t load your day. Check your connection and try again.'),
                    onRetry: () => context.read<HomeCubit>().loadDashboard(),
                  )
                else if (dashboard == null)
                  VeloraLoadingState(message: tr('Loading your day…'))
                else ...[
                  _VisitCard(
                    dashboard: dashboard,
                    savedSummary: _savedSummary,
                    onClockOut: _clockOut,
                    onStartAnother: () => setState(() => _savedSummary = null),
                  ),
                  if (dashboard.velora?.week case final week? when week.planType == 'set_days')
                    _SetDaysWeekCard(week: week)
                  else
                    const _ThisWeekCard(),
                  const _AttentionCard(),
                  VeloraCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    child: VeloraListRow(
                      showDivider: false,
                      leading: const IconTile(VeloraIcons.warning, tone: IconTileTone.danger),
                      title: tr('Report a change'),
                      subtitle: tr('Hospital stay, a fall, or you can\'t work'),
                      onTap: () => AppNavigator.openReportChange(context),
                    ),
                  ),
                  const _PayCard(),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.name,
    required this.avatarUrl,
    required this.hasUnread,
  });

  final String name;
  final String? avatarUrl;
  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    final first = VeloraFormat.firstName(name);
    final greeting = VeloraFormat.greeting();

    return VeloraHeader(
      gradient: true,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      overline: VeloraFormat.longDate(DateTime.now()),
      title: first.isEmpty ? greeting : '$greeting, $first',
      leading: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Image.asset(
                'assets/images/brand/velora_logo_light.png',
                height: 26,
                semanticLabel: 'VELORA',
              ),
            ),
          ),
          _CircleButton(
            semanticLabel: hasUnread ? tr('Inbox, new messages') : tr('Inbox'),
            onTap: () => AppNavigator.openInbox(context),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const VeloraIcon(VeloraIcons.bell, size: 20, color: Colors.white, strokeWidth: 1.8),
                if (hasUnread)
                  Positioned(
                    top: -2,
                    right: -1,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: VeloraColors.amber,
                        shape: BoxShape.circle,
                        border: Border.all(color: VeloraColors.brand, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _CircleButton(
            semanticLabel: tr('Your profile'),
            onTap: () => AppNavigator.openProfile(context),
            background: VeloraColors.mint,
            ring: true,
            child: avatarUrl != null && avatarUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      avatarUrl!,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const VeloraIcon(
                        VeloraIcons.user,
                        size: 24,
                        color: VeloraColors.teal,
                        strokeWidth: 1.8,
                      ),
                    ),
                  )
                : const VeloraIcon(VeloraIcons.user, size: 24, color: VeloraColors.teal, strokeWidth: 1.8),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.child,
    required this.onTap,
    required this.semanticLabel,
    this.background,
    this.ring = false,
  });

  final Widget child;
  final VoidCallback onTap;
  final String semanticLabel;
  final Color? background;
  final bool ring;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: Container(
        decoration: ring
            ? BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.55),
                    spreadRadius: 2,
                  ),
                ],
              )
            : null,
        child: Material(
          color: background ?? Colors.white.withValues(alpha: 0.1),
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(width: 44, height: 44, child: Center(child: child)),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Visit card
// ---------------------------------------------------------------------------

class _VisitCard extends StatefulWidget {
  const _VisitCard({
    required this.dashboard,
    required this.savedSummary,
    required this.onClockOut,
    required this.onStartAnother,
  });

  final HomeDashboard dashboard;
  final String? savedSummary;
  final ValueChanged<ActiveShift> onClockOut;
  final VoidCallback onStartAnother;

  @override
  State<_VisitCard> createState() => _VisitCardState();
}

class _VisitCardState extends State<_VisitCard> {
  bool _open = false;
  bool _clockingIn = false;

  Future<void> _clockIn(ActiveShift shift) async {
    setState(() => _clockingIn = true);
    await context.read<HomeCubit>().completeClockIn(
          clientName: shift.clientName,
          serviceType: shift.serviceType,
          clientId: shift.clientId,
          scheduleId: shift.scheduleId,
        );
    if (!mounted) return;
    setState(() {
      _clockingIn = false;
      _open = false;
    });
  }

  Future<void> _openClientProfile(String clientName) async {
    final client = await sl<ClientRepository>().findByName(clientName);
    if (!mounted) return;
    if (client == null) {
      showVeloraToast(context, tr('Client details aren\'t available right now.'));
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => ClientProfileView(client: client)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shift = widget.dashboard.activeShift;
    final saved = widget.savedSummary;
    final inProgress = shift?.isInProgress ?? false;

    final (caption, pill, tone) = switch ((inProgress, saved != null)) {
      (true, _) => (tr('Visit in progress'), tr('Clocked in'), PillTone.good),
      (false, true) => (tr('Today'), tr('Done'), PillTone.good),
      _ => (tr('Your client'), tr('Not clocked in'), PillTone.mute),
    };

    final Widget body;
    if (shift == null && saved == null) {
      body = Text(
        tr('No visits scheduled right now. When the office assigns your next visit it will show here.'),
        style: VeloraText.body(13.5, color: VeloraColors.muted, height: 1.45),
      );
    } else if (inProgress) {
      body = _OnShiftBody(shift: shift!, onClockOut: () => widget.onClockOut(shift));
    } else if (saved != null) {
      body = _SavedBody(summary: saved, onStartAnother: widget.onStartAnother);
    } else if (_open) {
      body = _OpenBody(
        shift: shift!,
        busy: _clockingIn,
        onClose: () => setState(() => _open = false),
        onClockIn: () => _clockIn(shift),
        onDetails: () => _openClientProfile(shift.clientName),
      );
    } else {
      body = _IdleBody(shift: shift!, onTap: () => setState(() => _open = true));
    }

    final laterToday = widget.dashboard.schedule
        .where((e) => e.clientName != shift?.clientName)
        .toList();

    return VeloraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCaption(
            caption,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (shift != null && saved == null) ...[
                  VeloraTextLink(
                    label: tr('Full screen'),
                    size: 12.5,
                    onTap: () => AppNavigator.openClock(context),
                  ),
                  const SizedBox(width: 10),
                ],
                StatusPill(pill, tone: tone),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: KeyedSubtree(key: ValueKey('$caption$_open${saved != null}'), child: body),
          ),
          if (laterToday.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final entry in laterToday)
              VeloraListRow(
                minHeight: 48,
                leading: InitialsTile(entry.initials, size: 36),
                title: entry.clientName,
                subtitle: tr('Also today · {0}', [entry.timeLabel]),
                showChevron: false,
              ),
          ],
        ],
      ),
    );
  }
}

class _IdleBody extends StatelessWidget {
  const _IdleBody({required this.shift, required this.onTap});

  final ActiveShift shift;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final time = shift.cardScheduleLabel;
    return Semantics(
      button: true,
      label: tr('Open visit with {0}', [shift.clientName]),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            InitialsTile(shift.clientInitials),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shift.clientName, style: VeloraText.body(17, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    time.isEmpty || time == '—'
                        ? tr('No set time · tap to start a visit')
                        : tr('{0} · tap to start a visit', [time]),
                    style: VeloraText.subtitle,
                  ),
                ],
              ),
            ),
            const IconTile(
              VeloraIcons.chevronRight,
              tone: IconTileTone.brand,
              iconSize: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _OpenBody extends StatelessWidget {
  const _OpenBody({
    required this.shift,
    required this.busy,
    required this.onClose,
    required this.onClockIn,
    required this.onDetails,
  });

  final ActiveShift shift;
  final bool busy;
  final VoidCallback onClose;
  final VoidCallback onClockIn;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            InitialsTile(shift.clientInitials),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shift.clientName, style: VeloraText.body(17, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    shift.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: VeloraText.subtitle,
                  ),
                ],
              ),
            ),
            Material(
              color: VeloraColors.subtle,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: VeloraColors.line),
              ),
              child: InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(12),
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: Center(
                    child: VeloraIcon(VeloraIcons.close, size: 16, color: VeloraColors.muted, strokeWidth: 2.2),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: VeloraColors.mintSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const VeloraIcon(VeloraIcons.clock, size: 17, color: VeloraColors.goodText, strokeWidth: 2.2),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${shift.serviceType} · ${shift.cardScheduleLabel}',
                  style: VeloraText.body(13, weight: FontWeight.w600, color: VeloraColors.goodText),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        VeloraButton(
          label: tr('Clock in now'),
          icon: VeloraIcons.clock,
          big: true,
          isLoading: busy,
          onPressed: onClockIn,
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: VeloraTextLink(label: tr('Client details'), onTap: onDetails),
        ),
      ],
    );
  }
}

class _OnShiftBody extends StatelessWidget {
  const _OnShiftBody({required this.shift, required this.onClockOut});

  final ActiveShift shift;
  final VoidCallback onClockOut;

  @override
  Widget build(BuildContext context) {
    final started = shift.shiftStartedAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            InitialsTile(shift.clientInitials, dark: true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('With {0}', [VeloraFormat.firstName(shift.clientName)]),
                    style: VeloraText.body(17, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    started != null
                        ? tr('Clocked in at {0}', [VeloraFormat.time(started)])
                        : (shift.startedAtLabel ?? tr('Clocked in')),
                    style: VeloraText.subtitle,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (started != null) ...[
          const SizedBox(height: 8),
          LiveShiftTimer(startedAt: started),
        ],
        const SizedBox(height: 12),
        VeloraButton(
          label: tr('Clock out'),
          icon: VeloraIcons.stop,
          big: true,
          variant: VeloraButtonVariant.outline,
          onPressed: onClockOut,
        ),
      ],
    );
  }
}

/// Pulsing dot + `1:18:32` shift timer (Home and the full-screen clock).
class LiveShiftTimer extends StatefulWidget {
  const LiveShiftTimer({super.key, required this.startedAt, this.size = 46});

  final DateTime startedAt;
  final double size;

  @override
  State<LiveShiftTimer> createState() => _LiveShiftTimerState();
}

class _LiveShiftTimerState extends State<LiveShiftTimer> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(widget.startedAt);
    return Semantics(
      liveRegion: false,
      label: tr('Time on shift {0}', [VeloraFormat.duration(elapsed)]),
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(color: VeloraColors.live, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                VeloraFormat.timer(elapsed),
                style: VeloraText.display(widget.size, letterSpacing: -0.03),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedBody extends StatelessWidget {
  const _SavedBody({required this.summary, required this.onStartAnother});

  final String summary;
  final VoidCallback onStartAnother;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const IconTile(VeloraIcons.check, tone: IconTileTone.good, size: 50, iconSize: 24, radius: 15),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr('Visit saved'), style: VeloraText.body(17, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(summary, style: VeloraText.subtitle),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        VeloraTextLink(label: tr('Start another visit'), size: 13.5, onTap: onStartAnother),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// This week
// ---------------------------------------------------------------------------

class _ThisWeekCard extends StatelessWidget {
  const _ThisWeekCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimeCubit, TimeState>(
      builder: (context, state) {
        final week = VisitPeriodSummary.week(state.visits);
        return VeloraCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionCaption(
                tr('This week'),
                trailing: VeloraTextLink(
                  label: tr('See hours'),
                  onTap: () => AppNavigator.goToTab(context, MainTab.time),
                ),
              ),
              if (state.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: LinearProgressIndicator(color: VeloraColors.teal, backgroundColor: VeloraColors.mint),
                )
              else if (state.hasError)
                Text(tr('Couldn\'t load this week\'s visits.'), style: VeloraText.subtitle)
              else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('${week.daysWorked}', style: VeloraText.display(34, letterSpacing: -0.03)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tr(week.daysWorked == 1 ? 'day worked · {0}' : 'days worked · {0}',
                            [VeloraFormat.duration(week.total)]),
                        style: VeloraText.body(14, weight: FontWeight.w600, color: VeloraColors.muted),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (final day in week.days)
                      Expanded(child: _DayDot(day: day)),
                  ],
                ),
                if (week.fixCount > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    week.fixCount == 1
                        ? tr('1 visit needs a clock-out time before it counts.')
                        : tr('{0} visits need a clock-out time before they count.',
                            [week.fixCount]),
                    style: VeloraText.body(12.5, color: VeloraColors.muted, height: 1.45),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}

/// "1 of 3 set days" — the client's plan has fixed days (planned
/// `week` block of `GET /dashboard`).
class _SetDaysWeekCard extends StatelessWidget {
  const _SetDaysWeekCard({required this.week});

  final DashboardWeekModel week;

  @override
  Widget build(BuildContext context) {
    final of = week.of;
    final missed = week.missedNote;
    return VeloraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionCaption(
            tr('This week'),
            trailing: VeloraTextLink(
              label: tr('See hours'),
              onTap: () => AppNavigator.goToTab(context, MainTab.time),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${week.done}', style: VeloraText.display(34, letterSpacing: -0.03)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  of == null ? tr('set days done') : tr('of {0} set days', [of]),
                  style: VeloraText.body(14, weight: FontWeight.w600, color: VeloraColors.muted),
                ),
              ),
            ],
          ),
          if (of != null && of > 0) ...[
            const SizedBox(height: 8),
            VeloraProgressBar(value: (week.done / of).clamp(0, 1).toDouble()),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              for (final day in week.days) Expanded(child: _PlanDayDot(day: day)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            tr('Your client\'s plan has set days. Other days are off.'),
            style: VeloraText.body(12.5, color: VeloraColors.muted, height: 1.45),
          ),
          if (missed != null)
            VeloraTextLink(
              label: missed.label,
              size: 13,
              onTap: () => missed.action != null
                  ? AppActionRouter.open(context, missed.action!)
                  : AppNavigator.openReportChange(context),
            ),
        ],
      ),
    );
  }
}

class _PlanDayDot extends StatelessWidget {
  const _PlanDayDot({required this.day});

  final DashboardWeekDayModel day;

  @override
  Widget build(BuildContext context) {
    final today = day.state == 'today';
    final (bg, fg, mark, border) = switch (day.state) {
      'worked' => (VeloraColors.teal, Colors.white, '✓', null),
      'missed' => (VeloraColors.dangerBg, VeloraColors.dangerText, '✕', null),
      'needs_fix' => (VeloraColors.warnBg, VeloraColors.warnText, '!', null),
      'today' => (Colors.white, VeloraColors.brand, '${day.dayNumber}', VeloraColors.amber),
      _ => (Colors.transparent, VeloraColors.faint, '${day.dayNumber}', VeloraColors.line),
    };
    final label = today
        ? tr('Today')
        : day.date != null
            ? VeloraFormat.weekdayShort(day.date!)
            : day.weekdayShort;
    final stateLabel = switch (day.state) {
      'worked' => tr('worked'),
      'missed' => tr('missed'),
      'needs_fix' => tr('needs a clock-out'),
      'off' => tr('not a set day'),
      _ => tr('not worked'),
    };
    return Semantics(
      label: '$label: $stateLabel',
      excludeSemantics: true,
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(11),
              border: border != null ? Border.all(color: border, width: today ? 2 : 1) : null,
            ),
            child: Text(mark, style: VeloraText.body(12.5, weight: FontWeight.w700, color: fg)),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: VeloraText.body(
                10.5,
                weight: FontWeight.w600,
                color: today ? VeloraColors.brand : (day.state == 'missed' ? VeloraColors.dangerText : VeloraColors.caption),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({required this.day});

  final DayVisits day;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, mark, border) = day.needsFix
        ? (VeloraColors.warnBg, VeloraColors.warnText, '!', null)
        : day.worked
            ? (VeloraColors.teal, Colors.white, '✓', null)
            : day.isToday
                ? (Colors.white, VeloraColors.brand, '${day.date.day}', VeloraColors.amber)
                : (VeloraColors.muteBg, VeloraColors.chevron, day.isFuture ? '${day.date.day}' : '–', null);
    final label = day.isToday ? tr('Today') : VeloraFormat.weekdayShort(day.date);

    return Semantics(
      label: '$label: ${day.needsFix ? tr('needs a clock-out') : day.worked ? tr('worked') : tr('not worked')}',
      excludeSemantics: true,
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(11),
              border: border != null ? Border.all(color: border, width: 2) : null,
            ),
            child: Text(mark, style: VeloraText.body(12.5, weight: FontWeight.w700, color: fg)),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: VeloraText.body(
                10.5,
                weight: FontWeight.w600,
                color: day.isToday ? VeloraColors.brand : VeloraColors.caption,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Needs your attention
// ---------------------------------------------------------------------------

class _AttentionItem {
  const _AttentionItem({
    required this.icon,
    required this.tone,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final VeloraIcons icon;
  final IconTileTone tone;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
}

class _AttentionCard extends StatelessWidget {
  const _AttentionCard();

  /// Server-ordered `needs_attention` (VELORA `/dashboard`, planned).
  List<_AttentionItem> _serverItems(
    BuildContext context,
    List<NeedsAttentionItemModel> server,
  ) {
    return [
      for (final item in server)
        _AttentionItem(
          icon: switch (item.key) {
            'missed_clockout' => VeloraIcons.alertCircle,
            'id_expiring' => VeloraIcons.idCard,
            'check_in_opens' => VeloraIcons.clipboardCheck,
            _ => VeloraIcons.info,
          },
          tone: item.key == 'check_in_opens' ? IconTileTone.mint : IconTileTone.amber,
          title: item.title,
          subtitle: item.subtitle ?? '',
          onTap: () {
            final action = item.action;
            if (action != null) AppActionRouter.open(context, action);
          },
        ),
    ];
  }

  List<_AttentionItem> _items(
    BuildContext context,
    TaskPageData? tasks,
    List<VisitModel> visits,
    List<NeedsAttentionItemModel>? server,
  ) {
    if (server != null && server.isNotEmpty) return _serverItems(context, server);

    final items = <_AttentionItem>[];

    for (final visit in visits.where((v) => v.isMissingClockOut).take(3)) {
      items.add(
        _AttentionItem(
          icon: VeloraIcons.alertCircle,
          tone: IconTileTone.amber,
          title: tr('Missed clock-out · {0}', [VeloraFormat.shortDate(visit.clockInAt.toLocal())]),
          subtitle: tr('Tell us what time you left'),
          onTap: () => AppNavigator.openFixVisit(
            context,
            args: FixVisitArgs.fromVisit(visit),
          ),
        ),
      );
    }

    for (final task in tasks?.allTasks ?? const <TaskItem>[]) {
      switch (task.type) {
        case TaskItemType.complianceForm:
          items.add(
            _AttentionItem(
              icon: VeloraIcons.clipboardCheck,
              tone: task.status == TaskItemStatus.overdue
                  ? IconTileTone.amber
                  : IconTileTone.mint,
              title: task.title,
              subtitle: task.subtitle,
              onTap: () => AppNavigator.goToTab(context, MainTab.checkIn),
            ),
          );
        case TaskItemType.documentUpload:
          items.add(
            _AttentionItem(
              icon: VeloraIcons.idCard,
              tone: IconTileTone.amber,
              title: task.title,
              subtitle: task.subtitle,
              onTap: () => AppNavigator.openUpload(context),
            ),
          );
        case TaskItemType.visitSignature:
        case TaskItemType.visit:
          break;
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final server = context.select<HomeCubit, List<NeedsAttentionItemModel>?>(
      (cubit) => cubit.state.dashboard?.velora?.needsAttention,
    );
    return BlocBuilder<TaskCubit, TaskState>(
      builder: (context, taskState) {
        return BlocBuilder<TimeCubit, TimeState>(
          builder: (context, timeState) {
            final items = _items(context, taskState.data, timeState.visits, server);
            final loading = taskState.isLoading && taskState.data == null;

            return VeloraCard(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 10, 0, 4),
                    child: Row(
                      children: [
                        Text(tr('NEEDS YOUR ATTENTION'), style: VeloraText.caption),
                        const SizedBox(width: 8),
                        if (items.isNotEmpty) StatusPill('${items.length}', tone: PillTone.warn),
                      ],
                    ),
                  ),
                  if (loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: LinearProgressIndicator(color: VeloraColors.teal, backgroundColor: VeloraColors.mint),
                    )
                  else if (items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 14),
                      child: Row(
                        children: [
                          const IconTile(VeloraIcons.check, tone: IconTileTone.good, size: 36, iconSize: 17, radius: 11),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              tr('You\'re all caught up.'),
                              style: VeloraText.body(14, weight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    for (final item in items)
                      VeloraListRow(
                        leading: IconTile(item.icon, tone: item.tone),
                        title: item.title,
                        subtitle: item.subtitle,
                        onTap: item.onTap,
                      ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Pay
// ---------------------------------------------------------------------------

class _PayCard extends StatelessWidget {
  const _PayCard();

  @override
  Widget build(BuildContext context) {
    final nextPaydayFromServer = context.select<HomeCubit, NextPaydayModel?>(
      (cubit) => cubit.state.dashboard?.velora?.nextPayday,
    );
    return BlocBuilder<TaskCubit, TaskState>(
      buildWhen: (p, c) => p.data?.payroll != c.data?.payroll,
      builder: (context, state) {
        final payroll = state.data?.payroll;
        final latest = (payroll?.paystubs.isNotEmpty ?? false) ? payroll!.paystubs.first : null;
        // VELORA `next_payday` (planned) — shown only when the server sends it.
        final nextPayday = nextPaydayFromServer;
        if (nextPayday != null) {
          return VeloraCard(
            onTap: () => AppNavigator.goToTab(context, MainTab.pay),
            child: Row(
              children: [
                const IconTile(VeloraIcons.wallet, size: 48, radius: 14),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr('NEXT PAYDAY'), style: VeloraText.caption),
                      const SizedBox(height: 2),
                      Text(nextPayday.label, style: VeloraText.display(20)),
                      if (nextPayday.lastPaidLabel != null) ...[
                        const SizedBox(height: 2),
                        Text(nextPayday.lastPaidLabel!, style: VeloraText.subtitle),
                      ],
                    ],
                  ),
                ),
                const VeloraIcon(VeloraIcons.chevronRight, size: 16, color: VeloraColors.chevron, strokeWidth: 2.2),
              ],
            ),
          );
        }

        return VeloraCard(
          onTap: () => AppNavigator.goToTab(context, MainTab.pay),
          child: Row(
            children: [
              const IconTile(VeloraIcons.wallet, size: 48, radius: 14),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tr('PAY'), style: VeloraText.caption),
                    const SizedBox(height: 2),
                    Text(
                      latest != null ? latest.grossPay : tr('Paystubs'),
                      style: VeloraText.display(20),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      latest != null
                          ? tr('Latest: {0} · {1}', [latest.periodLabel, latest.status])
                          : (payroll != null ? tr('No paystubs yet') : tr('See your pay and paystubs')),
                      style: VeloraText.subtitle,
                    ),
                  ],
                ),
              ),
              const VeloraIcon(VeloraIcons.chevronRight, size: 16, color: VeloraColors.chevron, strokeWidth: 2.2),
            ],
          ),
        );
      },
    );
  }
}
