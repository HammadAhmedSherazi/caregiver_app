import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/api_error_message.dart';
import '../../../core/utils/velora_format.dart';
import '../../../data/models/api/velora/velora_models.dart';
import '../../../data/repositories/visit_repository.dart';
import '../../../data/models/api/visit_model.dart';
import '../../main/app_navigator.dart';
import '../../widgets/velora/velora.dart';
import '../../../core/i18n/tr.dart';

class FixVisitArgs {
  const FixVisitArgs({
    required this.visitId,
    required this.clientName,
    required this.clockInAt,
  });

  factory FixVisitArgs.fromVisit(VisitModel visit) => FixVisitArgs(
        visitId: visit.id,
        clientName: visit.clientName,
        clockInAt: visit.clockInAt.toLocal(),
      );

  final int visitId;
  final String clientName;
  final DateTime clockInAt;
}

/// "Missed clock-out" form.
///
/// Submits `POST /visits/{schedule}/fix-clockout` (🚧 PLANNED — NOT LIVE)
/// when `ApiConfig.veloraApiEnabled`; otherwise "Send to office" explains the
/// endpoint isn't available instead of pretending to submit.
///
/// The path id is the `visit_id` the contract's `fix_clockout` action
/// carries (see open question in the API report).
class FixVisitView extends StatefulWidget {
  const FixVisitView({super.key, required this.args});

  final FixVisitArgs args;

  @override
  State<FixVisitView> createState() => _FixVisitViewState();
}

class _FixVisitViewState extends State<FixVisitView> {
  static const _reasons = [
    'Forgot to tap out',
    'Phone died',
    'App problem',
    'Something else',
  ];

  TimeOfDay? _leftAt;
  String _reason = _reasons.first;
  bool _sending = false;

  static const _reasonValues = {
    'Forgot to tap out': FixClockoutReason.forgotToTapOut,
    'Phone died': FixClockoutReason.phoneDied,
    'App problem': FixClockoutReason.appProblem,
    'Something else': FixClockoutReason.somethingElse,
  };

  /// Picked time on the clock-in day; before the clock-in means after midnight.
  DateTime _leftAtDateTime() {
    final start = widget.args.clockInAt;
    final t = _leftAt!;
    var left = DateTime(start.year, start.month, start.day, t.hour, t.minute);
    if (!left.isAfter(start)) left = left.add(const Duration(days: 1));
    return left;
  }

  Future<void> _submit() async {
    if (!ApiConfig.veloraApiEnabled) {
      await showApiRequiredSheet(
        context,
        feature: tr('Clock-out corrections'),
        onContactOffice: () => AppNavigator.openInbox(context),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      final result = await sl<VisitRepository>().fixClockout(
        widget.args.visitId,
        FixClockoutRequest(
          leftAt: _leftAtDateTime(),
          reason: _reasonValues[_reason]!,
          note: _noteController.text,
          clockInAt: widget.args.clockInAt,
        ),
      );
      if (!mounted) return;
      showVeloraToast(
        context,
        [result.message, result.reviewEta].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _sending = false);
      showVeloraToast(context, apiErrorMessage(error));
    }
  }
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _leftAt ?? const TimeOfDay(hour: 15, minute: 0),
    );
    if (picked != null && mounted) setState(() => _leftAt = picked);
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.args;
    return VeloraScaffold(
      body: VeloraPage(
        header: VeloraHeader(
          title: tr('Missed clock-out'),
          subtitle: '${VeloraFormat.shortDate(args.clockInAt)} · ${args.clientName}',
          onBack: () => Navigator.of(context).pop(),
        ),
        children: [
          VeloraCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Column(
              children: [
                KeyValueRow(
                  showDivider: false,
                  label: tr('Clocked in'),
                  value: VeloraFormat.time(args.clockInAt),
                ),
                KeyValueRow(
                  label: tr('Clocked out'),
                  value: tr('Missing'),
                  valueColor: VeloraColors.warnText,
                ),
              ],
            ),
          ),
          VeloraCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  tr('What time did you leave?'),
                  style: VeloraText.body(13, weight: FontWeight.w700, color: VeloraColors.body),
                ),
                const SizedBox(height: 7),
                Material(
                  color: VeloraColors.subtle,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(VeloraRadii.field),
                    side: const BorderSide(color: VeloraColors.fieldBorder),
                  ),
                  child: InkWell(
                    onTap: _pickTime,
                    borderRadius: BorderRadius.circular(VeloraRadii.field),
                    child: SizedBox(
                      height: 52,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _leftAt?.format(context) ?? tr('Select a time'),
                                style: VeloraText.body(
                                  16,
                                  color: _leftAt == null ? VeloraColors.faint : VeloraColors.ink,
                                ),
                              ),
                            ),
                            const VeloraIcon(VeloraIcons.clock, size: 20, color: VeloraColors.ink),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  tr('What happened?'),
                  style: VeloraText.body(13, weight: FontWeight.w700, color: VeloraColors.body),
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, c) {
                    final w = (c.maxWidth - 8) / 2;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final reason in _reasons)
                          SizedBox(
                            width: w,
                            child: VeloraChoiceChip(
                              label: tr(reason),
                              expand: true,
                              selected: _reason == reason,
                              onTap: () => setState(() => _reason = reason),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                VeloraTextField(
                  controller: _noteController,
                  label: tr('Note for the office (optional)'),
                  maxLines: 3,
                  minLines: 3,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              tr('The office reviews time changes, usually within 1 business day. Your hours for this day count once it\'s approved.'),
              style: VeloraText.body(12.5, color: VeloraColors.muted, height: 1.5),
            ),
          ),
          VeloraButton(
            label: tr('Send to office'),
            isLoading: _sending,
            onPressed: _leftAt == null ? null : _submit,
          ),
        ],
      ),
    );
  }
}
