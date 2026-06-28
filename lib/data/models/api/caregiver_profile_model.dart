import '../base_model.dart';

class CaregiverProfileModel extends BaseModel {
  const CaregiverProfileModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.caregiverType,
    required this.liveIn,
    required this.hourlyWage,
    required this.status,
    this.payEligibilityStart,
  });

  final int id;
  final String name;
  final String email;
  final String phone;
  final String caregiverType;
  final bool liveIn;
  final double hourlyWage;
  final String status;
  final String? payEligibilityStart;

  factory CaregiverProfileModel.fromJson(Map<String, dynamic> json) {
    return CaregiverProfileModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String? ?? '',
      caregiverType: json['caregiver_type'] as String? ?? '',
      liveIn: json['live_in'] as bool? ?? false,
      hourlyWage: (json['hourly_wage'] as num?)?.toDouble() ?? 0,
      status: json['status'] as String? ?? '',
      payEligibilityStart: json['pay_eligibility_start'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'caregiver_type': caregiverType,
        'live_in': liveIn,
        'hourly_wage': hourlyWage,
        'status': status,
        if (payEligibilityStart != null)
          'pay_eligibility_start': payEligibilityStart,
      };

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        caregiverType,
        liveIn,
        hourlyWage,
        status,
        payEligibilityStart,
      ];
}
