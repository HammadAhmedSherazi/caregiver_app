import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/utils/document_picker_service.dart';
import '../../../data/models/selected_document.dart';
import '../../task/cubit/task_cubit.dart';
import '../../widgets/velora/velora.dart';

class _DocType {
  const _DocType(this.id, this.label, this.hint, this.icon, this.apiType);

  final String id;
  final String label;
  final String hint;
  final VeloraIcons icon;

  /// Value sent as `type` to `POST /documents` (existing API values).
  final String apiType;
}

const _types = [
  _DocType('id', 'Photo ID or driver\'s license', 'Front and back', VeloraIcons.idCard, 'ID'),
  _DocType('tax', 'Tax or pay form', 'W-4, MI-W4, direct deposit', VeloraIcons.document, 'Signed Form'),
  _DocType('med', 'Doctor or hospital note', 'For your client or for you', VeloraIcons.plus, 'Other'),
  _DocType('state', 'Letter from DHS or the plan', 'Anything the state or insurance mailed you',
      VeloraIcons.mail, 'Mail/Letter'),
  _DocType('other', 'Something else', 'Tell the office what it is', VeloraIcons.dots, 'Other'),
];

enum _Step { type, capture, review, sent }

/// Upload to office: pick type → photo or file → check it → sent.
///
/// Uses the existing picker and `POST /documents`.
class UploadView extends StatefulWidget {
  const UploadView({super.key, this.initialType});

  /// One of `id`, `tax`, `med`, `state`, `other`.
  final String? initialType;

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
        showVeloraToast(context, 'That file is too large. The limit is 10 MB.');
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
      showVeloraToast(context, 'Could not load that file. Please try again.');
    }
  }

  Future<void> _send() async {
    final doc = _document;
    if (doc == null || _uploading) return;
    setState(() => _uploading = true);

    final note = _notesController.text.trim();
    final notes = [
      if (_type.id == 'med' || _type.id == 'tax') _type.label,
      if (note.isNotEmpty) note,
    ].join(' – ');

    try {
      await context.read<TaskCubit>().uploadDocument(
            document: doc,
            type: _type.apiType,
            notes: notes.isEmpty ? null : notes,
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
      showVeloraToast(context, 'Unable to upload the document. Please try again.');
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
      _Step.type => 'Upload a document',
      _Step.capture => 'Add a photo or file',
      _Step.review => 'Check it',
      _Step.sent => 'Sent',
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
            subtitle: 'Goes straight to your file at the office',
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
        const SectionCaption('What are you sending?', padding: EdgeInsets.symmetric(horizontal: 2)),
        for (final type in _types)
          _TypeOption(
            type: type,
            selected: type.id == _type.id,
            onTap: () => setState(() => _type = type),
          ),
        const SizedBox(height: 2),
        VeloraButton(label: 'Continue', onPressed: () => setState(() => _step = _Step.capture)),
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
                            ? 'Take a clear photo of the front of your ID'
                            : 'Take a clear photo, or choose a file',
                        textAlign: TextAlign.center,
                        style: VeloraText.body(14, weight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ],
                ),
        ),
        VeloraButton(
          label: 'Take photo',
          icon: VeloraIcons.camera,
          onPressed: _picking ? null : () => _pick(DocumentSource.camera),
        ),
        VeloraButton(
          label: 'Choose from photos',
          variant: VeloraButtonVariant.ghost,
          icon: VeloraIcons.idCard,
          onPressed: _picking ? null : () => _pick(DocumentSource.gallery),
        ),
        VeloraButton(
          label: 'Choose a file or PDF',
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
                  Text(_type.label, style: VeloraText.body(15, weight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(
                    '${doc.fileName} · ${doc.formattedSize}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: VeloraText.subtitle,
                  ),
                  VeloraTextLink(
                    label: 'Retake',
                    size: 13,
                    onTap: () => setState(() => _step = _Step.capture),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      VeloraCard(
        child: VeloraTextField(
          controller: _notesController,
          label: _type.id == 'other' ? 'What is it?' : 'Note for the office (optional)',
          hint: _type.id == 'id' ? 'e.g. New expiration date 10/12/2031' : 'Optional',
          maxLines: 3,
          minLines: 2,
        ),
      ),
      VeloraCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          children: [
            const KeyValueRow(showDivider: false, label: 'Files to', value: 'Your file'),
            KeyValueRow(label: 'Type', value: _type.apiType),
          ],
        ),
      ),
      VeloraButton(
        label: 'Send to office',
        icon: VeloraIcons.send,
        isLoading: _uploading,
        onPressed: _send,
      ),
    ];
  }

  List<Widget> _sentStep() => [
        VeloraDoneCard(
          title: 'The office has it',
          message: 'Your document is in your file. The office will review it and let you know in your inbox if anything else is needed.',
          actions: [
            VeloraButton(label: 'Done', onPressed: () => Navigator.of(context).pop(true)),
            VeloraTextLink(
              label: 'Send another',
              size: 13,
              onTap: () => setState(() {
                _document = null;
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
                        Text(type.label, style: VeloraText.body(14.5, weight: FontWeight.w700)),
                        Text(type.hint, style: VeloraText.body(12, color: VeloraColors.muted)),
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
