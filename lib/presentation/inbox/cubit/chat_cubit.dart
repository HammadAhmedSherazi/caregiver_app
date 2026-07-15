import 'dart:async';

import '../../../core/base/base_cubit.dart';
import '../../../core/network/chat_realtime_service.dart';
import '../../../data/mappers/api_mappers.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../data/repositories/inbox_repository.dart';
import 'chat_state.dart';

class ChatCubit extends BaseCubit<ChatState> {
  ChatCubit({
    required this.threadId,
    required this.repository,
    required this.realtime,
  }) : super(const ChatState());

  final String threadId;
  final InboxRepository repository;
  final ChatRealtimeService realtime;

  StreamSubscription<ChatMessage>? _socketSub;

  Future<void> start() async {
    await load();
    await _initSocket();
  }

  Future<void> load() async {
    emit(state.copyWith(status: ChatStatus.loading));

    try {
      final items = await repository.fetchMessages(threadId);
      emit(
        state.copyWith(
          status: ChatStatus.success,
          messages: items,
        ),
      );
    } catch (error, stackTrace) {
      logError('Failed to load chat', error: error, stackTrace: stackTrace);
      emit(state.copyWith(status: ChatStatus.failure));
    }
  }

  Future<void> _initSocket() async {
    await _socketSub?.cancel();
    _socketSub = realtime.messages.listen(_onSocketMessage);
    try {
      await realtime.subscribeToConversation(threadId);
    } catch (error, stackTrace) {
      logError(
        'Chat socket subscribe failed',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _onSocketMessage(ChatMessage message) {
    if (state.messages.any((m) => m.id == message.id)) return;

    final optimisticIndex = state.messages.indexWhere(
      (m) =>
          m.sendStatus == ChatMessageSendStatus.sending &&
          m.direction == ChatMessageDirection.outgoing &&
          m.text == message.text,
    );

    if (optimisticIndex >= 0) {
      final updated = [...state.messages];
      updated[optimisticIndex] = message;
      emit(state.copyWith(messages: updated));
      return;
    }

    emit(state.copyWith(messages: [...state.messages, message]));
  }

  Future<void> sendMessage(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty) return;

    final localId = 'local-${DateTime.now().microsecondsSinceEpoch}';
    final optimistic = ChatMessage(
      id: localId,
      text: text,
      direction: ChatMessageDirection.outgoing,
      timestampLabel: formatTimeLabel(DateTime.now()),
      sendStatus: ChatMessageSendStatus.sending,
    );

    emit(state.copyWith(messages: [...state.messages, optimistic]));
    await _deliverMessage(localId: localId, text: text);
  }

  Future<void> retryMessage(String messageId) async {
    ChatMessage? target;
    for (final message in state.messages) {
      if (message.id == messageId) {
        target = message;
        break;
      }
    }
    if (target == null || target.sendStatus != ChatMessageSendStatus.failed) {
      return;
    }

    emit(
      state.copyWith(
        messages: [
          for (final item in state.messages)
            if (item.id == messageId)
              item.copyWith(sendStatus: ChatMessageSendStatus.sending)
            else
              item,
        ],
      ),
    );

    await _deliverMessage(localId: target.id, text: target.text);
  }

  Future<void> _deliverMessage({
    required String localId,
    required String text,
  }) async {
    try {
      final message = await repository.sendMessage(
        threadId: threadId,
        body: text,
      );

      final withoutLocal =
          state.messages.where((item) => item.id != localId).toList();
      final alreadyPresent = withoutLocal.any((item) => item.id == message.id);
      emit(
        state.copyWith(
          messages: alreadyPresent ? withoutLocal : [...withoutLocal, message],
        ),
      );
    } catch (error, stackTrace) {
      logError('Failed to send chat message', error: error, stackTrace: stackTrace);
      emit(
        state.copyWith(
          messages: [
            for (final item in state.messages)
              if (item.id == localId)
                item.copyWith(sendStatus: ChatMessageSendStatus.failed)
              else
                item,
          ],
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _socketSub?.cancel();
    await realtime.unsubscribeConversation();
    return super.close();
  }
}
