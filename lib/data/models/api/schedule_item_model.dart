import '../base_model.dart';

class ScheduleItemModel extends BaseModel {
  const ScheduleItemModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.title,
    required this.status,
    required this.date,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.address,
  });

  final int id;
  final int clientId;
  final String clientName;
  final String title;
  final String status;
  final String date;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final String address;

  factory ScheduleItemModel.fromJson(Map<String, dynamic> json) {
    return ScheduleItemModel(
      id: json['id'] as int,
      clientId: json['client_id'] as int,
      clientName: json['client_name'] as String? ?? '',
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? '',
      date: json['date'] as String? ?? '',
      scheduledStart: DateTime.parse(json['scheduled_start'] as String),
      scheduledEnd: DateTime.parse(json['scheduled_end'] as String),
      address: json['address'] as String? ?? '',
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'client_id': clientId,
        'client_name': clientName,
        'title': title,
        'status': status,
        'date': date,
        'scheduled_start': scheduledStart.toIso8601String(),
        'scheduled_end': scheduledEnd.toIso8601String(),
        'address': address,
      };

  @override
  List<Object?> get props => [
        id,
        clientId,
        clientName,
        title,
        status,
        date,
        scheduledStart,
        scheduledEnd,
        address,
      ];
}
