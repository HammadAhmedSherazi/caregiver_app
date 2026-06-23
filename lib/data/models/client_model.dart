import 'base_model.dart';

class ClientContact extends BaseModel {
  const ClientContact({
    required this.label,
    required this.phone,
  });

  final String label;
  final String phone;

  @override
  Map<String, dynamic> toJson() => {
        'label': label,
        'phone': phone,
      };

  @override
  List<Object?> get props => [label, phone];
}

class ClientModel extends BaseModel {
  const ClientModel({
    required this.id,
    required this.name,
    required this.listSubtitle,
    required this.scheduleBadge,
    required this.address,
    required this.clientPhone,
    required this.emergencyContact,
    required this.dailyCarePlan,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String listSubtitle;
  final String scheduleBadge;
  final String address;
  final String clientPhone;
  final ClientContact emergencyContact;
  final List<String> dailyCarePlan;
  final String? avatarUrl;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'listSubtitle': listSubtitle,
        'scheduleBadge': scheduleBadge,
        'address': address,
        'clientPhone': clientPhone,
        'emergencyContact': emergencyContact.toJson(),
        'dailyCarePlan': dailyCarePlan,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      };

  @override
  List<Object?> get props => [
        id,
        name,
        listSubtitle,
        scheduleBadge,
        address,
        clientPhone,
        emergencyContact,
        dailyCarePlan,
        avatarUrl,
      ];
}
