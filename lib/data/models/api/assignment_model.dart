import '../base_model.dart';

class AssignmentAuthorizationModel extends BaseModel {
  const AssignmentAuthorizationModel({
    required this.label,
    required this.tone,
    required this.days,
  });

  final String label;
  final String tone;
  final int days;

  factory AssignmentAuthorizationModel.fromJson(Map<String, dynamic> json) {
    return AssignmentAuthorizationModel(
      label: json['label'] as String? ?? '',
      tone: json['tone'] as String? ?? '',
      days: json['days'] as int? ?? 0,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'label': label,
        'tone': tone,
        'days': days,
      };

  @override
  List<Object?> get props => [label, tone, days];
}

class AssignmentModel extends BaseModel {
  const AssignmentModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.county,
    required this.program,
    required this.authorization,
  });

  final int id;
  final String name;
  final String phone;
  final String address;
  final String county;
  final String program;
  final AssignmentAuthorizationModel authorization;

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    return AssignmentModel(
      id: json['id'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      county: json['county'] as String? ?? '',
      program: json['program'] as String? ?? '',
      authorization: AssignmentAuthorizationModel.fromJson(
        json['authorization'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'address': address,
        'county': county,
        'program': program,
        'authorization': authorization.toJson(),
      };

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        address,
        county,
        program,
        authorization,
      ];
}
