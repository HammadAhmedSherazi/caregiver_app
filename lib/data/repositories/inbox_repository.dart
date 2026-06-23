import '../models/chat_message_model.dart';
import '../models/inbox_thread_model.dart';

abstract class InboxRepository {
  Future<List<InboxThread>> fetchThreads();
  Future<List<ChatMessage>> fetchMessages(String threadId);
}

class InboxRepositoryImpl implements InboxRepository {
  static const _threads = [
    InboxThread(
      id: '1',
      contactName: 'James C',
      preview:
          'Hi Designers, checkout this article; Learn more about the laws of U.I Design.',
      timestampLabel: '4 days ago',
      avatarUrl: 'https://i.pravatar.cc/150?u=james-c-1',
    ),
    InboxThread(
      id: '2',
      contactName: 'Salena James',
      preview:
          'Hi Designers, checkout this article; Learn more about the laws of U.I Design.',
      timestampLabel: '4 days ago',
      avatarUrl: 'https://i.pravatar.cc/150?u=salena-james',
    ),
    InboxThread(
      id: '3',
      contactName: 'James C',
      preview:
          'Hi Designers, checkout this article; Learn more about the laws of U.I Design.',
      timestampLabel: '4 days ago',
      avatarUrl: 'https://i.pravatar.cc/150?u=james-c-2',
    ),
    InboxThread(
      id: '4',
      contactName: 'James C',
      preview:
          'Hi Designers, checkout this article; Learn more about the laws of U.I Design.',
      timestampLabel: '4 days ago',
      avatarUrl: 'https://i.pravatar.cc/150?u=james-c-3',
    ),
  ];

  static const _conversation = [
    ChatMessage(
      id: 'm1',
      text:
          'Thank you for contacting Closet. Please let us know how we can help you.',
      direction: ChatMessageDirection.incoming,
    ),
    ChatMessage(
      id: 'm2',
      text: '''What would you like assistance with?

1. Account setup help.
2. Facing Login issue.
3. How do I add my apparel to the event calendar?

Please select one of the options above, or feel free to ask any other questions you may have''',
      direction: ChatMessageDirection.incoming,
      isNumberedList: true,
    ),
    ChatMessage(
      id: 'm3',
      text: '1',
      direction: ChatMessageDirection.outgoing,
      timestampLabel: '11:35 AM',
    ),
    ChatMessage(
      id: 'm4',
      text:
          "I'd be happy to help you set up your account. To get started, could you please provide me with your email address that you'd like to use for the account?",
      direction: ChatMessageDirection.incoming,
      timestampLabel: '11:40 AM',
    ),
  ];

  @override
  Future<List<InboxThread>> fetchThreads() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return List<InboxThread>.from(_threads);
  }

  @override
  Future<List<ChatMessage>> fetchMessages(String threadId) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return List<ChatMessage>.from(_conversation);
  }
}
