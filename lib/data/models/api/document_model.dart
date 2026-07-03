import '../base_model.dart';

class DocumentModel extends BaseModel {
  const DocumentModel({
    required this.id,
    required this.name,
    required this.type,
    required this.category,
    required this.isSigned,
    required this.mimeType,
    required this.fileSize,
    required this.verificationStatus,
    this.attachedTo,
    this.clientId,
    this.url,
    this.uploadedAt,
  });

  final int id;
  final String name;
  final String type;
  final String category;
  final bool isSigned;
  final String mimeType;
  final int fileSize;
  final String verificationStatus;
  final String? attachedTo;
  final int? clientId;
  final String? url;
  final DateTime? uploadedAt;

  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      category: json['category'] as String? ?? '',
      isSigned: json['is_signed'] as bool? ?? false,
      mimeType: json['mime_type'] as String? ?? '',
      fileSize: json['file_size'] as int? ?? 0,
      verificationStatus: json['verification_status'] as String? ?? '',
      attachedTo: json['attached_to'] as String?,
      clientId: json['client_id'] as int?,
      url: json['url'] as String?,
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.tryParse(json['uploaded_at'] as String)
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'category': category,
        'is_signed': isSigned,
        'mime_type': mimeType,
        'file_size': fileSize,
        'verification_status': verificationStatus,
        'attached_to': attachedTo,
        'client_id': clientId,
        'url': url,
        'uploaded_at': uploadedAt?.toIso8601String(),
      };

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        category,
        isSigned,
        mimeType,
        fileSize,
        verificationStatus,
        attachedTo,
        clientId,
        url,
        uploadedAt,
      ];
}
