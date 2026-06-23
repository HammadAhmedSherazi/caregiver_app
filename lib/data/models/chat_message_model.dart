import 'base_model.dart';

enum ChatMessageDirection { incoming, outgoing }

class ChatMessage extends BaseModel {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.direction,
    this.timestampLabel,
    this.isNumberedList = false,
  });

  final String id;
  final String text;
  final ChatMessageDirection direction;
  final String? timestampLabel;
  final bool isNumberedList;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'direction': direction.name,
        'timestampLabel': timestampLabel,
        'isNumberedList': isNumberedList,
      };

  @override
  List<Object?> get props => [id, text, direction, timestampLabel, isNumberedList];
}
