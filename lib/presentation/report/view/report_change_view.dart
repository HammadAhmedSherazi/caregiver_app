import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../home/widgets/clock_out_sheet.dart' show DateField;
import '../../main/app_navigator.dart';
import '../../widgets/velora/velora.dart';

class _ChangeType {
  const _ChangeType({
    required this.label,
    required this.hint,
    required this.icon,
    required this.tone,
    required this.noteLabel,
    this.noteHint = '',
    this.fromLabel,
    this.askDoctor = false,
  });

  final String label;
  final String hint;
  final VeloraIcons icon;
  final IconTileTone tone;
  final String noteLabel;
  final String noteHint;

  /// When set, the details step asks for a start date and optional end date.
  final String? fromLabel;
  final bool askDoctor;
}

const _types = [
  _ChangeType(
    label: 'Hospital or nursing home stay',
    hint: 'Your client was admitted somewhere',
    icon: VeloraIcons.hospital,
    tone: IconTileTone.danger,
    fromLabel: 'Admitted',
    noteLabel: 'Where is your client?',
    noteHint: 'e.g. hospital name and room',
  ),
  _ChangeType(
    label: 'A fall or injury',
    hint: 'Your client fell or got hurt',
    icon: VeloraIcons.warning,
    tone: IconTileTone.danger,
    askDoctor: true,
    noteLabel: 'What happened?',
    noteHint: 'Where, when, and how your client is doing now',
  ),
  _ChangeType(
    label: 'Your client\'s needs changed',
    hint: 'More help needed, new condition, new doctor',
    icon: VeloraIcons.pulse,
    tone: IconTileTone.amber,
    noteLabel: 'What\'s different?',
    noteHint: 'e.g. needs help walking now',
  ),
  _ChangeType(
    label: 'I can\'t work',
    hint: 'You\'re sick, traveling, or need time off',
    icon: VeloraIcons.calendar,
    tone: IconTileTone.amber,
    fromLabel: 'Starting',
    noteLabel: 'Anything we should know?',
    noteHint: 'Optional',
  ),
  _ChangeType(
    label: 'Address or phone changed',
    hint: 'For you or for your client',
    icon: VeloraIcons.pin,
    tone: IconTileTone.mint,
    noteLabel: 'New address or phone',
    noteHint: 'Include apartment number',
  ),
  _ChangeType(
    label: 'Your client is no longer with us',
    hint: 'Let us know, and we\'ll take care of the rest',
    icon: VeloraIcons.heart,
    tone: IconTileTone.mint,
    fromLabel: 'Date',
    noteLabel: 'Anything you\'d like us to know?',
    noteHint: 'Optional — you don\'t need to write anything',
  ),
  _ChangeType(
    label: 'Something else',
    hint: 'Tell us in your own words',
    icon: VeloraIcons.dots,
    tone: IconTileTone.mint,
    noteLabel: 'What\'s going on?',
  ),
];

/// Report a change: pick what happened → details.
///
/// UI ONLY — API REQUIRED: there is no endpoint for change reports, so
/// "Send to office" explains that and offers the Inbox. The emergency
/// banner dials 911 directly.
class ReportChangeView extends StatefulWidget {
  const ReportChangeView({super.key});

  @override
  State<ReportChangeView> createState() => _ReportChangeViewState();
}

class _ReportChangeViewState extends State<ReportChangeView> {
  _ChangeType? _selected;
  DateTime? _from;
  DateTime? _until;
  bool? _sawDoctor;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _select(_ChangeType? type) {
    setState(() {
      _selected = type;
      _from = null;
      _until = null;
      _sawDoctor = null;
      _noteController.clear();
    });
  }

  Future<void> _pickDate({required bool from}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (from ? _from : _until) ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() => from ? _from = picked : _until = picked);
  }

  Future<void> _call911() async {
    final uri = Uri(scheme: 'tel', path: '911');
    if (!await launchUrl(uri) && mounted) {
      showVeloraToast(context, 'Couldn\'t start the call. Please dial 911.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return PopScope(
      canPop: selected == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _select(null);
      },
      child: VeloraScaffold(
        body: VeloraPage(
          gap: 12,
          header: VeloraHeader(
            title: selected?.label ?? 'Report a change',
            subtitle: 'Tell the office what happened',
            onBack: () => selected == null ? Navigator.of(context).pop() : _select(null),
          ),
          children: selected == null ? _pickStep() : _detailsStep(selected),
        ),
      ),
    );
  }

  List<Widget> _pickStep() => [
        Material(
          color: VeloraColors.dangerBg,
          borderRadius: BorderRadius.circular(15),
          child: InkWell(
            onTap: _call911,
            borderRadius: BorderRadius.circular(15),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: Row(
                children: [
                  const VeloraIcon(VeloraIcons.phone, size: 20, color: Color(0xFF7E2A23), strokeWidth: 2),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Emergency? ',
                            style: VeloraText.body(13.5, weight: FontWeight.w700, color: const Color(0xFF7E2A23)),
                          ),
                          TextSpan(
                            text: 'Call 911 first, then tell us here.',
                            style: VeloraText.body(13.5, color: const Color(0xFF7E2A23)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SectionCaption('What happened?', padding: EdgeInsets.fromLTRB(2, 4, 2, 0)),
        for (final type in _types)
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: const BorderSide(color: VeloraColors.line),
            ),
            child: InkWell(
              onTap: () => _select(type),
              borderRadius: BorderRadius.circular(15),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(
                  children: [
                    IconTile(type.icon, tone: type.tone, size: 38, iconSize: 18, radius: 11),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(type.label, style: VeloraText.body(14.5, weight: FontWeight.w700)),
                          Text(type.hint, style: VeloraText.body(12, color: VeloraColors.muted)),
                        ],
                      ),
                    ),
                    const VeloraIcon(VeloraIcons.chevronRight, size: 16, color: VeloraColors.chevron, strokeWidth: 2.2),
                  ],
                ),
              ),
            ),
          ),
      ];

  List<Widget> _detailsStep(_ChangeType type) => [
        VeloraCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (type.fromLabel != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: DateField(
                        label: type.fromLabel!,
                        value: _from,
                        labelColor: VeloraColors.body,
                        onTap: () => _pickDate(from: true),
                      ),
                    ),
                    if (type.fromLabel != 'Date') ...[
                      const SizedBox(width: 10),
                      Expanded(
                        child: DateField(
                          label: 'Until',
                          value: _until,
                          labelColor: VeloraColors.body,
                          onTap: () => _pickDate(from: false),
                        ),
                      ),
                    ],
                  ],
                ),
                if (type.fromLabel != 'Date') ...[
                  const SizedBox(height: 6),
                  Text('Leave "Until" empty if it\'s still going on.',
                      style: VeloraText.body(12, color: VeloraColors.muted)),
                ],
                const SizedBox(height: 14),
              ],
              if (type.askDoctor) ...[
                Text(
                  'Did your client see a doctor or go to the ER?',
                  style: VeloraText.body(13, weight: FontWeight.w700, color: VeloraColors.body),
                ),
                const SizedBox(height: 8),
                YesNoToggle(value: _sawDoctor, onChanged: (v) => setState(() => _sawDoctor = v)),
                const SizedBox(height: 14),
              ],
              VeloraTextField(
                label: type.noteLabel,
                hint: type.noteHint,
                controller: _noteController,
                maxLines: 4,
                minLines: 3,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: VeloraTextLink(
                  label: 'Add a photo of paperwork (optional)',
                  size: 13.5,
                  icon: VeloraIcons.camera,
                  onTap: () => AppNavigator.openUpload(context, initialType: 'med'),
                ),
              ),
            ],
          ),
        ),
        VeloraButton(
          label: 'Send to office',
          icon: VeloraIcons.send,
          onPressed: () => showApiRequiredSheet(
            context,
            feature: 'Change reports',
            onContactOffice: () => AppNavigator.openInbox(context),
          ),
        ),
      ];
}
