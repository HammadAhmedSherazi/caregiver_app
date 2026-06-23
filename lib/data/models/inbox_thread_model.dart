import 'base_model.dart';

class InboxThread extends BaseModel {
  const InboxThread({
    required this.id,
    required this.contactName,
    required this.preview,
    required this.timestampLabel,
    this.avatarUrl,
  });

  final String id;
  final String contactName;
  final String preview;
  final String timestampLabel;
  final String? avatarUrl;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'contactName': contactName,
        'preview': preview,
        'timestampLabel': timestampLabel,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      };

  @override
  List<Object?> get props =>
      [id, contactName, preview, timestampLabel, avatarUrl];
}
