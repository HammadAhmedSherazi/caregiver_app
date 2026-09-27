import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/network/api_config.dart';
import '../../../data/repositories/visit_repository.dart';
import '../../../data/models/api/velora/velora_models.dart';
import '../../../data/models/home_dashboard_model.dart';
import '../../widgets/velora/velora.dart';
import '../cubit/home_cubit.dart';
import '../cubit/home_state.dart';
import '../../../core/i18n/tr.dart';

/// "Before you go" bottom sheet shown when the caregiver taps Clock out.
///
/// Sends `POST /visits/clock-out` through [HomeCubit.endShift].
///
/// * Planned API on (`ApiConfig.veloraApiEnabled`): the answers go in the
///   contract fields `hospital` / `care_not_given` and `notes` stays the
///   caregiver's own note.
/// * Planned API off (today): those fields don't exist on the live API, so
///   the answers are appended to `notes` so the office still receives them.
///
/// Services: with the planned API on, the 6 quick picks come from
/// `GET /services/catalog` (`summary`) and are sent as `services[]`.
/// Otherwise (or if the catalog can't load) care tasks toggle through the
/// existing visit-task API.
class ClockOutSheet extends StatefulWidget {
  const ClockOutSheet({super.key, required this.shift});

  final ActiveShift shift;

  /// Returns `true` when the clock-out succeeded.
  static Future<bool?> show(BuildContext context, {required ActiveShift shift}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      barrierColor: const Color(0x73091815),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(VeloraRadii.sheet)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<HomeCubit>(),
        child: ClockOutSheet(shift: shift),
      ),
    );
  }

  @override
  State<ClockOutSheet> createState() => _ClockOutSheetState();
}

class _ClockOutSheetState extends State<ClockOutSheet> {
  bool? _hospital;
  bool? _careGap;
  DateTime? _hospitalFrom;
  DateTime? _hospitalTo;
  final _careGapController = TextEditingController();
  final _notesController = TextEditingController();
  ServiceCatalogModel? _catalog;
  final _services = <String>{};

  @override
  void initState() {
    super.initState();
    if (ApiConfig.veloraApiEnabled) _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      final catalog = await sl<VisitRepository>().getServiceCatalog();
      if (mounted && catalog.summary.isNotEmpty) setState(() => _catalog = catalog);
    } catch (_) {
      // Falls back to the visit care tasks.
    }
  }

  @override
  void dispose() {
    _careGapController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _hospitalDatesValid =>
      _hospitalFrom != null &&
      _hospitalTo != null &&
      !_hospitalTo!.isBefore(_hospitalFrom!);

  bool get _ready =>
      _careGap != null &&
      (_hospital == false || (_hospital == true && _hospitalDatesValid));

  int get _hospitalDays =>
      _hospitalDatesValid ? _hospitalTo!.difference(_hospitalFrom!).inDays + 1 : 0;

  Future<void> _pickDate({required bool from}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (from ? _hospitalFrom : _hospitalTo) ?? now,
      firstDate: now.subtract(const Duration(days: 60)),
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    setState(() => from ? _hospitalFrom = picked : _hospitalTo = picked);
  }

  ClockOutAnswers _answers() => ClockOutAnswers(
        hospital: _hospital == true
            ? HospitalStayModel(
                wasInHospital: true,
                from: _hospitalFrom,
                to: _hospitalTo,
              )
            : const HospitalStayModel.none(),
        careNotGiven: _careGap == true,
        services: _services.toList(),
      );

  String _composeNotes() {
    final lines = <String>[];
    final note = _notesController.text.trim();
    if (note.isNotEmpty) lines.add(note);

    if (_hospital == true && _hospitalDatesValid) {
      lines.add(
        'Hospital/nursing home since last visit: Yes '
        '(${_date(_hospitalFrom!)} – ${_date(_hospitalTo!)})',
      );
    } else {
      lines.add('Hospital/nursing home since last visit: No');
    }

    final gap = _careGapController.text.trim();
    lines.add(
      _careGap == true
          ? 'Care needed but not given: Yes${gap.isEmpty ? '' : ' – $gap'}'
          : 'Care needed but not given: No',
    );
    return lines.join('\n');
  }

  static String _date(DateTime d) => '${d.month}/${d.day}/${d.year}';

  Future<void> _clockOut() async {
    final cubit = context.read<HomeCubit>();
    final structured = ApiConfig.veloraApiEnabled;
    final gap = _careGapController.text.trim();
    final ownNote = [
      _notesController.text.trim(),
      if (_careGap == true && gap.isNotEmpty) 'Care not given: $gap',
    ].where((l) => l.isNotEmpty).join('\n');
    await cubit.endShift(
      visitId: widget.shift.visitId,
      scheduleId: widget.shift.scheduleId,
      notes: structured ? ownNote : _composeNotes(),
      answers: structured ? _answers() : null,
    );
    if (!mounted) return;
    final failed = cubit.state.errorMessage != null;
    Navigator.of(context).pop(!failed);
  }

  @override
  Widget build(BuildContext context) {
    final firstName = widget.shift.clientName.split(' ').first;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SheetGrabber(),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: Text(tr('Before you go'), style: VeloraText.display(21))),
                  VeloraTextLink(
                    label: tr('Not yet'),
                    size: 13.5,
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _Question(
                text: tr('Was {0} in the hospital or a nursing home since your last visit?', [firstName]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    YesNoToggle(
                      value: _hospital,
                      onChanged: (v) => setState(() => _hospital = v),
                    ),
                    if (_hospital == true) ...[
                      const SizedBox(height: 10),
                      _HospitalDates(
                        from: _hospitalFrom,
                        to: _hospitalTo,
                        onPickFrom: () => _pickDate(from: true),
                        onPickTo: () => _pickDate(from: false),
                        days: _hospitalDays,
                        invalidRange: _hospitalFrom != null &&
                            _hospitalTo != null &&
                            !_hospitalDatesValid,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _Question(
                text: tr('Was there any care {0} needed that you couldn\'t give?', [firstName]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    YesNoToggle(
                      value: _careGap,
                      onChanged: (v) => setState(() => _careGap = v),
                    ),
                    if (_careGap == true) ...[
                      const SizedBox(height: 10),
                      VeloraTextField(
                        controller: _careGapController,
                        hint: tr('What couldn\'t you do, and why?'),
                        maxLines: 3,
                        minLines: 3,
                      ),
                    ],
                  ],
                ),
              ),
              if (_catalog case final catalog?) ...[
                const SizedBox(height: 14),
                _servicesPrompt(),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    for (final service in catalog.summary)
                      VeloraChoiceChip(
                        label: service.label,
                        selected: _services.contains(service.id),
                        onTap: () => setState(() {
                          if (!_services.remove(service.id)) _services.add(service.id);
                        }),
                      ),
                  ],
                ),
              ] else if (widget.shift.careTasks.isNotEmpty) ...[
                const SizedBox(height: 14),
                _servicesPrompt(),
                const SizedBox(height: 8),
                BlocBuilder<HomeCubit, HomeState>(
                  buildWhen: (p, c) =>
                      p.dashboard?.activeShift?.careTasks !=
                      c.dashboard?.activeShift?.careTasks,
                  builder: (context, state) {
                    final tasks =
                        state.dashboard?.activeShift?.careTasks ?? widget.shift.careTasks;
                    return Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        for (final task in tasks)
                          VeloraChoiceChip(
                            label: task.label,
                            selected: task.isCompleted,
                            onTap: () =>
                                context.read<HomeCubit>().toggleCareTask(task.id),
                          ),
                      ],
                    );
                  },
                ),
              ],
              const SizedBox(height: 14),
              VeloraTextField(
                controller: _notesController,
                label: tr('Anything else the office should know? (optional)'),
                hint: tr('e.g. {0} seemed more tired than usual', [firstName]),
                maxLines: 3,
                minLines: 2,
              ),
              const SizedBox(height: 16),
              BlocBuilder<HomeCubit, HomeState>(
                buildWhen: (p, c) => p.isClockingOut != c.isClockingOut,
                builder: (context, state) {
                  return VeloraButton(
                    label: _ready ? tr('Clock out') : tr('Answer both questions'),
                    icon: _ready ? VeloraIcons.stop : null,
                    big: true,
                    isLoading: state.isClockingOut,
                    onPressed: _ready ? _clockOut : null,
                  );
                },
              ),
              const SizedBox(height: 10),
              Text(
                tr('Clocking out confirms today\'s visit and answers are true.'),
                textAlign: TextAlign.center,
                style: VeloraText.body(11.5, color: VeloraColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _servicesPrompt() => Text.rich(
      TextSpan(
        text: tr('What did you help with today? '),
        children: [
          TextSpan(
            text: tr('(tap any)'),
            style: VeloraText.body(13, weight: FontWeight.w500, color: VeloraColors.muted),
          ),
        ],
      ),
      style: VeloraText.body(13, weight: FontWeight.w700, color: VeloraColors.body),
    );

class _Question extends StatelessWidget {
  const _Question({required this.text, required this.child});

  final String text;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(text, style: VeloraText.body(15, weight: FontWeight.w700, height: 1.4)),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

/// Amber "From / To" date block shown when the hospital answer is Yes.
class _HospitalDates extends StatelessWidget {
  const _HospitalDates({
    required this.from,
    required this.to,
    required this.onPickFrom,
    required this.onPickTo,
    required this.days,
    required this.invalidRange,
  });

  final DateTime? from;
  final DateTime? to;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final int days;
  final bool invalidRange;

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
          Row(
            children: [
              Expanded(child: DateField(label: tr('From'), value: from, onTap: onPickFrom)),
              const SizedBox(width: 8),
              Expanded(child: DateField(label: tr('To'), value: to, onTap: onPickTo)),
            ],
          ),
          if (days > 0) ...[
            const SizedBox(height: 10),
            VeloraNote(
              boxed: false,
              text: days == 1
                  ? tr('1 day will be reported to the office as hospital days with this clock-out.')
                  : tr('{0} days will be reported to the office as hospital days with this clock-out.',
                      [days]),
            ),
          ],
          if (invalidRange) ...[
            const SizedBox(height: 10),
            Text(
              tr('The "To" date needs to be on or after the "From" date.'),
              style: VeloraText.body(12.5, color: VeloraColors.dangerText),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tappable date box used inside amber callouts (`.fld` with date input).
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.labelColor = VeloraColors.noteLabel,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    final v = value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: VeloraText.body(12, weight: FontWeight.w700, color: labelColor)),
        const SizedBox(height: 5),
        Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: VeloraColors.fieldBorder),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 46,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        v == null ? tr('Select date') : '${v.month}/${v.day}/${v.year}',
                        style: VeloraText.body(
                          14,
                          color: v == null ? VeloraColors.faint : VeloraColors.ink,
                        ),
                      ),
                    ),
                    const VeloraIcon(VeloraIcons.calendar, size: 16, color: VeloraColors.muted),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
