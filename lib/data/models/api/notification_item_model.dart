import '../base_model.dart';

class NotificationItemModel extends BaseModel {
  const NotificationItemModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
    required this.timeAgo,
  });

  final int id;
  final String type;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;
  final String timeAgo;

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    return NotificationItemModel(
      id: json['id'] as int,
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      read: json['read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      timeAgo: json['time_ago'] as String? ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'body': body,
        'read': read,
        'created_at': createdAt.toIso8601String(),
        'time_ago': timeAgo,
      };

  @override
  List<Object?> get props =>
      [id, type, title, body, read, createdAt, timeAgo];
}
