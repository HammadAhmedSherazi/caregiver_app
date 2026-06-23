import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../data/models/inbox_thread_model.dart';
import '../../../data/repositories/inbox_repository.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/loading_widget.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_screen_header.dart';

/// Figma node `1:2779` — one-to-one chat conversation.
class ChatView extends StatefulWidget {
  const ChatView({
    super.key,
    required this.thread,
  });

  final InboxThread thread;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _repository = sl<InboxRepository>();
  final _messageController = TextEditingController();
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await _repository.fetchMessages(widget.thread.id);
      if (!mounted) return;
      setState(() {
        _messages = items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load conversation.';
        _isLoading = false;
      });
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages = [
        ..._messages,
        ChatMessage(
          id: 'local-${DateTime.now().millisecondsSinceEpoch}',
          text: text,
          direction: ChatMessageDirection.outgoing,
          timestampLabel: _formatTime(DateTime.now()),
        ),
      ];
    });
    _messageController.clear();
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: Column(
        children: [
          ChatScreenHeader(
            title: widget.thread.contactName,
            avatarUrl: widget.thread.avatarUrl,
            avatarName: widget.thread.contactName,
            onBack: () => Navigator.of(context).pop(),
            onCall: () {},
          ),
          Expanded(child: _buildBody()),
          ChatInputBar(
            controller: _messageController,
            onSend: _sendMessage,
            enabled: !_isLoading && _error == null,
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingWidget(message: 'Loading conversation...');
    }

    if (_error != null) {
      return ErrorDisplayWidget(message: _error!, onRetry: _load);
    }

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
          itemCount: _messages.length,
          itemBuilder: (context, index) {
            return ChatBubble(message: _messages[index]);
          },
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 194,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.homeBackground.withValues(alpha: 0),
                    AppColors.surface,
                  ],
                  stops: const [0.142, 0.71875],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
