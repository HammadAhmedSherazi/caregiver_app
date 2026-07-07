import '../base_model.dart';

class CallResultModel extends BaseModel {
  const CallResultModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.mode,
    required this.status,
    this.tel,
    this.message,
  });

  final int id;
  final int clientId;
  final String clientName;
  final String mode;
  final String status;
  final String? tel;
  final String? message;

  bool get isRingout => mode == 'ringout';

  factory CallResultModel.fromJson(
    Map<String, dynamic> json, {
    String? message,
  }) {
    return CallResultModel(
      id: json['id'] as int? ?? 0,
      clientId: json['client_id'] as int? ?? 0,
      clientName: json['client_name'] as String? ?? '',
      mode: json['mode'] as String? ?? 'manual',
      status: json['status'] as String? ?? '',
      tel: json['tel'] as String?,
      message: message,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'client_id': clientId,
        'client_name': clientName,
        'mode': mode,
        'status': status,
        if (tel != null) 'tel': tel,
        if (message != null) 'message': message,
      };

  @override
  List<Object?> get props =>
      [id, clientId, clientName, mode, status, tel, message];
}
