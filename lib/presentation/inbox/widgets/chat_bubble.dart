import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/extensions/context_extensions.dart';
import '../../../data/models/chat_message_model.dart';

/// Figma node `1:2779` — chat message bubble.
class ChatBubble extends StatelessWidget {
  const ChatBubble({
    super.key,
    required this.message,
  });

  final ChatMessage message;

  static const _incomingFill = Color(0x125297FF);
  static const _bubbleTextColor = Color(0xFF333333);

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
                  color: isOutgoing ? AppColors.homePrimary : _incomingFill,
                  borderRadius: isOutgoing
                      ? const BorderRadius.only(
                          topLeft: Radius.circular(32),
                          topRight: Radius.circular(22),
                          bottomRight: Radius.circular(4),
                          bottomLeft: Radius.circular(32),
                        )
                      : const BorderRadius.only(
                          topLeft: Radius.circular(31.135),
                          topRight: Radius.circular(31.135),
                          bottomRight: Radius.circular(31.135),
                          bottomLeft: Radius.circular(3.892),
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
                        fontSize: 16,
                        height: 24 / 16,
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
          if (message.timestampLabel != null) ...[
            const SizedBox(height: 4),
            Text(
              message.timestampLabel!,
              style: context.responsiveStyle(
                AppTextStyles.homeNavLabel.copyWith(
                  fontSize: 12,
                  color: AppColors.homeDarkText,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
