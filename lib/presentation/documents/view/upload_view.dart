import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_config.dart';
import '../../../core/utils/document_picker_service.dart';
import '../../../data/models/api/velora/velora_models.dart';
import '../../../data/models/selected_document.dart';
import '../../home/widgets/clock_out_sheet.dart' show DateField;
import '../../task/cubit/task_cubit.dart';
import '../../widgets/velora/velora.dart';
import '../../../core/i18n/tr.dart';

class _DocType {
  const _DocType(this.id, this.label, this.hint, this.icon, this.legacyType, this.plannedType);

  final String id;
  final String label;
  final String hint;
  final VeloraIcons icon;

  /// `type` on today's live `POST /documents`.
  final String legacyType;

  /// `type` once the planned API is on (MOBILE_API_VELORA.md §6).
  final DocumentUploadType plannedType;

  String get apiType => ApiConfig.veloraApiEnabled ? plannedType.value : legacyType;

  bool get needsExpiry => id == 'id' && ApiConfig.veloraApiEnabled;
}

const _types = [
  _DocType('id', 'Photo ID or driver\'s license', 'Front and back', VeloraIcons.idCard, 'ID',
      DocumentUploadType.photoId),
  _DocType('tax', 'Tax or pay form', 'W-4, MI-W4, direct deposit', VeloraIcons.document, 'Signed Form',
      DocumentUploadType.taxOrPayForm),
  _DocType('med', 'Doctor or hospital note', 'For your client or for you', VeloraIcons.plus, 'Other',
      DocumentUploadType.doctorOrHospitalNote),
  _DocType('state', 'Letter from DHS or the plan', 'Anything the state or insurance mailed you',
      VeloraIcons.mail, 'Mail/Letter', DocumentUploadType.stateLetter),
  _DocType('other', 'Something else', 'Tell the office what it is', VeloraIcons.dots, 'Other',
      DocumentUploadType.other),
];

enum _Step { type, capture, review, sent }

/// Upload to office: pick type → photo or file → check it → sent.
///
/// Uses the existing picker and `POST /documents`.
class UploadView extends StatefulWidget {
  const UploadView({
    super.key,
    this.initialType,
    this.replacesDocumentId,
    this.directDeposit = false,
  });

  /// One of `id`, `tax`, `med`, `state`, `other`.
  final String? initialType;

  /// The expiring document this upload replaces (from an `upload` action).
  final int? replacesDocumentId;

  /// Bank change from My info → `tax_or_pay_form` + `purpose: direct_deposit`.
  final bool directDeposit;

  @override
  State<UploadView> createState() => _UploadViewState();
}

class _UploadViewState extends State<UploadView> {
  final _picker = DocumentPickerService();
  final _notesController = TextEditingController();
  late _DocType _type = _types.firstWhere(
    (t) => t.id == widget.initialType,
    orElse: () => _types.first,
  );
  _Step _step = _Step.type;
  SelectedDocument? _document;
  DateTime? _expiresOn;
  bool _picking = false;
  bool _uploading = false;
  bool _uploadedAny = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pick(DocumentSource source) async {
    setState(() => _picking = true);
    try {
      final doc = await _picker.pickFromSource(source);
      if (!mounted) return;
      if (doc == null) {
        setState(() => _picking = false);
        return;
      }
      if (!doc.isWithinSizeLimit) {
        setState(() => _picking = false);
        showVeloraToast(context, tr('That file is too large. The limit is 10 MB.'));
        return;
      }
      setState(() {
        _document = doc;
        _picking = false;
        _step = _Step.review;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _picking = false);
      showVeloraToast(context, tr('Could not load that file. Please try again.'));
    }
  }

  Future<void> _pickExpiry() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresOn ?? now.add(const Duration(days: 365 * 4)),
      firstDate: now,
      lastDate: DateTime(now.year + 20),
    );
    if (picked != null && mounted) setState(() => _expiresOn = picked);
  }

  Future<void> _send() async {
    final doc = _document;
    if (doc == null || _uploading) return;
    if (_type.needsExpiry && _expiresOn == null) {
      showVeloraToast(context, tr('Enter the new expiration date.'));
      return;
    }
    setState(() => _uploading = true);

    final note = _notesController.text.trim();
    final notes = [
      if (_type.id == 'med' || _type.id == 'tax') _type.label,
      if (note.isNotEmpty) note,
    ].join(' – ');

    final isTax = _type.id == 'tax';
    final extras = DocumentUploadExtras(
      expiresOn: _type.id == 'id' ? _expiresOn : null,
      replacesDocumentId: widget.replacesDocumentId,
      purpose: widget.directDeposit && isTax ? DocumentUploadPurpose.directDeposit : null,
    );

    try {
      await context.read<TaskCubit>().uploadDocument(
            document: doc,
            type: _type.apiType,
            notes: notes.isEmpty ? null : notes,
            extras: extras.isEmpty ? null : extras,
          );
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _uploadedAny = true;
        _step = _Step.sent;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _uploading = false);
      showVeloraToast(context, tr('Unable to upload the document. Please try again.'));
    }
  }

  void _back() {
    switch (_step) {
      case _Step.type:
      case _Step.sent:
        Navigator.of(context).pop(_uploadedAny);
      case _Step.capture:
        setState(() => _step = _Step.type);
      case _Step.review:
        setState(() => _step = _Step.capture);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_step) {
      _Step.type => tr('Upload a document'),
      _Step.capture => tr('Add a photo or file'),
      _Step.review => tr('Check it'),
      _Step.sent => tr('Sent'),
    };

    return PopScope(
      // Back always goes through [_back] so steps unwind one at a time and
      // the "uploaded" result reaches the Docs tab.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_uploading) _back();
      },
      child: VeloraScaffold(
        body: VeloraPage(
          header: VeloraHeader(
            title: title,
            subtitle: tr('Goes straight to your file at the office'),
            onBack: _uploading ? () {} : _back,
          ),
          children: switch (_step) {
            _Step.type => _typeStep(),
            _Step.capture => _captureStep(),
            _Step.review => _reviewStep(),
            _Step.sent => _sentStep(),
          },
        ),
      ),
    );
  }

  List<Widget> _typeStep() => [
        SectionCaption(tr('What are you sending?'), padding: EdgeInsets.symmetric(horizontal: 2)),
        for (final type in _types)
          _TypeOption(
            type: type,
            selected: type.id == _type.id,
            onTap: () => setState(() => _type = type),
          ),
        const SizedBox(height: 2),
        VeloraButton(label: tr('Continue'), onPressed: () => setState(() => _step = _Step.capture)),
      ];

  List<Widget> _captureStep() => [
        Container(
          height: 260,
          decoration: BoxDecoration(
            color: const Color(0xFF0A1B18),
            borderRadius: BorderRadius.circular(22),
          ),
          alignment: Alignment.center,
          child: _picking
              ? const CircularProgressIndicator(color: VeloraColors.amber)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const VeloraIcon(VeloraIcons.camera, size: 44, color: VeloraColors.amber, strokeWidth: 1.6),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        _type.id == 'id'
                            ? tr('Take a clear photo of the front of your ID')
                            : tr('Take a clear photo, or choose a file'),
                        textAlign: TextAlign.center,
                        style: VeloraText.body(14, weight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ],
                ),
        ),
        VeloraButton(
          label: tr('Take photo'),
          icon: VeloraIcons.camera,
          onPressed: _picking ? null : () => _pick(DocumentSource.camera),
        ),
        VeloraButton(
          label: tr('Choose from photos'),
          variant: VeloraButtonVariant.ghost,
          icon: VeloraIcons.idCard,
          onPressed: _picking ? null : () => _pick(DocumentSource.gallery),
        ),
        VeloraButton(
          label: tr('Choose a file or PDF'),
          variant: VeloraButtonVariant.ghost,
          icon: VeloraIcons.folder,
          onPressed: _picking ? null : () => _pick(DocumentSource.files),
        ),
      ];

  List<Widget> _reviewStep() {
    final doc = _document!;
    final path = doc.filePath;
    return [
      VeloraCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 118,
                height: 76,
                child: doc.isImage && path != null
                    ? Image.file(File(path), fit: BoxFit.cover)
                    : doc.isImage && doc.bytes != null
                        ? Image.memory(doc.bytes!, fit: BoxFit.cover)
                        : const ColoredBox(
                            color: VeloraColors.mint,
                            child: Center(
                              child: VeloraIcon(VeloraIcons.document, size: 30, color: VeloraColors.teal),
                            ),
                          ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tr(_type.label), style: VeloraText.body(15, weight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(
                    '${doc.fileName} · ${doc.formattedSize}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: VeloraText.subtitle,
                  ),
                  VeloraTextLink(
                    label: tr('Retake'),
                    size: 13,
                    onTap: () => setState(() => _step = _Step.capture),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      if (_type.needsExpiry)
        VeloraCard(
          child: DateField(
            label: tr('New expiration date'),
            value: _expiresOn,
            onTap: _pickExpiry,
            labelColor: VeloraColors.body,
          ),
        ),
      VeloraCard(
        child: VeloraTextField(
          controller: _notesController,
          label: _type.id == 'other' ? tr('What is it?') : tr('Note for the office (optional)'),
          hint: _type.id == 'id' && !_type.needsExpiry
              ? tr('e.g. New expiration date 10/12/2031')
              : tr('Optional'),
          maxLines: 3,
          minLines: 2,
        ),
      ),
      VeloraCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          children: [
            KeyValueRow(showDivider: false, label: tr('Files to'), value: tr('Your file')),
            KeyValueRow(label: tr('Type'), value: tr(_type.label)),
          ],
        ),
      ),
      VeloraButton(
        label: tr('Send to office'),
        icon: VeloraIcons.send,
        isLoading: _uploading,
        onPressed: _send,
      ),
    ];
  }

  List<Widget> _sentStep() => [
        VeloraDoneCard(
          title: tr('The office has it'),
          message: tr('Your document is in your file. The office will review it and let you know in your inbox if anything else is needed.'),
          actions: [
            VeloraButton(label: tr('Done'), onPressed: () => Navigator.of(context).pop(true)),
            VeloraTextLink(
              label: tr('Send another'),
              size: 13,
              onTap: () => setState(() {
                _document = null;
                _expiresOn = null;
                _notesController.clear();
                _step = _Step.type;
              }),
            ),
          ],
        ),
      ];
}

class _TypeOption extends StatelessWidget {
  const _TypeOption({required this.type, required this.selected, required this.onTap});

  final _DocType type;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? VeloraColors.mintSoft : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? VeloraColors.teal : VeloraColors.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 62),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  IconTile(type.icon, size: 38, iconSize: 18, radius: 11),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr(type.label), style: VeloraText.body(14.5, weight: FontWeight.w700)),
                        Text(tr(type.hint), style: VeloraText.body(12, color: VeloraColors.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
