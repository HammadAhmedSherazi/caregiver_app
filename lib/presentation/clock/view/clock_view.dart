import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/i18n/tr.dart';
import '../../../core/utils/velora_format.dart';
import '../../../data/models/home_dashboard_model.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../home/cubit/home_cubit.dart';
import '../../home/cubit/home_state.dart';
import '../../home/view/home_tab_view.dart' show LiveShiftTimer;
import '../../home/widgets/clock_out_sheet.dart';
import '../../main/app_navigator.dart';
import '../../main/widgets/main_bottom_nav_bar.dart';
import '../../profile/cubit/profile_cubit.dart';
import '../../profile/cubit/profile_state.dart';
import '../../time/cubit/time_cubit.dart';
import '../../widgets/velora/velora.dart';

/// Full-screen clock in / out — the design's `Clock` page (the same visit
/// Home clocks in and out inline).
///
/// States: ready → on shift → clock-out questions (the shared
/// [ClockOutSheet]: services + hospital / care questions) → clocked out.
/// Live-in caregivers don't clock in: they see the exemption card and go to
/// their check-in instead (`live_in` from `GET /me`; the "approved through"
/// date is the planned `live_in_exemption`).
class ClockView extends StatefulWidget {
  const ClockView({super.key});

  @override
  State<ClockView> createState() => _ClockViewState();
}

class _ClockViewState extends State<ClockView> {
  bool _clockingIn = false;

  /// Set after a successful clock-out: (clocked in, clocked out).
  (DateTime?, DateTime)? _done;

  @override
  void initState() {
    super.initState();
    final profile = context.read<ProfileCubit>();
    if (profile.state.data == null && !profile.state.isLoading) {
      unawaited(profile.loadProfile(user: context.read<AuthCubit>().state.user));
    }
  }

  Future<void> _clockIn(ActiveShift shift) async {
    setState(() => _clockingIn = true);
    await context.read<HomeCubit>().completeClockIn(
          clientName: shift.clientName,
          serviceType: shift.serviceType,
          clientId: shift.clientId,
          scheduleId: shift.scheduleId,
        );
    if (mounted) setState(() => _clockingIn = false);
  }

  Future<void> _clockOut(ActiveShift shift) async {
    final startedAt = shift.shiftStartedAt;
    final ok = await ClockOutSheet.show(context, shift: shift);
    if (!mounted || ok != true) return;
    setState(() => _done = (startedAt, DateTime.now()));
    unawaited(context.read<TimeCubit>().load());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, profileState) {
        return BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            final shift = state.dashboard?.activeShift;
            final liveIn = profileState.data?.isLiveIn ?? false;
            final title = liveIn
                ? tr('Your visits')
                : _done != null
                    ? tr('Visit saved')
                    : (shift?.isInProgress ?? false)
                        ? tr('On shift')
                        : tr('Clock in');
            final subtitle = shift == null
                ? VeloraFormat.longDate(DateTime.now())
                : '${shift.clientName} · ${VeloraFormat.shortDate(DateTime.now())}';
            return VeloraScaffold(
              body: VeloraPage(
                header: VeloraHeader(
                  title: title,
                  subtitle: subtitle,
                  onBack: () => Navigator.of(context).pop(),
                ),
                children: liveIn
                    ? _liveIn(profileState.data?.liveInApprovedThrough)
                    : _done != null
                        ? _clockedOut(_done!)
                        : shift == null
                            ? [
                                VeloraEmptyState(
                                  title: tr('No visit to clock in to'),
                                  message: tr('No visits scheduled right now. When the office assigns your next visit it will show here.'),
                                  icon: VeloraIcons.clock,
                                ),
                              ]
                            : shift.isInProgress
                                ? _onShift(shift)
                                : _ready(shift),
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _liveIn(DateTime? approvedThrough) {
    return [
      VeloraCard(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StatusPill(approvedThrough != null ? tr('Live-in · approved') : tr('Live-in'), tone: PillTone.info),
            const SizedBox(height: 12),
            Text(tr('You don\'t need to clock in'), style: VeloraText.display(20)),
            const SizedBox(height: 8),
            Text(
              approvedThrough != null
                  ? tr('You live with your client and your live-in exemption is approved through {0}. Instead of questions after each visit, you\'ll answer them in your check-in: once a month for DHS, twice a month for MICH.',
                      [VeloraFormat.longDate(approvedThrough)])
                  : tr('You live with your client. Instead of questions after each visit, you\'ll answer them in your check-in: once a month for DHS, twice a month for MICH.'),
              style: VeloraText.body(14, color: VeloraColors.muted, height: 1.5),
            ),
            const SizedBox(height: 16),
            VeloraButton(
              label: tr('Go to check-in'),
              variant: VeloraButtonVariant.ghost,
              onPressed: () => AppNavigator.goToTab(context, MainTab.checkIn),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _ready(ActiveShift shift) {
    return [
      VeloraCard(
        child: Row(
          children: [
            InitialsTile(shift.clientInitials),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(shift.clientName, style: VeloraText.body(15, weight: FontWeight.w700)),
                  if (shift.address.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(shift.address, style: VeloraText.subtitle),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Center(
        child: Semantics(
          button: true,
          label: tr('Clock in'),
          excludeSemantics: true,
          child: Material(
            color: VeloraColors.brand,
            shape: const CircleBorder(side: BorderSide(color: VeloraColors.mint, width: 10)),
            elevation: 10,
            shadowColor: VeloraColors.brand.withValues(alpha: 0.35),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _clockingIn ? null : () => _clockIn(shift),
              child: SizedBox(
                width: 188,
                height: 188,
                child: _clockingIn
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const VeloraIcon(VeloraIcons.clock, size: 34, color: VeloraColors.amber),
                          const SizedBox(height: 6),
                          Text(tr('Clock in'), style: VeloraText.display(24, color: Colors.white)),
                          Text(
                            VeloraFormat.time(DateTime.now()),
                            style: VeloraText.body(13, weight: FontWeight.w600, color: VeloraColors.onHeaderMuted),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        tr('Your time goes straight to the office. No other app needed.'),
        textAlign: TextAlign.center,
        style: VeloraText.body(13, color: VeloraColors.muted, height: 1.5),
      ),
    ];
  }

  List<Widget> _onShift(ActiveShift shift) {
    final started = shift.shiftStartedAt;
    return [
      VeloraCard(
        padding: const EdgeInsets.fromLTRB(18, 26, 18, 22),
        child: Column(
          children: [
            StatusPill(tr('On shift'), tone: PillTone.good),
            const SizedBox(height: 6),
            if (started != null) LiveShiftTimer(startedAt: started, size: 54),
            Text(
              started != null
                  ? tr('Clocked in at {0}', [VeloraFormat.time(started)])
                  : (shift.startedAtLabel ?? tr('Clocked in')),
              style: VeloraText.body(13.5, color: VeloraColors.muted),
            ),
          ],
        ),
      ),
      VeloraButton(
        label: tr('Clock out'),
        icon: VeloraIcons.stop,
        big: true,
        variant: VeloraButtonVariant.outline,
        onPressed: () => _clockOut(shift),
      ),
    ];
  }

  List<Widget> _clockedOut((DateTime?, DateTime) done) {
    final (inAt, outAt) = done;
    return [
      VeloraDoneCard(
        title: tr('You\'re clocked out'),
        message: tr('Sent to the office'),
        details: Column(
          children: [
            if (inAt != null) KeyValueRow(showDivider: false, label: tr('Clocked in'), value: VeloraFormat.time(inAt)),
            KeyValueRow(showDivider: inAt != null, label: tr('Clocked out'), value: VeloraFormat.time(outAt)),
            if (inAt != null)
              KeyValueRow(label: tr('Time with your client'), value: VeloraFormat.duration(outAt.difference(inAt))),
            KeyValueRow(label: tr('Check-in questions'), value: tr('Answered')),
          ],
        ),
      ),
      VeloraButton(
        label: tr('Back to home'),
        onPressed: () => AppNavigator.goToTab(context, MainTab.home),
      ),
    ];
  }
}
