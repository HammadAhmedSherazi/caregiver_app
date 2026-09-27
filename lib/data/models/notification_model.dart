import 'api/velora/common_models.dart';
import 'base_model.dart';

enum NotificationKind { schedule, compliance, message }

class AppNotification extends BaseModel {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestampLabel,
    required this.kind,
    this.isRead = false,
    this.category,
    this.action,
  });

  final String id;
  final String title;
  final String body;
  final String timestampLabel;
  final NotificationKind kind;
  final bool isRead;

  /// VELORA `category` (`time`, `documents`, `pay`, …). 🚧 Planned — null today.
  final String? category;

  /// VELORA deep link. 🚧 Planned — null today; when present it wins over [kind].
  final AppActionModel? action;

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      timestampLabel: timestampLabel,
      kind: kind,
      isRead: isRead ?? this.isRead,
      category: category,
      action: action,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'timestampLabel': timestampLabel,
        'kind': kind.name,
        'isRead': isRead,
      };

  @override
  List<Object?> get props =>
      [id, title, body, timestampLabel, kind, isRead, category, action];
}
