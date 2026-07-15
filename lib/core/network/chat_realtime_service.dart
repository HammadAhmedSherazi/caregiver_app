import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
    required this._sessionStorage,
    required this._inboxRepository,
  });

  final TokenStorage _tokenStorage;
  final SessionStorage _sessionStorage;
  final InboxRepository _inboxRepository;

  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();
  final _authDio = Dio(
    BaseOptions(
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: ApiConfig.defaultHeaders,
      validateStatus: (status) => status != null && status < 500,
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
  bool _shouldAutoResume = false;

  final _messagesController = StreamController<ChatMessage>.broadcast();
  final _inboxUpdatesController = StreamController<void>.broadcast();
  final _pendingSubscriptionCompleters = <String, Completer<void>>{};

  Stream<ChatMessage> get messages => _messagesController.stream;

  Stream<void> get inboxUpdates => _inboxUpdatesController.stream;

  bool get isConnected => _pusher.connectionState == 'CONNECTED';

  Future<void> connect() async {
    if (ApiConfig.reverbAppKey.isEmpty) return;

    // Already connected — still ensure channels (early return used to skip listen).
    if (isConnected) {
      try {
        await _ensureUserChannel();
      } catch (error) {
        debugPrint('Pusher: user channel subscribe failed: $error');
        _startUnreadPolling();
      }
      try {
        await _bindActiveConversationChannel();
      } catch (error) {
        debugPrint('Pusher: conversation channel subscribe failed: $error');
      }
      return;
    }

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

      await _refreshCurrentUserId();

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
          onSubscriptionSucceeded: _onSubscriptionSucceeded,
          onSubscriptionError: _onSubscriptionError,
          onError: (message, code, error) {
            debugPrint('Pusher error: $message code=$code error=$error');
          },
        );
        _isInitialized = true;
      }

      if (_pusher.connectionState != 'CONNECTED') {
        _socketReadyCompleter = Completer<void>();
        await _pusher.connect();
        await _socketReadyCompleter!.future.timeout(
          ApiConfig.connectTimeout,
          onTimeout: () => throw StateError('Socket connection timed out.'),
        );
      }

      if (!(_connectCompleter?.isCompleted ?? true)) {
        _connectCompleter?.complete();
      }
      try {
        await _ensureUserChannel();
      } catch (error) {
        debugPrint('Pusher: user channel subscribe failed: $error');
        _startUnreadPolling();
      }
      try {
        await _bindActiveConversationChannel();
      } catch (error) {
        debugPrint('Pusher: conversation channel subscribe failed: $error');
      }
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

    await _bindActiveConversationChannel();
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
    _pendingSubscriptionCompleters.remove(channelName);
    _activeConversationChannel = null;
    if (clearThread) _activeThreadId = null;
  }

  Future<void> _refreshCurrentUserId() async {
    // Prefer AuthCubit / session after refresh — must be Sanctum user id,
    // not caregiver profile id from /me.
    final user = await _sessionStorage.loadUser();
    _currentUserId = user?.id;
    if (_currentUserId == null ||
        _currentUserId!.isEmpty ||
        _currentUserId == '0') {
      debugPrint('Pusher: no valid auth user id — private-user channel skipped');
    } else {
      debugPrint('Pusher: session user id=$_currentUserId');
    }
  }

  Future<void> _ensureUserChannel({bool force = false}) async {
    if (_currentUserId == null || _currentUserId!.isEmpty) {
      await _refreshCurrentUserId();
    }

    final userId = _currentUserId;
    if (userId == null || userId.isEmpty) return;

    final channelName = 'private-user.$userId';
    if (!force && _userChannelName == channelName && isConnected) return;

    if (_userChannelName != null && _userChannelName != channelName) {
      try {
        await _pusher.unsubscribe(channelName: _userChannelName!);
      } catch (_) {}
      _pendingSubscriptionCompleters.remove(_userChannelName);
    } else if (force && _userChannelName == channelName) {
      try {
        await _pusher.unsubscribe(channelName: channelName);
      } catch (_) {}
      _pendingSubscriptionCompleters.remove(channelName);
    }

    await _subscribePrivate(channelName);
    _userChannelName = channelName;
  }

  Future<void> _subscribePrivate(String channelName) async {
    final existing = _pendingSubscriptionCompleters[channelName];
    if (existing != null && !existing.isCompleted) {
      await existing.future.timeout(
        ApiConfig.connectTimeout,
        onTimeout: () {},
      );
      return;
    }

    final completer = Completer<void>();
    _pendingSubscriptionCompleters[channelName] = completer;

    debugPrint('Pusher: subscribing $channelName');
    // Channel-level onEvent is Function(dynamic)?; global init onEvent already
    // receives every event — do not pass typed _onEvent here (causes subtype error).
    await _pusher.subscribe(
      channelName: channelName,
      onSubscriptionSucceeded: (dynamic _) {
        if (!completer.isCompleted) completer.complete();
      },
    );

    try {
      await completer.future.timeout(ApiConfig.connectTimeout);
      debugPrint('Pusher: subscribed $channelName');
    } on TimeoutException {
      debugPrint(
        'Pusher: subscription timeout for $channelName '
        '(auth may have failed — check /broadcasting/auth)',
      );
      _pendingSubscriptionCompleters.remove(channelName);
      rethrow;
    }
  }

  Future<void> _bindActiveConversationChannel() async {
    final threadId = _activeThreadId;
    if (threadId == null || threadId.isEmpty) return;

    final channelName = 'private-conversation.$threadId';
    if (_activeConversationChannel == channelName && isConnected) return;

    await unsubscribeConversation(clearThread: false);
    await _subscribePrivate(channelName);
    _activeConversationChannel = channelName;
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

    debugPrint('Pusher auth → $channelName socket=$socketId');

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

    final status = response.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      debugPrint('Pusher auth ✗ $channelName status=$status body=${response.data}');
      throw StateError('Broadcasting auth failed ($status) for $channelName');
    }

    final data = response.data;
    Map<String, dynamic>? authPayload;
    if (data is Map<String, dynamic>) {
      authPayload = data;
    } else if (data is Map) {
      authPayload = Map<String, dynamic>.from(data);
    } else if (data is String && data.isNotEmpty) {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        authPayload = decoded;
      } else if (decoded is Map) {
        authPayload = Map<String, dynamic>.from(decoded);
      }
    }

    if (authPayload == null || authPayload['auth'] is! String) {
      debugPrint('Pusher auth ✗ invalid payload for $channelName: $data');
      throw StateError('Invalid broadcasting auth response for $channelName');
    }

    debugPrint('Pusher auth ✓ $channelName');
    return authPayload;
  }

  void _onSubscriptionSucceeded(String channelName, dynamic data) {
    debugPrint('Pusher: subscription succeeded $channelName');
    final completer = _pendingSubscriptionCompleters.remove(channelName);
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }

  void _onSubscriptionError(String message, dynamic error) {
    debugPrint('Pusher: subscription error message=$message error=$error');
    for (final entry in _pendingSubscriptionCompleters.entries.toList()) {
      final completer = entry.value;
      if (!completer.isCompleted) {
        completer.completeError(
          StateError('Subscription failed: $message'),
        );
      }
      _pendingSubscriptionCompleters.remove(entry.key);
    }
  }

  void _onConnectionStateChange(String currentState, String previousState) {
    final current = currentState.toUpperCase();

    if (current == 'CONNECTED') {
      final ready = _socketReadyCompleter;
      if (ready != null && !ready.isCompleted) {
        ready.complete();
      }
      _socketReadyCompleter = null;
      _stopUnreadPolling();

      // Native reconnect drops private channel membership — re-bind listen.
      if (!_isConnecting) {
        unawaited(() async {
          try {
            await _ensureUserChannel();
            await _bindActiveConversationChannel();
          } catch (error) {
            debugPrint('Pusher: resubscribe after connect failed: $error');
            _startUnreadPolling();
          }
        }());
      }
      return;
    }

    if (current == 'DISCONNECTED' ||
        current == 'FAILED' ||
        current == 'UNAVAILABLE') {
      _socketReadyCompleter = null;
      _userChannelName = null;
      _activeConversationChannel = null;
      _pendingSubscriptionCompleters.clear();
      _startUnreadPolling();
    }
  }

  void _onEvent(PusherEvent event) {
    if (event.eventName.startsWith('pusher:')) return;

    if (!_isMessageSentEvent(event.eventName)) {
      debugPrint(
        'Pusher: ignored event=${event.eventName} channel=${event.channelName}',
      );
      return;
    }

    debugPrint(
      'Pusher: message.sent on ${event.channelName} data=${event.data}',
    );

    try {
      final json = _parseEventPayload(event.data);
      if (json == null) {
        debugPrint('Pusher: could not parse message payload');
        return;
      }

      final channelName = event.channelName;
      final threadId = _activeThreadId;

      if (channelName.startsWith('private-conversation.')) {
        _emitConversationMessage(json);
        return;
      }

      if (channelName.startsWith('private-user.')) {
        if (threadId != null) {
          final eventThreadId = json['thread_id']?.toString() ??
              json['conversation_id']?.toString();
          if (eventThreadId == threadId) {
            _emitConversationMessage(json);
          }
        }
        if (!_inboxUpdatesController.isClosed) {
          _inboxUpdatesController.add(null);
        }
      }
    } catch (error) {
      debugPrint('Pusher: event handling error: $error');
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
    _shouldAutoResume = false;
    _activeThreadId = null;
    await unsubscribeConversation(clearThread: false);

    if (_userChannelName != null) {
      try {
        await _pusher.unsubscribe(channelName: _userChannelName!);
      } catch (_) {}
      _userChannelName = null;
    }

    _pendingSubscriptionCompleters.clear();

    // Skip native disconnect when chat socket was never initialized (logout crash).
    if (_isInitialized) {
      try {
        await _pusher.disconnect();
      } catch (_) {}
      _isInitialized = false;
    }
    _pusher.connectionState = 'DISCONNECTED';
    _socketReadyCompleter = null;
  }

  /// App background / process pause — drop socket but keep conversation intent
  /// so reopen (without logout) can resubscribe cleanly.
  Future<void> suspend() async {
    _shouldAutoResume = _isInitialized ||
        isConnected ||
        _userChannelName != null ||
        _activeThreadId != null;
    if (!_shouldAutoResume) return;

    debugPrint('Pusher: suspend (app background/close)');
    _stopUnreadPolling();
    _userChannelName = null;
    _activeConversationChannel = null;
    _pendingSubscriptionCompleters.clear();
    _isConnecting = false;
    _socketReadyCompleter = null;

    if (_isInitialized) {
      try {
        await _pusher.disconnect();
      } catch (_) {}
      _isInitialized = false;
    }
    _pusher.connectionState = 'DISCONNECTED';
  }

  /// App foreground — refresh auth context and restore private channels.
  Future<void> resume() async {
    if (!_shouldAutoResume && _activeThreadId == null) return;

    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) return;

    debugPrint('Pusher: resume (app foreground)');
    // Force channel rebind even if Dart thought it was still subscribed.
    _userChannelName = null;
    _activeConversationChannel = null;

    try {
      await connect();
      _shouldAutoResume = true;
    } catch (error) {
      debugPrint('Pusher: resume connect failed: $error');
      _startUnreadPolling();
    }
  }

  Future<void> dispose() async {
    await disconnect();
    await _messagesController.close();
    await _inboxUpdatesController.close();
  }
}
