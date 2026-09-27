import 'package:flutter/material.dart';

import '../../../core/utils/velora_format.dart';
import '../../../data/models/api/visit_model.dart';
import '../../main/app_navigator.dart';
import '../../widgets/velora/velora.dart';

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
/// UI ONLY — API REQUIRED: there is no endpoint to submit a corrected
/// clock-out time for review, so "Send to office" explains that instead of
/// pretending to submit.
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
          title: 'Missed clock-out',
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
                  label: 'Clocked in',
                  value: VeloraFormat.time(args.clockInAt),
                ),
                const KeyValueRow(
                  label: 'Clocked out',
                  value: 'Missing',
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
                  'What time did you leave?',
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
                                _leftAt?.format(context) ?? 'Select a time',
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
                  'What happened?',
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
                              label: reason,
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
                  label: 'Note for the office (optional)',
                  maxLines: 3,
                  minLines: 3,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'The office reviews time changes, usually within 1 business day. '
              'Your hours for this day count once it\'s approved.',
              style: VeloraText.body(12.5, color: VeloraColors.muted, height: 1.5),
            ),
          ),
          VeloraButton(
            label: 'Send to office',
            onPressed: _leftAt == null
                ? null
                : () => showApiRequiredSheet(
                      context,
                      feature: 'Clock-out corrections',
                      onContactOffice: () => AppNavigator.openInbox(context),
                    ),
          ),
        ],
      ),
    );
  }
}
