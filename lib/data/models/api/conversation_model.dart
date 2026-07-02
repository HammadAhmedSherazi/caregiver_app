import '../base_model.dart';

class ConversationCounterpartModel extends BaseModel {
  const ConversationCounterpartModel({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  final int id;
  final String name;
  final String? avatarUrl;

  factory ConversationCounterpartModel.fromJson(Map<String, dynamic> json) {
    return ConversationCounterpartModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      };

  @override
  List<Object?> get props => [id, name, avatarUrl];
}

class ConversationSummaryModel extends BaseModel {
  const ConversationSummaryModel({
    required this.id,
    required this.subject,
    required this.counterpart,
    required this.lastMessage,
    required this.lastSender,
    required this.unread,
    required this.lastMessageAt,
    required this.timeAgo,
  });

  final int id;
  final String subject;
  final ConversationCounterpartModel counterpart;
  final String lastMessage;
  final String lastSender;
  final bool unread;
  final DateTime lastMessageAt;
  final String timeAgo;

  factory ConversationSummaryModel.fromJson(Map<String, dynamic> json) {
    return ConversationSummaryModel(
      id: json['id'] as int,
      subject: json['subject'] as String? ?? '',
      counterpart: ConversationCounterpartModel.fromJson(
        json['counterpart'] as Map<String, dynamic>? ?? const {},
      ),
      lastMessage: json['last_message'] as String? ?? '',
      lastSender: json['last_sender'] as String? ?? '',
      unread: json['unread'] as bool? ?? false,
      lastMessageAt: DateTime.parse(json['last_message_at'] as String),
      timeAgo: json['time_ago'] as String? ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'counterpart': counterpart.toJson(),
        'last_message': lastMessage,
        'last_sender': lastSender,
        'unread': unread,
        'last_message_at': lastMessageAt.toIso8601String(),
        'time_ago': timeAgo,
      };

  @override
  List<Object?> get props => [
        id,
        subject,
        counterpart,
        lastMessage,
        lastSender,
        unread,
        lastMessageAt,
        timeAgo,
      ];
}

class ConversationMessageModel extends BaseModel {
  const ConversationMessageModel({
    required this.id,
    required this.body,
    required this.senderId,
    required this.senderName,
    this.avatarUrl,
    required this.isMine,
    required this.createdAt,
    required this.time,
    required this.timeAgo,
  });

  final int id;
  final String body;
  final int senderId;
  final String senderName;
  final String? avatarUrl;
  final bool isMine;
  final DateTime createdAt;
  final String time;
  final String timeAgo;

  factory ConversationMessageModel.fromJson(Map<String, dynamic> json) {
    return ConversationMessageModel(
      id: json['id'] as int,
      body: json['body'] as String? ?? '',
      senderId: json['sender_id'] as int? ?? 0,
      senderName: json['sender_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      isMine: json['is_mine'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      time: json['time'] as String? ?? '',
      timeAgo: json['time_ago'] as String? ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'body': body,
        'sender_id': senderId,
        'sender_name': senderName,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        'is_mine': isMine,
        'created_at': createdAt.toIso8601String(),
        'time': time,
        'time_ago': timeAgo,
      };

  @override
  List<Object?> get props => [
        id,
        body,
        senderId,
        senderName,
        avatarUrl,
        isMine,
        createdAt,
        time,
        timeAgo,
      ];
}

class ConversationDetailModel extends BaseModel {
  const ConversationDetailModel({
    required this.id,
    required this.subject,
    required this.messages,
  });

  final int id;
  final String subject;
  final List<ConversationMessageModel> messages;

  factory ConversationDetailModel.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'] as List<dynamic>? ?? const [];
    return ConversationDetailModel(
      id: json['id'] as int,
      subject: json['subject'] as String? ?? '',
      messages: rawMessages
          .whereType<Map<String, dynamic>>()
          .map(ConversationMessageModel.fromJson)
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'messages': messages.map((message) => message.toJson()).toList(),
      };

  @override
  List<Object?> get props => [id, subject, messages];
}
