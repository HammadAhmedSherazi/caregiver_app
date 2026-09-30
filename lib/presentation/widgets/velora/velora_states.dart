import 'package:flutter/material.dart';

import '../../../core/theme/velora_theme.dart';
import 'velora_components.dart';
import 'velora_icon.dart';
import '../../../core/i18n/tr.dart';

/// Centered spinner for sections still loading.
class VeloraLoadingState extends StatelessWidget {
  const VeloraLoadingState({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: VeloraColors.teal,
              backgroundColor: VeloraColors.mint,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 14),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: VeloraText.body(14, weight: FontWeight.w700, color: VeloraColors.body),
            ),
          ],
        ],
      ),
    );
  }
}

/// Friendly empty state inside a card.
class VeloraEmptyState extends StatelessWidget {
  const VeloraEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = VeloraIcons.folder,
    this.action,
  });

  final String title;
  final String? message;
  final VeloraIcons icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return VeloraCard(
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 22),
      child: Column(
        children: [
          IconTile(icon, tone: IconTileTone.mute, size: 52, iconSize: 24, radius: 16),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: VeloraText.display(18)),
          if (message != null) ...[
            const SizedBox(height: 6),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: VeloraText.body(13.5, color: VeloraColors.muted, height: 1.45),
            ),
          ],
          if (action != null) ...[const SizedBox(height: 14), action!],
        ],
      ),
    );
  }
}

/// Error card with a retry button.
class VeloraErrorState extends StatelessWidget {
  const VeloraErrorState({
    super.key,
    this.title = 'Something went wrong',
    this.message = 'We couldn\'t load this. Check your connection and try again.',
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return VeloraCard(
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 20),
      child: Column(
        children: [
          const IconTile(
            VeloraIcons.warning,
            tone: IconTileTone.danger,
            size: 52,
            iconSize: 24,
            radius: 16,
          ),
          const SizedBox(height: 12),
          Text(tr(title), textAlign: TextAlign.center, style: VeloraText.display(18)),
          const SizedBox(height: 6),
          Text(
            tr(message),
            textAlign: TextAlign.center,
            style: VeloraText.body(13.5, color: VeloraColors.muted, height: 1.45),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            VeloraButton(
              label: tr('Try again'),
              variant: VeloraButtonVariant.ghost,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}

/// Explains that an action is designed but not backed by an API yet.
///
/// Used by screens whose submit step has no endpoint (Report a change,
/// Fix a clock-out, My info). It never pretends the data was sent.
Future<void> showApiRequiredSheet(
  BuildContext context, {
  required String feature,
  VoidCallback? onContactOffice,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(VeloraRadii.sheet)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetGrabber(),
            const SizedBox(height: 16),
            const Center(
              child: IconTile(
                VeloraIcons.info,
                tone: IconTileTone.amber,
                size: 56,
                iconSize: 26,
                radius: 18,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              tr('Not connected yet'),
              textAlign: TextAlign.center,
              style: VeloraText.display(20),
            ),
            const SizedBox(height: 8),
            Text(
              tr('{0} can\'t be sent from the app yet. Nothing was sent. Please message or call the office instead.', [feature]),
              textAlign: TextAlign.center,
              style: VeloraText.body(14, color: VeloraColors.muted, height: 1.5),
            ),
            const SizedBox(height: 18),
            if (onContactOffice != null) ...[
              VeloraButton(
                label: tr('Message the office'),
                icon: VeloraIcons.message,
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  onContactOffice();
                },
              ),
              const SizedBox(height: 10),
            ],
            VeloraButton(
              label: tr('Close'),
              variant: VeloraButtonVariant.ghost,
              onPressed: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Small handle at the top of bottom sheets.
class SheetGrabber extends StatelessWidget {
  const SheetGrabber({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 5,
        decoration: BoxDecoration(
          color: VeloraColors.fieldBorder,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

/// Dark rounded toast in the design's style.
void showVeloraToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        // Tablets: a phone-width toast instead of one across the screen.
        width: MediaQuery.sizeOf(context).width > VeloraSpacing.maxContentWidth
            ? VeloraSpacing.maxContentWidth - 32
            : null,
        backgroundColor: VeloraColors.brandDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            const VeloraIcon(VeloraIcons.check, size: 18, color: VeloraColors.amber, strokeWidth: 2.4),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                tr(message),
                style: VeloraText.body(13.5, weight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
}
