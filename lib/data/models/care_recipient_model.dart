import 'base_model.dart';

class CareRecipientModel extends BaseModel {
  const CareRecipientModel({
    required this.id,
    required this.name,
    required this.careType,
    required this.nextVisit,
  });

  factory CareRecipientModel.fromJson(Map<String, dynamic> json) {
    return CareRecipientModel(
      id: json['id'] as int,
      name: json['name'] as String,
      careType: json['careType'] as String,
      nextVisit: json['nextVisit'] as String,
    );
  }

  final int id;
  final String name;
  final String careType;
  final String nextVisit;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'careType': careType,
        'nextVisit': nextVisit,
      };

  @override
  List<Object?> get props => [id, name, careType, nextVisit];
}
