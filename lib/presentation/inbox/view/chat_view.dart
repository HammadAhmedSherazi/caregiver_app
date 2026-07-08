import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/network/chat_realtime_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../data/models/inbox_thread_model.dart';
import '../../../data/repositories/inbox_repository.dart';
import '../../widgets/get_request_view.dart';
import '../../widgets/skeletons/api_tab_skeletons.dart';
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
  final _realtime = sl<ChatRealtimeService>();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  StreamSubscription<ChatMessage>? _socketSub;
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _load();
    _initSocket();
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    _realtime.unsubscribeConversation();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initSocket() async {
    try {
      await _realtime.subscribeToConversation(widget.thread.id);
      _socketSub = _realtime.messages.listen(_onSocketMessage);
    } catch (_) {
      // REST remains source of truth if the socket is unavailable.
    }
  }

  void _onSocketMessage(ChatMessage message) {
    if (!mounted) return;
    if (_messages.any((m) => m.id == message.id)) return;

    setState(() {
      _messages = [..._messages, message];
    });
    _scrollToBottom();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final items = await _repository.fetchMessages(widget.thread.id);
      if (!mounted) return;
      setState(() {
        _messages = items;
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      final message = await _repository.sendMessage(
        threadId: widget.thread.id,
        body: text,
      );
      if (!mounted) return;
      setState(() {
        if (!_messages.any((m) => m.id == message.id)) {
          _messages = [..._messages, message];
        }
        _isSending = false;
      });
      _messageController.clear();
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to send message.')),
      );
    }
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
          Expanded(
            child: GetRequestView(
              isLoading: _isLoading,
              hasError: _hasError,
              onRetry: _load,
              skeleton: const ChatMessagesSkeleton(),
              child: _buildMessages(),
            ),
          ),
          ChatInputBar(
            controller: _messageController,
            onSend: _sendMessage,
            enabled: !_isLoading && !_isSending && !_hasError,
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (_messages.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        color: AppColors.homePrimary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(child: Text('No messages yet')),
          ],
        ),
      );
    }

    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
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
