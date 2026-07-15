import 'package:equatable/equatable.dart';

import '../../../data/models/chat_message_model.dart';

enum ChatStatus { initial, loading, success, failure }

class ChatState extends Equatable {
  const ChatState({
    this.status = ChatStatus.initial,
    this.messages = const [],
  });

  final ChatStatus status;
  final List<ChatMessage> messages;

  bool get isLoading => status == ChatStatus.loading;
  bool get hasError => status == ChatStatus.failure;

  ChatState copyWith({
    ChatStatus? status,
    List<ChatMessage>? messages,
  }) {
    return ChatState(
      status: status ?? this.status,
      messages: messages ?? this.messages,
    );
  }

  @override
  List<Object?> get props => [status, messages];
}
