import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment:
            isOutgoing ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Align(
            alignment:
                isOutgoing ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.8,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: isOutgoing ? VeloraColors.brand : _incomingFill,
                  border: isOutgoing ? null : Border.all(color: VeloraColors.line),
                  borderRadius: isOutgoing
                      ? const BorderRadiusDirectional.only(
                          topStart: Radius.circular(16),
                          topEnd: Radius.circular(16),
                          bottomEnd: Radius.circular(4),
                          bottomStart: Radius.circular(16),
                        )
                      : const BorderRadiusDirectional.only(
                          topStart: Radius.circular(16),
                          topEnd: Radius.circular(16),
                          bottomEnd: Radius.circular(16),
                          bottomStart: Radius.circular(4),
                        ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  child: Text(
                    message.text,
                    style: VeloraText.body(
                      14,
                      height: 1.45,
                      color: isOutgoing ? Colors.white : _bubbleTextColor,
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
          alignment: isOutgoing ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
          child: SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: VeloraColors.muted,
            ),
          ),
        );
      case ChatMessageSendStatus.failed:
        return Align(
          alignment: isOutgoing ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
          child: GestureDetector(
            onTap: onRetry,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                tr('Tap to send again'),
                style: VeloraText.body(12, weight: FontWeight.w600, color: VeloraColors.dangerText),
              ),
            ),
          ),
        );
      case ChatMessageSendStatus.sent:
        if (message.timestampLabel == null) {
          return const SizedBox.shrink();
        }
        return Align(
          alignment: isOutgoing ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
          child: Text(
            message.timestampLabel!,
            style: VeloraText.body(11.5, color: VeloraColors.muted),
          ),
        );
    }
  }
}
