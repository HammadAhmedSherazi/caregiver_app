import '../base_model.dart';

class VisitLocationModel extends BaseModel {
  const VisitLocationModel({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  factory VisitLocationModel.fromJson(Map<String, dynamic> json) {
    return VisitLocationModel(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
      };

  @override
  List<Object?> get props => [latitude, longitude];
}

class VisitModel extends BaseModel {
  const VisitModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.status,
    required this.clockInAt,
    this.clockOutAt,
    this.totalHours,
    this.clockInLocation,
    this.evvVerified,
  });

  final int id;
  final int clientId;
  final String clientName;
  final String status;
  final DateTime clockInAt;
  final DateTime? clockOutAt;
  final double? totalHours;
  final VisitLocationModel? clockInLocation;
  final bool? evvVerified;

  bool get isActive {
    if (clockOutAt != null) return false;

    final normalized = status.trim().toLowerCase();
    return normalized == 'clocked in' ||
        normalized == 'clocked_in' ||
        normalized == 'in progress' ||
        normalized == 'in_progress' ||
        normalized == 'active';
  }

  factory VisitModel.fromJson(Map<String, dynamic> json) {
    return VisitModel(
      id: json['id'] as int,
      clientId: json['client_id'] as int,
      clientName: json['client_name'] as String? ?? '',
      status: json['status'] as String? ?? '',
      clockInAt: DateTime.parse(json['clock_in_at'] as String),
      clockOutAt: json['clock_out_at'] != null
          ? DateTime.parse(json['clock_out_at'] as String)
          : null,
      totalHours: (json['total_hours'] as num?)?.toDouble(),
      clockInLocation: json['clock_in_location'] is Map<String, dynamic>
          ? VisitLocationModel.fromJson(
              json['clock_in_location'] as Map<String, dynamic>,
            )
          : null,
      evvVerified: json['evv_verified'] as bool?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'client_id': clientId,
        'client_name': clientName,
        'status': status,
        'clock_in_at': clockInAt.toIso8601String(),
        if (clockOutAt != null) 'clock_out_at': clockOutAt!.toIso8601String(),
        if (totalHours != null) 'total_hours': totalHours,
        if (clockInLocation != null)
          'clock_in_location': clockInLocation!.toJson(),
        if (evvVerified != null) 'evv_verified': evvVerified,
      };

  @override
  List<Object?> get props => [
        id,
        clientId,
        clientName,
        status,
        clockInAt,
        clockOutAt,
        totalHours,
        clockInLocation,
        evvVerified,
      ];
}
