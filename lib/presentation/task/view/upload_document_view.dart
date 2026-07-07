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
import '../../home/widgets/home_svg_icon.dart';
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
  final _notesController = TextEditingController();
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

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

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
            notes: _notesController.text.trim(),
          );
      if (!mounted) return;

      await _showSuccessSheet();
    } catch (_) {
      if (!mounted) return;
      _showMessage('Unable to upload document. Please try again.');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _showSuccessSheet() {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return TaskSuccessSheet(
          title: 'Document Uploaded',
          message:
              'Synced to your agency EMR. Office staff has been notified.',
          primaryLabel: 'Done',
          onPrimary: () {
            Navigator.of(sheetContext).pop();
            Navigator.of(context).pop();
          },
          secondaryLabel: 'Upload another',
          onSecondary: () {
            Navigator.of(sheetContext).pop();
            setState(() {
              _selectedDocument = null;
              _notesController.clear();
              _documentType = 'ID';
            });
          },
        );
      },
    );
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
                _DocumentPreviewCard(
                  document: document,
                  isPicking: _isPicking,
                  onPick: _pickDocument,
                ),
                const SizedBox(height: 24),
                Text(
                  'Document Type',
                  style: context.responsiveStyle(
                    AppTextStyles.homeCardTitle.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _DocumentTypeGrid(
                  types: _documentTypes,
                  selected: _documentType,
                  enabled: !_isUploading,
                  onSelected: (value) => setState(() => _documentType = value),
                ),
                const SizedBox(height: 24),
                Text(
                  'Notes (Optional)',
                  style: context.responsiveStyle(
                    AppTextStyles.homeCardTitle.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  enabled: !_isUploading,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Add note for the office...',
                    hintStyle: context.responsiveStyle(
                      AppTextStyles.homeCardSubtitle,
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.homeDialogDivider,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.homeDialogDivider,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(
                        color: AppColors.homePrimary,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 32),
                TaskPrimaryButton(
                  label: _isUploading ? 'Submitting...' : 'Submit To EMR',
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

class _DocumentPreviewCard extends StatelessWidget {
  const _DocumentPreviewCard({
    required this.document,
    required this.isPicking,
    required this.onPick,
  });

  final SelectedDocument? document;
  final bool isPicking;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: taskCardDecoration(),
      child: Column(
        children: [
          GestureDetector(
            onTap: isPicking ? null : onPick,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: document?.isImage == true ? 200 : 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.homeIconTint,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: document != null
                      ? AppColors.homePrimary.withValues(alpha: 0.3)
                      : AppColors.homeDialogDivider,
                ),
              ),
              child: isPicking
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.homePrimary,
                      ),
                    )
                  : document == null
                      ? _EmptyPickerContent()
                      : document!.isImage
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: _DocumentImagePreview(document: document!),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                HomeIconBox(
                                  iconAsset: AppAssets.icTaskForm,
                                  width: 56,
                                  height: 56,
                                ),
                              ],
                            ),
            ),
          ),
          if (document != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document!.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.responsiveStyle(
                          AppTextStyles.homeCardTitle.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${document!.formattedSize} · Captured now',
                        style: context.responsiveStyle(
                          AppTextStyles.homeCardSubtitle,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: isPicking ? null : onPick,
                  child: Text(
                    'Retake',
                    style: context.responsiveStyle(
                      AppTextStyles.homeCardSubtitle.copyWith(
                        color: AppColors.homePrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _DocumentTypeGrid extends StatelessWidget {
  const _DocumentTypeGrid({
    required this.types,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final List<String> types;
  final String selected;
  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.6,
      children: types.map((type) {
        final isSelected = type == selected;
        return GestureDetector(
          onTap: enabled ? () => onSelected(type) : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.homePrimary
                    : AppColors.homeDialogDivider,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                HomeSvgIcon(
                  asset: AppAssets.icTaskUpload,
                  width: 18,
                  height: 18,
                  color: isSelected
                      ? AppColors.homePrimary
                      : AppColors.homeMutedText,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    type,
                    style: context.responsiveStyle(
                      AppTextStyles.homeCardTitle.copyWith(
                        fontSize: 13,
                        color: isSelected
                            ? AppColors.homePrimary
                            : AppColors.homeDarkText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
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
          'Tap to capture document',
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
