import 'package:equatable/equatable.dart';

import 'json.dart';

/// `GET /inbox/office-thread` 🚧 PLANNED — NOT LIVE. Messages keep using the
/// existing `/conversations/{thread_id}` endpoints and sockets.
class OfficeThreadModel extends Equatable {
  const OfficeThreadModel({
    required this.threadId,
    required this.officeName,
    this.officePhone,
    this.officePhoneLabel,
    this.officeHoursLabel,
  });

  final int threadId;
  final String officeName;

  /// For "Call the office" (`tel:`).
  final String? officePhone;
  final String? officePhoneLabel;

  /// "Mon – Fri, 9 AM – 5 PM".
  final String? officeHoursLabel;

  factory OfficeThreadModel.fromJson(Json json) {
    final d = jsonMap(json['data']) ?? json;
    return OfficeThreadModel(
      threadId: intOrNull(d['thread_id']) ?? 0,
      officeName: strOr(d['office_name']),
      officePhone: str(d['office_phone']),
      officePhoneLabel: str(d['office_phone_label']),
      officeHoursLabel: str(d['office_hours_label']),
    );
  }

  @override
  List<Object?> get props => [threadId, officeName, officePhone, officePhoneLabel, officeHoursLabel];
}
