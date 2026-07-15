import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/service_locator.dart';
import '../../../core/network/chat_realtime_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../data/models/inbox_thread_model.dart';
import '../../../data/repositories/inbox_repository.dart';
import '../../widgets/get_request_view.dart';
import '../../widgets/skeletons/api_tab_skeletons.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_screen_header.dart';

/// Figma node `1:2779` — one-to-one chat conversation.
class ChatView extends StatelessWidget {
  const ChatView({
    super.key,
    required this.thread,
  });

  final InboxThread thread;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChatCubit(
        threadId: thread.id,
        repository: sl<InboxRepository>(),
        realtime: sl<ChatRealtimeService>(),
      )..start(),
      child: _ChatViewBody(thread: thread),
    );
  }
}

class _ChatViewBody extends StatefulWidget {
  const _ChatViewBody({required this.thread});

  final InboxThread thread;

  @override
  State<_ChatViewBody> createState() => _ChatViewBodyState();
}

class _ChatViewBodyState extends State<_ChatViewBody> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _onSend() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();
    await context.read<ChatCubit>().sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.homeBackground,
      body: BlocListener<ChatCubit, ChatState>(
        listenWhen: (previous, current) =>
            previous.messages.length != current.messages.length ||
            previous.messages.lastOrNull?.sendStatus !=
                current.messages.lastOrNull?.sendStatus,
        listener: (context, state) => _scrollToBottom(),
        child: Column(
          children: [
            ChatScreenHeader(
              title: widget.thread.contactName,
              avatarUrl: widget.thread.avatarUrl,
              avatarName: widget.thread.contactName,
              onBack: () => Navigator.of(context).pop(),
              onCall: () {},
            ),
            Expanded(
              child: BlocSelector<ChatCubit, ChatState,
                  ({bool loading, bool error})>(
                selector: (state) => (
                  loading: state.isLoading,
                  error: state.hasError,
                ),
                builder: (context, shell) {
                  return GetRequestView(
                    isLoading: shell.loading,
                    hasError: shell.error,
                    onRetry: () => context.read<ChatCubit>().load(),
                    skeleton: const ChatMessagesSkeleton(),
                    child: _ChatMessagesPane(
                      scrollController: _scrollController,
                    ),
                  );
                },
              ),
            ),
            BlocSelector<ChatCubit, ChatState, bool>(
              selector: (state) => !state.isLoading && !state.hasError,
              builder: (context, enabled) {
                return ChatInputBar(
                  controller: _messageController,
                  onSend: _onSend,
                  enabled: enabled,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessagesPane extends StatelessWidget {
  const _ChatMessagesPane({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ChatCubit, ChatState, List<String>>(
      selector: (state) => [for (final message in state.messages) message.id],
      builder: (context, messageIds) {
        if (messageIds.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => context.read<ChatCubit>().load(),
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
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
              itemCount: messageIds.length,
              itemBuilder: (context, index) {
                final messageId = messageIds[index];
                return BlocSelector<ChatCubit, ChatState, ChatMessage?>(
                  selector: (state) {
                    for (final message in state.messages) {
                      if (message.id == messageId) return message;
                    }
                    return null;
                  },
                  builder: (context, message) {
                    if (message == null) return const SizedBox.shrink();
                    return ChatBubble(
                      message: message,
                      onRetry:
                          message.sendStatus == ChatMessageSendStatus.failed
                              ? () => context
                                  .read<ChatCubit>()
                                  .retryMessage(message.id)
                              : null,
                    );
                  },
                );
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
      },
    );
  }
}
