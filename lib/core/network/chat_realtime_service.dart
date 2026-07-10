import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';

import '../network/api_config.dart';
import '../../data/local/token_storage.dart';
import '../../data/mappers/api_mappers.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/local/session_storage.dart';
import '../../data/repositories/inbox_repository.dart';

/// Real-time chat over Laravel Reverb via [pusher_channels_flutter].
class ChatRealtimeService {
  ChatRealtimeService({
    required this._tokenStorage,
    required SessionStorage sessionStorage,
    required this._inboxRepository,
  })  : _sessionStorage = sessionStorage;

  final TokenStorage _tokenStorage;
  final SessionStorage _sessionStorage;
  final InboxRepository _inboxRepository;

  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();
  final _authDio = Dio(
    BaseOptions(
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: ApiConfig.defaultHeaders,
    ),
  );

  Completer<void>? _connectCompleter;
  Completer<void>? _socketReadyCompleter;
  bool _isConnecting = false;
  bool _isInitialized = false;
  String? _activeConversationChannel;
  String? _activeThreadId;
  String? _userChannelName;
  String? _currentUserId;
  Timer? _unreadPollTimer;

  final _messagesController = StreamController<ChatMessage>.broadcast();
  final _inboxUpdatesController = StreamController<void>.broadcast();

  Stream<ChatMessage> get messages => _messagesController.stream;

  Stream<void> get inboxUpdates => _inboxUpdatesController.stream;

  bool get isConnected => _pusher.connectionState == 'CONNECTED';

  Future<void> connect() async {
    if (ApiConfig.reverbAppKey.isEmpty) return;
    if (isConnected) return;
    if (_isConnecting) {
      await _connectCompleter?.future;
      return;
    }

    _isConnecting = true;
    _connectCompleter = Completer<void>();

    try {
      final token = await _tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        throw StateError('Missing auth token for chat socket.');
      }

      final user = await _sessionStorage.loadUser();
      _currentUserId = user?.id;

      if (!_isInitialized) {
        // Laravel Reverb (Pusher protocol). Official pub.dev Dart API omits
        // host/wssPort; this path package forwards them to native (required).
        await _pusher.init(
          apiKey: ApiConfig.reverbAppKey,
          cluster: 'mt1', // required by package; ignored by Reverb
          useTLS: ApiConfig.reverbUseTls,
          host: ApiConfig.reverbHost,
          wssPort: ApiConfig.reverbUseTls ? ApiConfig.reverbPort : null,
          wsPort: ApiConfig.reverbUseTls ? null : ApiConfig.reverbPort,
          onConnectionStateChange: _onConnectionStateChange,
          onEvent: _onEvent,
          onAuthorizer: _onAuthorizer,
          onSubscriptionError: (_, _) {},
          onError: (_, _, _) {},
        );
        _isInitialized = true;
      }

      if (_pusher.connectionState == 'CONNECTED') {
        // Already connected — state change callback won't fire again.
      } else {
        _socketReadyCompleter = Completer<void>();
        await _pusher.connect();
        await _socketReadyCompleter!.future.timeout(
          ApiConfig.connectTimeout,
          onTimeout: () => throw StateError('Socket connection timed out.'),
        );
      }

      _connectCompleter?.complete();
      await _ensureUserChannel();
      await _resubscribeActiveConversation();
    } catch (error, stackTrace) {
      _socketReadyCompleter = null;
      if (_connectCompleter?.isCompleted == false) {
        _connectCompleter?.completeError(error, stackTrace);
      }
      _startUnreadPolling();
      rethrow;
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> subscribeToConversation(String threadId) async {
    _activeThreadId = threadId;

    try {
      await connect();
    } catch (_) {
      _startUnreadPolling();
      return;
    }

    final channelName = 'private-conversation.$threadId';
    if (_activeConversationChannel == channelName && isConnected) return;

    await unsubscribeConversation(clearThread: false);

    await _pusher.subscribe(
      channelName: channelName,
      onEvent: _onEvent,
    );
    _activeConversationChannel = channelName;
  }

  Future<void> unsubscribeConversation({bool clearThread = true}) async {
    final channelName = _activeConversationChannel;
    if (channelName == null) {
      if (clearThread) _activeThreadId = null;
      return;
    }

    try {
      await _pusher.unsubscribe(channelName: channelName);
    } catch (_) {}
    _activeConversationChannel = null;
    if (clearThread) _activeThreadId = null;
  }

  Future<void> _ensureUserChannel() async {
    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) return;

    final channelName = 'private-user.$userId';
    if (_userChannelName == channelName) return;

    if (_userChannelName != null) {
      try {
        await _pusher.unsubscribe(channelName: _userChannelName!);
      } catch (_) {}
    }

    await _pusher.subscribe(
      channelName: channelName,
      onEvent: _onEvent,
    );
    _userChannelName = channelName;
  }

  Future<void> _resubscribeActiveConversation() async {
    final threadId = _activeThreadId;
    if (threadId == null || threadId.isEmpty) return;

    _activeConversationChannel = null;
    await subscribeToConversation(threadId);
  }

  Future<dynamic> _onAuthorizer(
    String channelName,
    String socketId,
    dynamic options,
  ) async {
    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      throw StateError('Missing auth token for channel authorization.');
    }

    final response = await _authDio.post<dynamic>(
      ApiConfig.broadcastingAuthUrl,
      data: {
        'channel_name': channelName,
        'socket_id': socketId,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        responseType: ResponseType.json,
      ),
    );

    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String && data.isNotEmpty) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }

    throw StateError('Invalid broadcasting auth response.');
  }

  void _onConnectionStateChange(String currentState, String previousState) {
    final current = currentState.toUpperCase();

    if (current == 'CONNECTED') {
      _socketReadyCompleter?.complete();
      _socketReadyCompleter = null;
      _stopUnreadPolling();
      return;
    }

    if (current == 'DISCONNECTED' ||
        current == 'FAILED' ||
        current == 'UNAVAILABLE') {
      _socketReadyCompleter = null;
      _startUnreadPolling();
    }
  }

  void _onEvent(PusherEvent event) {
    if (!_isMessageSentEvent(event.eventName)) return;

    try {
      final json = _parseEventPayload(event.data);
      if (json == null) return;

      final channelName = event.channelName;
      final threadId = _activeThreadId;

      if (channelName.startsWith('private-conversation.')) {
        _emitConversationMessage(json);
        return;
      }

      if (channelName.startsWith('private-user.')) {
        if (threadId != null) {
          final eventThreadId = json['thread_id']?.toString();
          if (eventThreadId == threadId) {
            _emitConversationMessage(json);
          }
        }
        if (!_inboxUpdatesController.isClosed) {
          _inboxUpdatesController.add(null);
        }
      }
    } catch (_) {
      // Ignore malformed socket payloads; REST remains source of truth.
    }
  }

  void _emitConversationMessage(Map<String, dynamic> json) {
    final message = realtimeMessageToChatMessage(
      json: json,
      currentUserId: _currentUserId,
    );
    if (!_messagesController.isClosed) {
      _messagesController.add(message);
    }
  }

  bool _isMessageSentEvent(String eventName) {
    if (eventName == 'message.sent') return true;
    return eventName.endsWith('.message.sent') ||
        eventName.endsWith('MessageSent');
  }

  Map<String, dynamic>? _parseEventPayload(dynamic raw) {
    dynamic decoded = raw;
    if (decoded is String && decoded.isNotEmpty) {
      decoded = jsonDecode(decoded);
    }
    if (decoded is! Map) return null;

    final map = Map<String, dynamic>.from(decoded);
    final message = map['message'];
    if (message is Map) {
      return Map<String, dynamic>.from(message);
    }
    final data = map['data'];
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    if (map.containsKey('body') || map.containsKey('id')) {
      return map;
    }
    return null;
  }

  void _startUnreadPolling() {
    if (_unreadPollTimer != null) return;
    _unreadPollTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        await _inboxRepository.getUnreadCount();
        if (!_inboxUpdatesController.isClosed) {
          _inboxUpdatesController.add(null);
        }
      } catch (_) {}
    });
  }

  void _stopUnreadPolling() {
    _unreadPollTimer?.cancel();
    _unreadPollTimer = null;
  }

  Future<void> disconnect() async {
    _stopUnreadPolling();
    _activeThreadId = null;
    await unsubscribeConversation(clearThread: false);

    if (_userChannelName != null) {
      try {
        await _pusher.unsubscribe(channelName: _userChannelName!);
      } catch (_) {}
      _userChannelName = null;
    }

    try {
      await _pusher.disconnect();
    } catch (_) {}
    _isInitialized = false;
    _socketReadyCompleter = null;
  }

  Future<void> dispose() async {
    await disconnect();
    await _messagesController.close();
    await _inboxUpdatesController.close();
  }
}
