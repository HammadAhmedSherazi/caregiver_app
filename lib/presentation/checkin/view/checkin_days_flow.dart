import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/i18n/tr.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/utils/velora_format.dart';
import '../../../data/models/api/compliance_form_model.dart';
import '../../../data/models/api/velora/velora_models.dart';
import '../../home/widgets/clock_out_sheet.dart' show DateField;
import '../../main/app_navigator.dart';
import '../../main/widgets/main_bottom_nav_bar.dart';
import '../../task/cubit/task_cubit.dart';
import '../../widgets/velora/velora.dart';

/// "STEP n OF m" row with Save & exit / Exit and the amber progress bar,
/// shared by both check-in flows.
class CheckInStepHeader extends StatelessWidget {
  const CheckInStepHeader({
    super.key,
    required this.step,
    required this.stepCount,
    required this.exitLabel,
    required this.onExit,
  });

  final int step;
  final int stepCount;
  final String exitLabel;
  final VoidCallback? onExit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                tr('STEP {0} OF {1}', [step, stepCount]),
                style: VeloraText.body(12.5, weight: FontWeight.w700, color: VeloraColors.amber, letterSpacing: 1),
              ),
            ),
            Material(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
              child: InkWell(
                onTap: onExit,
                borderRadius: BorderRadius.circular(11),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  child: Text(exitLabel, style: VeloraText.body(13, weight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        VeloraProgressBar(
          value: step / stepCount,
          height: 6,
          color: VeloraColors.amber,
          track: Colors.white.withValues(alpha: 0.14),
        ),
      ],
    );
  }
}

/// The design's check-in: questions → your days → review & sign → sent.
///
/// Runs when `GET /compliance-forms/{id}` returns the planned `check_in`
/// block (MOBILE_API_VELORA.md §8). Clock-in caregivers get answers
/// pre-filled from their clock-outs; live-in caregivers (DHS monthly, MICH
/// twice a month) answer everything here. Hospital dates mark those days
/// on the calendar and lock them; any other day can be tapped to cycle
/// worked → not worked → hospital. "Save & exit" stores a draft
/// (`PUT …/draft`), submit sends the typed name (`POST …/submit`).
class CheckInDaysFlow extends StatefulWidget {
  const CheckInDaysFlow({
    super.key,
    required this.formId,
    required this.periodLabel,
    required this.detail,
    required this.checkIn,
    this.clientName,
    this.initialName = '',
  });

  final int formId;
  final String periodLabel;
  final ComplianceFormDetailModel detail;
  final CheckInDetailModel checkIn;
  final String? clientName;
  final String initialName;

  @override
  State<CheckInDaysFlow> createState() => _CheckInDaysFlowState();
}

class _CheckInDaysFlowState extends State<CheckInDaysFlow> {
  static const _stepCount = 3;

  int _step = 0; // 0 questions, 1 days, 2 sign, 3 done
  bool _busy = false;

  bool? _hospital;
  DateTime? _hospitalFrom;
  DateTime? _hospitalTo;
  bool? _careGap;
  bool? _missed;
  final _careGapController = TextEditingController();
  final _missedController = TextEditingController();
  final _notesController = TextEditingController();
  late final TextEditingController _nameController;
  bool _agree = false;

  /// Server day states; [_edits] holds the days the caregiver tapped.
  late final Map<DateTime, CheckInDayState> _serverDays;
  final _edits = <DateTime, CheckInDayState>{};

  CheckInSubmitExtensionModel? _result;

  CheckInMode get _mode => widget.detail.velora?.mode ?? CheckInMode.clocks;
  bool get _clocks => _mode == CheckInMode.clocks;

  String get _client => widget.clientName?.split(' ').first ?? tr('your client');

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _serverDays = {
      for (final d in widget.checkIn.days) VeloraFormat.dateOnly(d.date): d.state,
    };
    final prefill = widget.checkIn.prefill;
    if (prefill != null) {
      final hospital = prefill.hospital;
      if (hospital != null) {
        _hospital = hospital.wasInHospital;
        _hospitalFrom = hospital.from;
        _hospitalTo = hospital.to;
      }
      _careGap = prefill.careNotGiven?.answer;
      _careGapController.text = prefill.careNotGiven?.details ?? '';
      _missed = prefill.missedOrLate?.answer;
      _missedController.text = prefill.missedOrLate?.details ?? '';
      _notesController.text = prefill.additionalNotes ?? '';
    }
  }

  @override
  void dispose() {
    _careGapController.dispose();
    _missedController.dispose();
    _notesController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------ period / days

  List<DateTime> get _periodDays {
    final days = _serverDays.keys.toList()..sort();
    if (days.isNotEmpty) return days;
    final start = widget.detail.velora?.periodStart;
    final end = widget.detail.velora?.periodEnd;
    if (start == null || end == null) return const [];
    return [
      for (var d = VeloraFormat.dateOnly(start); !d.isAfter(end); d = DateTime(d.year, d.month, d.day + 1)) d,
    ];
  }

  DateTime? get _periodStart => _periodDays.isEmpty ? null : _periodDays.first;
  DateTime? get _periodEnd => _periodDays.isEmpty ? null : _periodDays.last;

  bool get _hospitalRangeValid =>
      _hospitalFrom != null && _hospitalTo != null && !_hospitalTo!.isBefore(_hospitalFrom!);

  bool get _hospitalBad =>
      _hospitalFrom != null && _hospitalTo != null && _hospitalTo!.isBefore(_hospitalFrom!);

  bool _inHospital(DateTime day) =>
      _hospital == true &&
      _hospitalRangeValid &&
      !day.isBefore(VeloraFormat.dateOnly(_hospitalFrom!)) &&
      !day.isAfter(VeloraFormat.dateOnly(_hospitalTo!));

  /// What the caregiver sees before the hospital overlay.
  CheckInDayState _base(DateTime day) =>
      _edits[day] ?? _serverDays[day] ?? (_clocks ? CheckInDayState.notWorked : CheckInDayState.worked);

  CheckInDayState _stateOf(DateTime day) => _inHospital(day) ? CheckInDayState.hospital : _base(day);

  void _tapDay(DateTime day) {
    if (_inHospital(day)) return;
    setState(() {
      final next = _base(day).next;
      if (next == _serverDays[day]) {
        _edits.remove(day);
      } else {
        _edits[day] = next;
      }
    });
  }

  CheckInCountsModel get _counts {
    var worked = 0, notWorked = 0, hospital = 0;
    for (final day in _periodDays) {
      switch (_stateOf(day)) {
        case CheckInDayState.worked:
          worked++;
        case CheckInDayState.notWorked:
          notWorked++;
        case CheckInDayState.hospital:
          hospital++;
      }
    }
    return CheckInCountsModel(worked: worked, notWorked: notWorked, hospital: hospital);
  }

  /// Days in the period covered by the hospital dates.
  int get _hospitalDaysInPeriod => _periodDays.where(_inHospital).length;

  String get _hospitalRange {
    final from = _hospitalFrom!, to = _hospitalTo!;
    return VeloraFormat.sameDay(from, to)
        ? VeloraFormat.monthDay(from)
        : '${VeloraFormat.monthDay(from)} – ${VeloraFormat.monthDay(to)}';
  }

  String _dayCount(int n) => n == 1 ? tr('1 day') : tr('{0} days', [n]);

  // ------------------------------------------------------------ answers

  CheckInAnswers get _answers => CheckInAnswers(
        hospital: _hospital == null
            ? null
            : _hospital!
                ? HospitalStayModel(wasInHospital: true, from: _hospitalFrom, to: _hospitalTo)
                : const HospitalStayModel.none(),
        careNotGiven: _careGap == null
            ? null
            : CheckInYesNoAnswer(answer: _careGap!, details: _careGapController.text),
        missedOrLate: _missed == null
            ? null
            : CheckInYesNoAnswer(answer: _missed!, details: _missedController.text),
        additionalNotes: _notesController.text,
      );

  bool get _answered =>
      _hospital != null && _careGap != null && _missed != null && (_hospital == false || _hospitalRangeValid);

  bool get _detailsMissing =>
      (_careGap == true && _careGapController.text.trim().isEmpty) ||
      (_missed == true && _missedController.text.trim().isEmpty);

  bool get _nameValid =>
      _nameController.text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length >= 2;

  List<CheckInDayModel> get _changedDays => [
        for (final e in _edits.entries)
          if (!_inHospital(e.key)) CheckInDayModel(date: e.key, state: e.value),
      ];

  // ------------------------------------------------------------ actions

  Future<void> _saveAndExit() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await context.read<TaskCubit>().saveCheckInDraft(
            widget.formId,
            CheckInDraftRequest(answers: _answers, changedDays: _changedDays),
          );
      if (!mounted) return;
      Navigator.of(context).pop(false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      showVeloraToast(context, tr('We couldn\'t save your answers. Please try again.'));
    }
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final saved = await context.read<TaskCubit>().submitCheckIn(
            widget.formId,
            CheckInSubmitRequest(
              answers: _answers,
              changedDays: _changedDays,
              signatureName: _nameController.text,
              confirmed: _agree,
            ),
          );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _result = saved.submitResult;
        _step = 3;
      });
    } on RequestValidationException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      showVeloraToast(context, tr(e.message));
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      showVeloraToast(context, tr('We couldn\'t send your check-in. Please try again.'));
    }
  }

  Future<void> _pickDate({required bool from}) async {
    final start = _periodStart ?? DateTime.now().subtract(const Duration(days: 60));
    final end = _periodEnd ?? DateTime.now();
    final current = from ? _hospitalFrom : _hospitalTo;
    final picked = await showDatePicker(
      context: context,
      initialDate: current == null || current.isBefore(start) || current.isAfter(end) ? start : current,
      firstDate: start,
      lastDate: end,
    );
    if (picked == null || !mounted) return;
    setState(() => from ? _hospitalFrom = picked : _hospitalTo = picked);
  }

  void _back() {
    if (_busy) return;
    if (_step == 0) {
      Navigator.of(context).pop(false);
    } else if (_step == 3) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _step--);
    }
  }

  // ------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final inFlow = _step < 3;
    final title = switch (_step) {
      0 => tr('A few questions'),
      1 => tr('Your days'),
      2 => tr('Review & sign'),
      _ => tr('All done'),
    };
    final subtitle = switch (_step) {
      1 => tr('Tap any day that\'s wrong'),
      2 => tr('Last step before it goes to the office'),
      3 => tr('{0} · sent to the office', [widget.periodLabel]),
      _ => widget.clientName == null
          ? tr('{0} check-in', [widget.periodLabel])
          : '${widget.periodLabel} · ${widget.clientName}',
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: VeloraScaffold(
        body: VeloraPage(
          header: VeloraHeader(
            title: title,
            subtitle: subtitle,
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            leading: inFlow
                ? CheckInStepHeader(
                    step: _step + 1,
                    stepCount: _stepCount,
                    exitLabel: tr('Save & exit'),
                    onExit: _busy ? null : _saveAndExit,
                  )
                : null,
          ),
          footer: inFlow ? _footer() : null,
          children: switch (_step) {
            0 => _questionsStep(),
            1 => _daysStep(),
            2 => _signStep(),
            _ => _doneStep(),
          },
        ),
      ),
    );
  }

  Widget _footer() {
    final (blockedLabel, blocked) = switch (_step) {
      0 when !_answered => (tr('Answer all 3 to continue'), true),
      0 when _detailsMissing => (tr('Add details to continue'), true),
      2 when !_agree => (tr('Confirm to submit'), true),
      2 when !_nameValid => (tr('Type your first and last name'), true),
      _ => ('', false),
    };
    final label = blocked ? blockedLabel : (_step == 2 ? tr('Submit check-in') : tr('Continue'));
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: VeloraButton(
            label: tr('Back'),
            variant: VeloraButtonVariant.ghost,
            onPressed: _busy ? null : _back,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: VeloraButton(
            label: label,
            isLoading: _busy && _step == 2,
            onPressed: blocked || _busy ? null : (_step == 2 ? _submit : () => setState(() => _step++)),
          ),
        ),
      ],
    );
  }

  String get _periodPhrase {
    final start = _periodStart, end = _periodEnd;
    if (_mode == CheckInMode.liveInMich && start != null && end != null) {
      return tr('from {0} to {1}', [VeloraFormat.monthDay(start), VeloraFormat.monthDay(end)]);
    }
    return tr('in {0}', [widget.periodLabel]);
  }

  List<Widget> _questionsStep() {
    return [
      if (_clocks && widget.checkIn.prefill != null)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: VeloraNote(
            boxed: false,
            text: tr('Filled in from your answers at each clock-out. Change anything that isn\'t right.'),
          ),
        ),
      _QuestionCard(
        text: tr('Was {0} in the hospital or a nursing home at any time {1}?', [_client, _periodPhrase]),
        value: _hospital,
        onChanged: (v) => setState(() => _hospital = v),
        expanded: _hospital == true
            ? _HospitalBox(
                from: _hospitalFrom,
                to: _hospitalTo,
                onPickFrom: () => _pickDate(from: true),
                onPickTo: () => _pickDate(from: false),
                message: _hospitalRangeValid
                    ? tr('{0} ({1}) will be marked as hospital days and taken out of your time automatically. You don\'t need to change anything else.',
                        [_hospitalRange, _dayCount(_hospitalDaysInPeriod)])
                    : null,
                invalid: _hospitalBad,
              )
            : null,
      ),
      _QuestionCard(
        text: tr('Were there any days {0} needed care and didn\'t get it?', [_client]),
        value: _careGap,
        onChanged: (v) => setState(() => _careGap = v),
        expanded: _careGap == true
            ? VeloraTextField(
                controller: _careGapController,
                hint: tr('Which days, and why?'),
                maxLines: 3,
                minLines: 3,
                onChanged: (_) => setState(() {}),
              )
            : null,
      ),
      _QuestionCard(
        text: tr('Did you miss or run late for any visits?'),
        value: _missed,
        onChanged: (v) => setState(() => _missed = v),
        expanded: _missed == true
            ? VeloraTextField(
                controller: _missedController,
                hint: tr('Which days, and why?'),
                maxLines: 3,
                minLines: 3,
                onChanged: (_) => setState(() {}),
              )
            : null,
      ),
      VeloraCard(
        child: VeloraTextField(
          controller: _notesController,
          label: tr('Anything else the office should know about {0}?', [_client]),
          hint: tr('Optional'),
          maxLines: 4,
          minLines: 3,
        ),
      ),
    ];
  }

  List<Widget> _daysStep() {
    final counts = _counts;
    final start = _periodStart;
    final hospitalWorked = _periodDays.where((d) => _inHospital(d) && _base(d) == CheckInDayState.worked).length;
    final hours = _clocks ? widget.checkIn.hoursRemovedFor(hospitalWorked) : null;
    return [
      VeloraCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: Text(widget.periodLabel.toUpperCase(), style: VeloraText.caption)),
                Text(tr('Tap a day to change it'), style: VeloraText.body(12, color: VeloraColors.muted)),
              ],
            ),
            const SizedBox(height: 10),
            if (start == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(tr('No days to show for this check-in.'), style: VeloraText.subtitle),
              )
            else
              CheckInCalendar(
                month: DateTime(start.year, start.month),
                inPeriod: (d) => _serverDays.isEmpty ? _periodDays.contains(d) : _serverDays.containsKey(d),
                stateOf: _stateOf,
                onTap: _tapDay,
              ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _Legend(color: VeloraColors.teal, label: tr('Worked')),
                _Legend(color: VeloraColors.muteBg, label: tr('Not worked'), bordered: true),
                _Legend(color: VeloraColors.dangerStrong, label: tr('Hospital')),
              ],
            ),
          ],
        ),
      ),
      VeloraCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _Count(value: counts.worked, label: tr('Worked')),
            _Count(value: counts.notWorked, label: tr('Not worked')),
            _Count(value: counts.hospital, label: tr('Hospital'), color: VeloraColors.dangerText),
          ],
        ),
      ),
      if (_hospital == true && _hospitalRangeValid)
        VeloraNote(
          icon: VeloraIcons.check,
          text: hours != null && hospitalWorked > 0
              ? tr('Adjusted for the hospital stay: {0} (about {1} hrs) removed from pay and billing.',
                  [_dayCount(_hospitalDaysInPeriod), hours.toStringAsFixed(1)])
              : tr('Adjusted for the hospital stay: {0} removed from pay and billing.', [_dayCount(_hospitalDaysInPeriod)]),
        ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          _clocks
              ? tr('Pulled from your clock-ins. Change any day that isn\'t right.')
              : tr('Live-in: every day is marked worked unless you change it.'),
          style: VeloraText.body(12.5, color: VeloraColors.muted, height: 1.5),
        ),
      ),
    ];
  }

  List<Widget> _signStep() {
    final counts = _counts;
    final yes = [_careGap, _missed].where((a) => a == true).length;
    final confirmation = widget.checkIn.confirmationText ??
        tr('I confirm the care I\'ve reported for {0} is true and accurate.', [widget.periodLabel]);
    return [
      VeloraCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          children: [
            KeyValueRow(showDivider: false, label: tr('Period'), value: widget.periodLabel),
            if (widget.clientName != null) KeyValueRow(label: tr('Client'), value: widget.clientName!),
            KeyValueRow(label: tr('Days worked'), value: '${counts.worked}'),
            KeyValueRow(
              label: tr('Hospital days'),
              value: _hospital == true && _hospitalRangeValid
                  ? tr('{0} · {1} removed', [_hospitalRange, counts.hospital])
                  : tr('None'),
            ),
            KeyValueRow(
              label: tr('Other answers'),
              value: yes == 0 ? tr('All no') : tr('{0} yes, details added', [yes]),
            ),
          ],
        ),
      ),
      VeloraCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => setState(() => _agree = !_agree),
              borderRadius: BorderRadius.circular(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _agree,
                      activeColor: VeloraColors.brand,
                      onChanged: (v) => setState(() => _agree = v ?? false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(confirmation, style: VeloraText.body(14, height: 1.45))),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              tr('Type your full name to sign'),
              style: VeloraText.body(13, weight: FontWeight.w700, color: VeloraColors.body),
            ),
            const SizedBox(height: 7),
            TextField(
              controller: _nameController,
              onChanged: (_) => setState(() {}),
              textCapitalization: TextCapitalization.words,
              style: VeloraText.display(20, weight: FontWeight.w600, color: VeloraColors.brand),
              decoration: VeloraTextField.decoration(hint: tr('Your full name')),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _doneStep() {
    final counts = _result?.counts ?? _counts;
    final payLabel = _result?.payLabel ?? widget.detail.velora?.payLabel;
    final receipt = _result?.receiptAvailable ?? false;
    return [
      VeloraDoneCard(
        title: tr('Check-in sent'),
        message: payLabel == null
            ? tr('Thanks. The office has your {0} check-in.', [widget.periodLabel])
            : tr('You\'re on track to be paid {0}.', [payLabel]),
        details: Column(
          children: [
            KeyValueRow(showDivider: false, label: tr('Days worked'), value: '${counts.worked}'),
            KeyValueRow(label: tr('Hospital days removed'), value: '${counts.hospital}'),
            if (receipt) KeyValueRow(label: tr('Copy saved'), value: tr('Docs › From the office')),
          ],
        ),
        actions: [
          if (receipt)
            VeloraTextLink(
              label: tr('View my receipt'),
              size: 13.5,
              icon: VeloraIcons.document,
              onTap: () => AppNavigator.openCheckInReceipt(
                context,
                formId: widget.formId,
                periodLabel: widget.periodLabel,
              ),
            ),
        ],
      ),
      VeloraButton(
        label: tr('See my pay'),
        onPressed: () {
          Navigator.of(context).pop(true);
          AppNavigator.selectTab(MainTab.pay);
        },
      ),
      VeloraButton(
        label: tr('Done'),
        variant: VeloraButtonVariant.ghost,
        onPressed: () => Navigator.of(context).pop(true),
      ),
    ];
  }
}

/// Month grid, Monday first. Days outside the check-in period are greyed
/// (a MICH half-month still shows the whole month).
class CheckInCalendar extends StatelessWidget {
  const CheckInCalendar({
    super.key,
    required this.month,
    required this.inPeriod,
    required this.stateOf,
    required this.onTap,
  });

  final DateTime month;
  final bool Function(DateTime day) inPeriod;
  final CheckInDayState Function(DateTime day) stateOf;
  final ValueChanged<DateTime> onTap;

  static const _heads = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final lead = first.weekday - 1;
    return GridView.count(
      crossAxisCount: 7,
      mainAxisSpacing: 5,
      crossAxisSpacing: 5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        for (final h in _heads)
          Center(child: Text(h, style: VeloraText.body(10.5, weight: FontWeight.w700, color: VeloraColors.caption))),
        for (var i = 0; i < lead; i++) const SizedBox.shrink(),
        for (var d = 1; d <= daysInMonth; d++) _day(DateTime(month.year, month.month, d)),
      ],
    );
  }

  Widget _day(DateTime day) {
    final active = inPeriod(day);
    final state = stateOf(day);
    final (bg, fg) = !active
        ? (Colors.white, VeloraColors.faint)
        : switch (state) {
            CheckInDayState.worked => (VeloraColors.teal, Colors.white),
            CheckInDayState.notWorked => (VeloraColors.muteBg, VeloraColors.chevron),
            CheckInDayState.hospital => (VeloraColors.dangerStrong, Colors.white),
          };
    final stateLabel = !active
        ? tr('not in this check-in')
        : switch (state) {
            CheckInDayState.worked => tr('worked'),
            CheckInDayState.notWorked => tr('not worked'),
            CheckInDayState.hospital => tr('hospital'),
          };
    return Semantics(
      button: active,
      label: '${VeloraFormat.monthDay(day)}, $stateLabel',
      excludeSemantics: true,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: active ? BorderSide.none : const BorderSide(color: VeloraColors.muteBg),
        ),
        child: InkWell(
          onTap: active ? () => onTap(day) : null,
          borderRadius: BorderRadius.circular(10),
          child: Center(
            child: Text('${day.day}', style: VeloraText.body(13, weight: FontWeight.w700, color: fg)),
          ),
        ),
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.text, required this.value, required this.onChanged, this.expanded});

  final String text;
  final bool? value;
  final ValueChanged<bool> onChanged;
  final Widget? expanded;

  @override
  Widget build(BuildContext context) {
    return VeloraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(text, style: VeloraText.body(15, weight: FontWeight.w700, height: 1.4)),
          const SizedBox(height: 12),
          YesNoToggle(value: value, onChanged: onChanged),
          if (expanded != null) ...[const SizedBox(height: 12), expanded!],
        ],
      ),
    );
  }
}

/// Amber "Admitted / Came home" block (`.adj`).
class _HospitalBox extends StatelessWidget {
  const _HospitalBox({
    required this.from,
    required this.to,
    required this.onPickFrom,
    required this.onPickTo,
    required this.message,
    required this.invalid,
  });

  final DateTime? from;
  final DateTime? to;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final String? message;
  final bool invalid;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: VeloraColors.noteBg,
        border: Border.all(color: VeloraColors.noteBorder),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(tr('From when to when?'),
              style: VeloraText.body(13, weight: FontWeight.w700, color: VeloraColors.noteLabel)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: DateField(label: tr('Admitted'), value: from, onTap: onPickFrom)),
              const SizedBox(width: 8),
              Expanded(child: DateField(label: tr('Came home'), value: to, onTap: onPickTo)),
            ],
          ),
          if (message != null) ...[const SizedBox(height: 10), VeloraNote(boxed: false, text: message!)],
          if (invalid) ...[
            const SizedBox(height: 10),
            Text(
              tr('The "came home" date needs to be on or after the admitted date.'),
              style: VeloraText.body(12.5, color: VeloraColors.dangerText),
            ),
          ],
        ],
      ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.value, required this.label, this.color = VeloraColors.ink});

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$value', style: VeloraText.display(24, color: color)),
          Text(label, style: VeloraText.body(11.5, weight: FontWeight.w600, color: VeloraColors.muted)),
        ],
      ),
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
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: bordered ? Border.all(color: VeloraColors.fieldBorder) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: VeloraText.body(12, color: VeloraColors.muted)),
      ],
    );
  }
}
