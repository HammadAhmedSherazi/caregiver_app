import 'dart:async';
import 'dart:convert';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';

import '../network/api_config.dart';
import '../../data/local/token_storage.dart';
import '../../data/mappers/api_mappers.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/local/session_storage.dart';

/// Real-time chat over Laravel Reverb (Pusher protocol).
class ChatRealtimeService {
  ChatRealtimeService({
    required TokenStorage tokenStorage,
    required SessionStorage sessionStorage,
  })  : _tokenStorage = tokenStorage,
        _sessionStorage = sessionStorage;

  final TokenStorage _tokenStorage;
  final SessionStorage _sessionStorage;

  PusherChannelsClient? _client;
  PrivateChannel? _channel;
  StreamSubscription<void>? _connectionSub;
  StreamSubscription<ChannelReadEvent>? _eventSub;
  Completer<void>? _connectCompleter;
  bool _isConnecting = false;

  final _messagesController = StreamController<ChatMessage>.broadcast();

  Stream<ChatMessage> get messages => _messagesController.stream;

  bool get isConnected => _client != null;

  Future<void> connect() async {
    if (_client != null) return;
    if (_isConnecting) {
      await _connectCompleter?.future;
      return;
    }

    _isConnecting = true;
    _connectCompleter = Completer<void>();

    try {
      // Defaults are placeholders. If these are still present, it's almost
      // guaranteed that the websocket server won't match and handshake fails.
      if (ApiConfig.reverbAppKey == 'local-key') {
        throw StateError(
          'Missing REVERB_APP_KEY (set via --dart-define=REVERB_APP_KEY=...).',
        );
      }
      if (ApiConfig.reverbHost == 'www.beydountech.com') {
        throw StateError(
          'Missing/incorrect REVERB_HOST (set via --dart-define=REVERB_HOST=...).',
        );
      }

      final token = await _tokenStorage.getToken();
      if (token == null || token.isEmpty) {
        throw StateError('Missing auth token for chat socket.');
      }

      final options = PusherChannelsOptions.fromHost(
        scheme: ApiConfig.reverbScheme,
        host: ApiConfig.reverbHost,
        port: ApiConfig.reverbPort,
        key: ApiConfig.reverbAppKey,
        shouldSupplyMetadataQueries: true,
        metadata: PusherChannelsOptionsMetadata.byDefault(),
      );

      final client = PusherChannelsClient.websocket(
        options: options,
        connectionErrorHandler: (exception, trace, refresh) {
          refresh();
        },
      );

      _client = client;
      await client.connect();
      _connectCompleter?.complete();
    } catch (error, stackTrace) {
      _connectCompleter?.completeError(error, stackTrace);
      await disconnect();
      rethrow;
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> subscribeToConversation(String threadId) async {
    await connect();

    final client = _client;
    if (client == null) return;

    await unsubscribeConversation();

    final token = await _tokenStorage.getToken();
    if (token == null || token.isEmpty) return;

    final user = await _sessionStorage.loadUser();
    final currentUserId = user?.id;

    final channel = client.privateChannel(
      'private-conversation.$threadId',
      authorizationDelegate:
          EndpointAuthorizableChannelTokenAuthorizationDelegate
              .forPrivateChannel(
        authorizationEndpoint: Uri.parse(ApiConfig.broadcastingAuthUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ),
    );

    _channel = channel;
    _connectionSub = client.onConnectionEstablished.listen((_) {
      channel.subscribeIfNotUnsubscribed();
    });

    // Laravel Echo listens as `.message.sent` → event name `message.sent`.
    _eventSub = channel.bind('message.sent').listen((event) {
      try {
        final raw = event.data;
        final Map<String, dynamic> json;
        if (raw is Map<String, dynamic>) {
          json = raw;
        } else if (raw is String) {
          final decoded = jsonDecode(raw);
          if (decoded is! Map<String, dynamic>) return;
          json = decoded;
        } else {
          return;
        }

        final message = realtimeMessageToChatMessage(
          json: json,
          currentUserId: currentUserId,
        );
        if (!_messagesController.isClosed) {
          _messagesController.add(message);
        }
      } catch (_) {
        // Ignore malformed socket payloads; REST remains source of truth.
      }
    });

    channel.subscribeIfNotUnsubscribed();
  }

  Future<void> unsubscribeConversation() async {
    await _eventSub?.cancel();
    _eventSub = null;
    await _connectionSub?.cancel();
    _connectionSub = null;
    try {
      _channel?.unsubscribe();
    } catch (_) {}
    _channel = null;
  }

  Future<void> disconnect() async {
    await unsubscribeConversation();
    try {
      _client?.dispose();
    } catch (_) {}
    _client = null;
  }

  Future<void> dispose() async {
    await disconnect();
    await _messagesController.close();
  }
}
