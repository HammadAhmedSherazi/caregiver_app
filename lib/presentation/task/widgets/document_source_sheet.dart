import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../../data/models/selected_document.dart';

Future<DocumentSource?> showDocumentSourceSheet(BuildContext context) {
  return showModalBottomSheet<DocumentSource>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: AppColors.homeDialogOverlay,
    builder: (sheetContext) => const DocumentSourceSheet(),
  );
}

class DocumentSourceSheet extends StatelessWidget {
  const DocumentSourceSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.homeDialogDivider,
                borderRadius: BorderRadius.circular(100),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Add document',
              style: context.responsiveStyle(AppTextStyles.homeAddress),
            ),
            const SizedBox(height: 8),
            Text(
              'Take a photo or choose an existing file',
              textAlign: TextAlign.center,
              style: context.responsiveStyle(AppTextStyles.homeCardSubtitle),
            ),
            const SizedBox(height: 20),
            _SourceOptionTile(
              icon: Icons.photo_camera_outlined,
              title: 'Take photo',
              subtitle: 'Use your camera',
              onTap: () => Navigator.of(context).pop(DocumentSource.camera),
            ),
            const SizedBox(height: 10),
            _SourceOptionTile(
              icon: Icons.photo_library_outlined,
              title: 'Photo gallery',
              subtitle: 'Choose from your photos',
              onTap: () => Navigator.of(context).pop(DocumentSource.gallery),
            ),
            const SizedBox(height: 10),
            _SourceOptionTile(
              icon: Icons.insert_drive_file_outlined,
              title: 'Browse files',
              subtitle: 'JPG, PNG or PDF · Max 10 MB',
              onTap: () => Navigator.of(context).pop(DocumentSource.files),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: context.responsiveStyle(
                    AppTextStyles.homeCardSubtitle.copyWith(
                      color: AppColors.homeDialogCancel,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceOptionTile extends StatelessWidget {
  const _SourceOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.homeIconTint,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: AppColors.homePrimary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.responsiveStyle(
                        AppTextStyles.homeCardTitle,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: context.responsiveStyle(
                        AppTextStyles.homeCardSubtitle,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.homeMutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
