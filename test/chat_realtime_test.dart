import 'package:caregiver_app/core/network/chat_realtime_service.dart';
import 'package:caregiver_app/data/local/session_storage.dart';
import 'package:caregiver_app/data/local/token_storage.dart';
import 'package:caregiver_app/data/models/api/realtime_config_model.dart';
import 'package:caregiver_app/data/models/chat_message_model.dart';
import 'package:caregiver_app/data/repositories/inbox_repository.dart';
import 'package:caregiver_app/presentation/inbox/cubit/chat_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

class _Tokens implements TokenStorage {
  @override
  Future<String?> getToken() async => 'token';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Session implements SessionStorage {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Inbox implements InboxRepository {
  RealtimeConfigModel? config;
  int configCalls = 0;
  int fetchCalls = 0;
  List<ChatMessage> serverMessages = const [];

  @override
  Future<RealtimeConfigModel> getRealtimeConfig() async {
    configCalls++;
    return config!;
  }

  @override
  Future<List<ChatMessage>> fetchMessages(String threadId) async {
    fetchCalls++;
    return serverMessages;
  }

  @override
  Future<int> getUnreadCount() async => 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ChatMessage _msg(String id, String text) =>
    ChatMessage(id: id, text: text, direction: ChatMessageDirection.incoming);

void main() {
  group('RealtimeConfigModel', () {
    test('parses /realtime/config and resolves a relative auth endpoint', () {
      final config = RealtimeConfigModel.fromJson(
        {
          'data': {
            'enabled': true,
            'key': 'abc',
            'host': 'beydountech.com',
            'port': 443,
            'scheme': 'https',
            'auth_endpoint': '/broadcasting/auth',
            'channels': {
              'conversation': 'private-conversation.{threadId}',
              'user': 'private-user.{userId}',
            },
            'event': 'message.sent',
          },
        },
        apiBaseUrl: 'https://beydountech.com/api',
      );
      expect(config.isUsable, isTrue);
      expect(config.useTls, isTrue);
      expect(config.authEndpoint, 'https://beydountech.com/broadcasting/auth');
      expect(config.conversationChannel('7'), 'private-conversation.7');
      expect(config.userChannel('5'), 'private-user.5');
      expect(config.event, 'message.sent');
    });

    test('channel patterns as a list, defaults when missing', () {
      final config = RealtimeConfigModel.fromJson(
        {'enabled': false, 'key': 'abc', 'host': 'h', 'channels': ['private-user.{id}']},
        apiBaseUrl: 'https://x.test/api',
      );
      expect(config.isUsable, isFalse, reason: 'enabled: false = REST only');
      expect(config.userChannel('9'), 'private-user.9');
      expect(config.conversationChannel('3'), 'private-conversation.3');
      expect(config.port, 443);
    });
  });

  group('socket not live → REST', () {
    late _Inbox inbox;
    late ChatRealtimeService realtime;

    setUp(() {
      inbox = _Inbox()
        ..config = const RealtimeConfigModel(
          enabled: false,
          key: 'abc',
          host: 'beydountech.com',
          port: 443,
          useTls: true,
          authEndpoint: 'https://beydountech.com/broadcasting/auth',
        );
      realtime = ChatRealtimeService(
        tokenStorage: _Tokens(),
        sessionStorage: _Session(),
        inboxRepository: inbox,
      );
    });

    test('connect() refuses without touching the socket when enabled is false', () async {
      await expectLater(realtime.connect(), throwsA(isA<RealtimeUnavailableException>()));
      expect(realtime.conversationLive.value, isFalse);
      // Config is cached for the session.
      await expectLater(realtime.connect(), throwsA(isA<RealtimeUnavailableException>()));
      expect(inbox.configCalls, 1);
      await realtime.disconnect();
    });

    test('an open chat polls REST and shows new messages', () async {
      inbox.serverMessages = [_msg('1', 'Hi')];
      final cubit = ChatCubit(
        threadId: '7',
        repository: inbox,
        realtime: realtime,
        pollInterval: const Duration(milliseconds: 20),
      );

      await cubit.start();
      expect(cubit.state.messages.map((m) => m.id), ['1']);
      final afterStart = inbox.fetchCalls;

      inbox.serverMessages = [_msg('1', 'Hi'), _msg('2', 'Reply from the office')];
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(inbox.fetchCalls, greaterThan(afterStart));
      expect(cubit.state.messages.map((m) => m.id), ['1', '2']);

      await cubit.close();
      final calls = inbox.fetchCalls;
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(inbox.fetchCalls, calls, reason: 'polling stops when the chat closes');
      await realtime.disconnect();
    });
  });
}
