import 'dart:async';

import '../../../core/base/base_cubit.dart';
import '../../../core/network/api_config.dart';
import '../../../core/network/chat_realtime_service.dart';
import '../../../data/mappers/api_mappers.dart';
import '../../../data/models/chat_message_model.dart';
import '../../../data/repositories/inbox_repository.dart';
import 'chat_state.dart';

/// One chat thread. Messages come from `GET /conversations/{id}`; new ones
/// arrive over the socket when it is live, otherwise by polling the same
/// endpoint every [pollInterval] (FLUTTER_SOCKET_CONNECT.pdf:
/// keep the REST path working until the socket is live).
class ChatCubit extends BaseCubit<ChatState> {
  ChatCubit({
    required this.threadId,
    required this.repository,
    required this.realtime,
    this.pollInterval = ApiConfig.chatPollInterval,
  }) : super(const ChatState());

  /// How often to fetch messages while the socket is not live.
  final Duration pollInterval;

  final String threadId;
  final InboxRepository repository;
  final ChatRealtimeService realtime;

  StreamSubscription<ChatMessage>? _socketSub;
  Timer? _pollTimer;
  bool _polling = false;

  /// True while another thread's [ChatView] is open on top of the inline
  /// office chat — the realtime service holds one conversation at a time.
  bool _paused = false;

  Future<void> start() async {
    await load();
    realtime.conversationLive.addListener(_syncPolling);
    _syncPolling();
    await _initSocket();
  }

  /// Poll only while the conversation channel is not subscribed.
  void _syncPolling() {
    if (isClosed) return;
    if (_paused || realtime.conversationLive.value) {
      _pollTimer?.cancel();
      _pollTimer = null;
    } else {
      _pollTimer ??= Timer.periodic(pollInterval, (_) => _poll());
    }
  }

  Future<void> _poll() async {
    // Skip while a send is in flight: the send result replaces the
    // optimistic bubble, and a poll could briefly show it twice.
    if (_polling || _paused || isClosed || state.status != ChatStatus.success) return;
    if (state.messages.any((m) => m.sendStatus == ChatMessageSendStatus.sending)) return;
    _polling = true;
    try {
      final items = await repository.fetchMessages(threadId);
      if (isClosed) return;
      final failed = state.messages.where((m) => m.sendStatus == ChatMessageSendStatus.failed);
      final merged = [...items, ...failed];
      if (merged.length != state.messages.length ||
          !Iterable.generate(merged.length).every((i) => merged[i] == state.messages[i])) {
        emit(state.copyWith(messages: merged));
      }
    } catch (error) {
      // Keep what is on screen; the next tick tries again.
      logError('Chat poll failed', error: error);
    } finally {
      _polling = false;
    }
  }

  /// Stops socket and polling updates (another conversation is open).
  Future<void> pause() async {
    _paused = true;
    _pollTimer?.cancel();
    _pollTimer = null;
    await _socketSub?.cancel();
    _socketSub = null;
  }

  /// Re-subscribes after [pause] and catches up on missed messages.
  Future<void> resume() async {
    if (isClosed || !_paused) return;
    _paused = false;
    _syncPolling();
    await _initSocket();
    await _poll();
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
    if (_paused) return;
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
    realtime.conversationLive.removeListener(_syncPolling);
    _pollTimer?.cancel();
    await _socketSub?.cancel();
    await realtime.unsubscribeConversation();
    return super.close();
  }
}
