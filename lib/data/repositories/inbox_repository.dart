import '../api/caregiver_api.dart';
import '../mappers/api_mappers.dart';
import '../models/chat_message_model.dart';
import '../models/inbox_thread_model.dart';

abstract class InboxRepository {
  Future<List<InboxThread>> fetchThreads();
  Future<List<ChatMessage>> fetchMessages(String threadId);
  Future<ChatMessage> sendMessage({
    required String threadId,
    required String body,
  });
  Future<int> getUnreadCount();
}

class InboxRepositoryImpl implements InboxRepository {
  InboxRepositoryImpl({required this._api});

  final CaregiverApi _api;

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
}
