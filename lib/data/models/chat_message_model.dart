import 'base_model.dart';

enum ChatMessageDirection { incoming, outgoing }

enum ChatMessageSendStatus { sent, sending, failed }

class ChatMessage extends BaseModel {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.direction,
    this.timestampLabel,
    this.isNumberedList = false,
    this.sendStatus = ChatMessageSendStatus.sent,
  });

  final String id;
  final String text;
  final ChatMessageDirection direction;
  final String? timestampLabel;
  final bool isNumberedList;
  final ChatMessageSendStatus sendStatus;

  ChatMessage copyWith({
    String? id,
    String? text,
    ChatMessageDirection? direction,
    String? timestampLabel,
    bool? isNumberedList,
    ChatMessageSendStatus? sendStatus,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      direction: direction ?? this.direction,
      timestampLabel: timestampLabel ?? this.timestampLabel,
      isNumberedList: isNumberedList ?? this.isNumberedList,
      sendStatus: sendStatus ?? this.sendStatus,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'direction': direction.name,
        'timestampLabel': timestampLabel,
        'isNumberedList': isNumberedList,
        'sendStatus': sendStatus.name,
      };

  @override
  List<Object?> get props =>
      [id, text, direction, timestampLabel, isNumberedList, sendStatus];
}
