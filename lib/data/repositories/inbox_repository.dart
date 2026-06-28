import '../models/chat_message_model.dart';
import '../models/inbox_thread_model.dart';

abstract class InboxRepository {
  Future<List<InboxThread>> fetchThreads();
  Future<List<ChatMessage>> fetchMessages(String threadId);
}

class InboxRepositoryImpl implements InboxRepository {
  @override
  Future<List<InboxThread>> fetchThreads() async {
    return const [];
  }

  @override
  Future<List<ChatMessage>> fetchMessages(String threadId) async {
    return const [];
  }
}
