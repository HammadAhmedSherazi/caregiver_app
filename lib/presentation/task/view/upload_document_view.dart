import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/document_picker_service.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../../data/models/selected_document.dart';
import '../../home/widgets/home_icon_box.dart';
import '../cubit/task_cubit.dart';
import '../widgets/document_source_sheet.dart';
import '../widgets/task_cards.dart';
import '../widgets/task_primary_button.dart';
import '../widgets/task_screen_header.dart';
import '../widgets/task_success_sheet.dart';

class UploadDocumentView extends StatefulWidget {
  const UploadDocumentView({super.key});

  @override
  State<UploadDocumentView> createState() => _UploadDocumentViewState();
}

class _UploadDocumentViewState extends State<UploadDocumentView> {
  final _pickerService = DocumentPickerService();
  SelectedDocument? _selectedDocument;
  bool _isPicking = false;
  bool _isUploading = false;
  String _documentType = 'ID';

  static const _documentTypes = [
    'ID',
    'Mail/Letter',
    'Signed Form',
    'Other',
  ];

  Future<void> _pickDocument() async {
    final source = await showDocumentSourceSheet(context);
    if (!mounted || source == null) return;

    setState(() => _isPicking = true);

    try {
      final document = await _pickerService.pickFromSource(source);
      if (!mounted) return;

      if (document == null) {
        setState(() => _isPicking = false);
        return;
      }

      if (!document.isWithinSizeLimit) {
        setState(() => _isPicking = false);
        _showMessage('File is too large. Maximum size is 10 MB.');
        return;
      }

      setState(() {
        _selectedDocument = document;
        _isPicking = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isPicking = false);
      _showMessage('Could not load the selected file. Please try again.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submit() async {
    final document = _selectedDocument;
    if (document == null || _isUploading) return;

    setState(() => _isUploading = true);

    try {
      await context.read<TaskCubit>().uploadDocument(
            document: document,
            type: _documentType,
          );
      if (!mounted) return;

      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return TaskSuccessSheet(
            title: 'Document uploaded',
            message: 'Your document has been uploaded successfully.',
            primaryLabel: 'Done',
            onPrimary: () {
              Navigator.of(sheetContext).pop();
              Navigator.of(context).pop();
            },
          );
        },
      );
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to upload document. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final document = _selectedDocument;

    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TaskScreenHeader(
            title: 'Upload Document',
            subtitle: 'Required document',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: taskCardDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upload Document',
                        style: context.responsiveStyle(
                          AppTextStyles.homeCardTitle.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Select a file to upload',
                        style: context.responsiveStyle(
                          AppTextStyles.homeCardSubtitle,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: taskCardDecoration(),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _documentType,
                      isExpanded: true,
                      items: _documentTypes
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(
                                type,
                                style: context.responsiveStyle(
                                  AppTextStyles.homeCardTitle,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _isUploading
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _documentType = value);
                              }
                            },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _isPicking ? null : _pickDocument,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: document?.isImage == true ? 220 : 180,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: document != null
                            ? AppColors.homePrimary
                            : AppColors.homeDialogDivider,
                        width: document != null ? 2 : 1,
                      ),
                    ),
                    child: _isPicking
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.homePrimary,
                            ),
                          )
                        : document == null
                            ? _EmptyPickerContent()
                            : _SelectedDocumentPreview(document: document),
                  ),
                ),
                if (document != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isPicking ? null : _pickDocument,
                      child: Text(
                        'Replace file',
                        style: context.responsiveStyle(
                          AppTextStyles.homeCardSubtitle.copyWith(
                            color: AppColors.homePrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                TaskPrimaryButton(
                  label: _isUploading ? 'Uploading...' : 'Upload document',
                  onPressed: document != null && !_isPicking && !_isUploading
                      ? _submit
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPickerContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        HomeIconBox(
          iconAsset: AppAssets.icTaskUpload,
          width: 56,
          height: 56,
        ),
        const SizedBox(height: 12),
        Text(
          'Tap to add file',
          style: context.responsiveStyle(
            AppTextStyles.homeCardTitle.copyWith(
              color: AppColors.homeMutedText,
            ),
          ),
        ),
        Text(
          'Camera, gallery or files',
          style: context.responsiveStyle(AppTextStyles.homeCardSubtitle),
        ),
        const SizedBox(height: 4),
        Text(
          'JPG, PNG or PDF · Max 10 MB',
          style: context.responsiveStyle(AppTextStyles.homeCardSubtitle),
        ),
      ],
    );
  }
}

class _SelectedDocumentPreview extends StatelessWidget {
  const _SelectedDocumentPreview({required this.document});

  final SelectedDocument document;

  @override
  Widget build(BuildContext context) {
    if (document.isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _DocumentImagePreview(document: document),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: _DocumentMetaChip(document: document),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        HomeIconBox(
          iconAsset: AppAssets.icTaskForm,
          width: 56,
          height: 56,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            document.fileName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.responsiveStyle(
              AppTextStyles.homeCardTitle.copyWith(
                color: AppColors.homePrimary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          document.formattedSize,
          style: context.responsiveStyle(AppTextStyles.homeCardSubtitle),
        ),
      ],
    );
  }
}

class _DocumentImagePreview extends StatelessWidget {
  const _DocumentImagePreview({required this.document});

  final SelectedDocument document;

  @override
  Widget build(BuildContext context) {
    final file = document.file;
    if (file != null && !kIsWeb) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    final bytes = document.bytes;
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    return const ColoredBox(color: AppColors.homeIconTint);
  }
}

class _DocumentMetaChip extends StatelessWidget {
  const _DocumentMetaChip({required this.document});

  final SelectedDocument document;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              document.fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.responsiveStyle(
                AppTextStyles.homeCardSubtitle.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            document.formattedSize,
            style: context.responsiveStyle(
              AppTextStyles.homeCardSubtitle.copyWith(
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
