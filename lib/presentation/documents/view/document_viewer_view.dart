import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';

import '../../main/app_navigator.dart';
import '../../task/cubit/task_cubit.dart';
import '../../widgets/velora/velora.dart';
import '../../../core/i18n/tr.dart';

/// One in-app viewer for every PDF: paystub, W-2, pay schedule and check-in
/// receipt (design `DocView`).
///
/// [load] fetches the bytes through the existing [TaskCubit] loaders, so the
/// endpoints and their error mapping live in one place. "Save to Files" uses
/// the system save dialog (`file_picker`), "Share or print" the share sheet.
class DocumentViewerView extends StatefulWidget {
  const DocumentViewerView({
    super.key,
    required this.title,
    required this.fileName,
    required this.load,
  });

  final String title;

  /// Shown under the title and used when saving / sharing (`*.pdf`).
  final String fileName;
  final Future<Uint8List> Function() load;

  @override
  State<DocumentViewerView> createState() => _DocumentViewerViewState();
}

class _DocumentViewerViewState extends State<DocumentViewerView> {
  Uint8List? _bytes;
  PdfControllerPinch? _controller;
  DocumentDownloadException? _error;
  bool _saving = false;
  bool _sharing = false;
  final _shareButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _bytes = null;
    });
    try {
      final bytes = await widget.load();
      if (!mounted) return;
      _controller?.dispose();
      setState(() {
        _bytes = bytes;
        _controller = PdfControllerPinch(document: PdfDocument.openData(bytes));
      });
    } on DocumentDownloadException catch (error) {
      if (mounted) setState(() => _error = error);
    } catch (_) {
      if (mounted) {
        setState(() => _error = DocumentDownloadException(tr('Unable to download this document.')));
      }
    }
  }

  Future<void> _save() async {
    final bytes = _bytes;
    if (bytes == null || _saving) return;
    setState(() => _saving = true);
    try {
      final path = await FilePicker.saveFile(
        fileName: widget.fileName,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
      );
      if (path != null && mounted) showVeloraToast(context, tr('Saved to Files.'));
    } catch (_) {
      if (mounted) showVeloraToast(context, tr('Couldn\'t save this document.'));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _share() async {
    final bytes = _bytes;
    if (bytes == null || _sharing) return;
    setState(() => _sharing = true);
    // iPad anchors the share sheet to the button.
    final box = _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: 'application/pdf', name: widget.fileName)],
          fileNameOverrides: [widget.fileName],
          sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (mounted) showVeloraToast(context, tr('Couldn\'t open the share sheet.'));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = _controller != null;

    return Scaffold(
      backgroundColor: VeloraColors.paperBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VeloraHeader(
            title: widget.title,
            subtitle: widget.fileName,
            onBack: () => Navigator.of(context).pop(),
            showRings: false,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          ),
          Expanded(child: _body()),
          _ActionBar(
            shareKey: _shareButtonKey,
            saving: _saving,
            sharing: _sharing,
            onSave: ready ? _save : null,
            onShare: ready ? _share : null,
          ),
        ],
      ),
    );
  }

  Widget _body() {
    final error = _error;
    if (error != null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          if (error.notLive) ...[
            VeloraErrorState(title: 'Not connected yet', message: error.message),
            const SizedBox(height: 12),
            VeloraButton(
              label: tr('Message the office'),
              icon: VeloraIcons.message,
              variant: VeloraButtonVariant.ghost,
              onPressed: () => AppNavigator.openInbox(context),
            ),
          ] else
            VeloraErrorState(
              title: 'We couldn\'t open this document',
              message: error.message,
              onRetry: _load,
            ),
        ],
      );
    }

    final controller = _controller;
    if (controller == null) {
      return Center(child: VeloraLoadingState(message: tr('Opening your document…')));
    }

    return PdfViewPinch(
      controller: controller,
      padding: 16,
      backgroundDecoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(6)),
        boxShadow: [
          BoxShadow(color: Color(0x1F0A1E1A), blurRadius: 6, offset: Offset(0, 2)),
          BoxShadow(color: Color(0x1F0A1E1A), blurRadius: 40, offset: Offset(0, 18)),
        ],
      ),
      builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        documentLoaderBuilder: (_) =>
            Center(child: VeloraLoadingState(message: tr('Opening your document…'))),
        pageLoaderBuilder: (_) => const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3, color: VeloraColors.teal),
          ),
        ),
        errorBuilder: (_, _) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: [
            VeloraErrorState(
              title: 'We couldn\'t open this document',
              message: 'The file is damaged or not a PDF.',
              onRetry: _load,
            ),
          ],
        ),
      ),
    );
  }
}

/// White bottom bar: "Save to Files" and "Share or print" side by side.
class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.shareKey,
    required this.saving,
    required this.sharing,
    required this.onSave,
    required this.onShare,
  });

  final Key shareKey;
  final bool saving;
  final bool sharing;
  final VoidCallback? onSave;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomInset > 0 ? bottomInset : 22),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: VeloraColors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: VeloraButton(
              label: tr('Save to Files'),
              icon: VeloraIcons.download,
              isLoading: saving,
              onPressed: onSave,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: VeloraButton(
              key: shareKey,
              label: tr('Share or print'),
              icon: VeloraIcons.share,
              variant: VeloraButtonVariant.ghost,
              isLoading: sharing,
              onPressed: onShare,
            ),
          ),
        ],
      ),
    );
  }
}
