import '../api/caregiver_api.dart';
import '../mappers/api_mappers.dart';
import '../models/api/realtime_config_model.dart';
import '../models/chat_message_model.dart';
import '../models/inbox_thread_model.dart';
import '../api/velora_api.dart';
import '../models/api/velora/velora_models.dart';

abstract class InboxRepository {
  Future<List<InboxThread>> fetchThreads();
  Future<List<ChatMessage>> fetchMessages(String threadId);
  Future<ChatMessage> sendMessage({
    required String threadId,
    required String body,
  });
  Future<int> getUnreadCount();

  /// `GET /realtime/config` — socket values; `enabled: false` = REST only.
  Future<RealtimeConfigModel> getRealtimeConfig();

  /// `GET /inbox/office-thread` — 🚧 PLANNED — NOT LIVE. Messages then use
  /// the existing `/conversations/{thread_id}` endpoints.
  Future<OfficeThreadModel> getOfficeThread();
}

class InboxRepositoryImpl implements InboxRepository {
  InboxRepositoryImpl({required this._api, required this._velora});

  final CaregiverApi _api;
  final VeloraApi _velora;

  @override
  Future<OfficeThreadModel> getOfficeThread() => _velora.getOfficeThread();

  @override
  Future<List<InboxThread>> fetchThreads() async {
    final response = await _api.getConversations();
    return response.data.map(conversationToInboxThread).toList();
  }

  @override
  Future<List<ChatMessage>> fetchMessages(String threadId) async {
    final conversation = await _api.getConversation(int.parse(threadId));
    return conversation.messages.map(conversationMessageToChatMessage).toList();
  }

  @override
  Future<ChatMessage> sendMessage({
    required String threadId,
    required String body,
  }) async {
    final message = await _api.sendConversationMessage(
      conversationId: int.parse(threadId),
      body: body,
    );
    return conversationMessageToChatMessage(message);
  }

  @override
  Future<int> getUnreadCount() => _api.getConversationsUnreadCount();

  @override
  Future<RealtimeConfigModel> getRealtimeConfig() => _api.getRealtimeConfig();
}
