import 'base_model.dart';

class InboxThread extends BaseModel {
  const InboxThread({
    required this.id,
    required this.contactName,
    required this.preview,
    required this.timestampLabel,
    this.avatarUrl,
    this.isUnread = false,
  });

  final String id;
  final String contactName;
  final String preview;
  final String timestampLabel;
  final String? avatarUrl;
  final bool isUnread;

  InboxThread copyWith({
    String? id,
    String? contactName,
    String? preview,
    String? timestampLabel,
    String? avatarUrl,
    bool? isUnread,
  }) {
    return InboxThread(
      id: id ?? this.id,
      contactName: contactName ?? this.contactName,
      preview: preview ?? this.preview,
      timestampLabel: timestampLabel ?? this.timestampLabel,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isUnread: isUnread ?? this.isUnread,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'contactName': contactName,
        'preview': preview,
        'timestampLabel': timestampLabel,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        'isUnread': isUnread,
      };

  @override
  List<Object?> get props =>
      [id, contactName, preview, timestampLabel, avatarUrl, isUnread];
}
