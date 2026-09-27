import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../../data/models/chat_message_model.dart';
import '../../widgets/velora/velora.dart';
import '../../../core/i18n/tr.dart';

/// Figma node `1:2779` — chat message bubble.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
    this.onRetry,
  });

  final ChatMessage message;
  final VoidCallback? onRetry;

  static const _incomingFill = VeloraColors.card;
  static const _bubbleTextColor = VeloraColors.ink;

  @override
  Widget build(BuildContext context) {
    final isOutgoing = message.direction == ChatMessageDirection.outgoing;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment:
            isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Align(
            alignment:
                isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.72,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isOutgoing ? VeloraColors.brand : _incomingFill,
                  border: isOutgoing ? null : Border.all(color: VeloraColors.line),
                  borderRadius: isOutgoing
                      ? const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                          bottomRight: Radius.circular(4),
                          bottomLeft: Radius.circular(16),
                        )
                      : const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                          bottomLeft: Radius.circular(4),
                        ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Text(
                    message.text,
                    style: context.responsiveStyle(
                      AppTextStyles.bodyLarge.copyWith(
                        fontSize: 14,
                        height: 1.45,
                        color: isOutgoing
                            ? AppColors.authOnGradient
                            : _bubbleTextColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          _StatusRow(
            message: message,
            isOutgoing: isOutgoing,
            onRetry: onRetry,
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.message,
    required this.isOutgoing,
    this.onRetry,
  });

  final ChatMessage message;
  final bool isOutgoing;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    switch (message.sendStatus) {
      case ChatMessageSendStatus.sending:
        return Align(
          alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
          child: SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: AppColors.homeMutedText,
            ),
          ),
        );
      case ChatMessageSendStatus.failed:
        return Align(
          alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
          child: GestureDetector(
            onTap: onRetry,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                tr('Tap to send again'),
                style: context.responsiveStyle(
                  AppTextStyles.homeNavLabel.copyWith(
                    fontSize: 12,
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
          ),
        );
      case ChatMessageSendStatus.sent:
        if (message.timestampLabel == null) {
          return const SizedBox.shrink();
        }
        return Align(
          alignment: isOutgoing ? Alignment.centerRight : Alignment.centerLeft,
          child: Text(
            message.timestampLabel!,
            style: context.responsiveStyle(
              AppTextStyles.homeNavLabel.copyWith(
                fontSize: 12,
                color: AppColors.homeDarkText,
              ),
            ),
          ),
        );
    }
  }
}
