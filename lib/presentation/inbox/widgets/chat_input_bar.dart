import 'package:flutter/material.dart';

import '../../widgets/velora/velora.dart';
import '../../../core/i18n/tr.dart';

/// Figma node `1:2779` — message composer bar.
class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.enabled = true,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: VeloraColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  minLines: 1,
                  maxLines: 4,
                  style: VeloraText.body(15),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  decoration: VeloraTextField.decoration(hint: tr('Message the office…')),
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                button: true,
                label: tr('Send'),
                // The design keeps the brand-green button; only the icon dims.
                child: Material(
                  color: VeloraColors.brand,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: enabled ? onSend : null,
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 52,
                      height: 52,
                      child: Center(
                        child: VeloraIcon(
                          VeloraIcons.send,
                          size: 20,
                          color: enabled ? VeloraColors.amber : VeloraColors.amber.withValues(alpha: 0.45),
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
