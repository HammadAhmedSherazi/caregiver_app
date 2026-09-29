import 'package:equatable/equatable.dart';

/// `GET /api/realtime/config` — how to reach the chat socket (Laravel Reverb,
/// Pusher protocol). The server owns these values; the app never hardcodes
/// the key (FLUTTER_SOCKET_CONNECT.pdf §2).
class RealtimeConfigModel extends Equatable {
  const RealtimeConfigModel({
    required this.enabled,
    required this.key,
    required this.host,
    required this.port,
    required this.useTls,
    required this.authEndpoint,
    this.conversationChannelPattern = defaultConversationPattern,
    this.userChannelPattern = defaultUserPattern,
    this.event = defaultEvent,
  });

  static const defaultConversationPattern = 'private-conversation.{threadId}';
  static const defaultUserPattern = 'private-user.{userId}';
  static const defaultEvent = 'message.sent';

  /// `false` = sockets are not live yet; stay on REST polling.
  final bool enabled;
  final String key;
  final String host;
  final int port;
  final bool useTls;

  /// Absolute URL for private-channel auth (`POST`, same Bearer token).
  final String authEndpoint;
  final String conversationChannelPattern;
  final String userChannelPattern;
  final String event;

  /// Connecting needs at least a key and a host.
  bool get isUsable => enabled && key.isNotEmpty && host.isNotEmpty;

  String conversationChannel(String threadId) => _fill(conversationChannelPattern, threadId);

  String userChannel(String userId) => _fill(userChannelPattern, userId);

  static String _fill(String pattern, String id) => pattern.replaceAll(RegExp(r'\{[^}]*\}'), id);

  /// [apiBaseUrl] resolves a relative `auth_endpoint` (e.g. `/broadcasting/auth`).
  factory RealtimeConfigModel.fromJson(Map<String, dynamic> json, {required String apiBaseUrl}) {
    final raw = json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : json;
    final scheme = (raw['scheme'] ?? 'https').toString().toLowerCase();
    final useTls = scheme != 'http' && scheme != 'ws';
    final port = raw['port'] is num ? (raw['port'] as num).toInt() : int.tryParse('${raw['port']}');

    final patterns = <String>[];
    final channels = raw['channels'];
    if (channels is Map) {
      patterns.addAll(channels.values.map((v) => '$v'));
    } else if (channels is List) {
      patterns.addAll(channels.map((v) => '$v'));
    } else if (channels is String) {
      patterns.add(channels);
    }
    String pick(String marker, String fallback) =>
        patterns.firstWhere((p) => p.contains(marker), orElse: () => fallback);

    final authRaw = (raw['auth_endpoint'] ?? '').toString().trim();

    return RealtimeConfigModel(
      enabled: raw['enabled'] == true,
      key: (raw['key'] ?? '').toString(),
      host: (raw['host'] ?? '').toString(),
      port: port ?? (useTls ? 443 : 80),
      useTls: useTls,
      authEndpoint: authRaw.isEmpty ? '' : Uri.parse(apiBaseUrl).resolve(authRaw).toString(),
      conversationChannelPattern: pick('conversation', defaultConversationPattern),
      userChannelPattern: pick('user', defaultUserPattern),
      event: (raw['event'] ?? '').toString().isEmpty ? defaultEvent : raw['event'].toString(),
    );
  }

  @override
  List<Object?> get props => [
        enabled, key, host, port, useTls, authEndpoint,
        conversationChannelPattern, userChannelPattern, event,
      ];
}
