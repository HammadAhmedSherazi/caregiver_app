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
                child: Material(
                  color: enabled ? VeloraColors.brand : VeloraColors.disabled,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: enabled ? onSend : null,
                    borderRadius: BorderRadius.circular(14),
                    child: const SizedBox(
                      width: 50,
                      height: 50,
                      child: Center(
                        child: VeloraIcon(VeloraIcons.send, size: 20, color: VeloraColors.amber, strokeWidth: 2),
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
