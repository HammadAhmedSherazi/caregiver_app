import 'package:equatable/equatable.dart';

import '../../../../core/network/api_exception.dart';
import 'common_models.dart';
import 'json.dart';

class PendingCorrectionModel extends Equatable {
  const PendingCorrectionModel({this.proposedClockOutAt, required this.status});

  final DateTime? proposedClockOutAt;

  /// `pending_review`, …
  final String status;

  static PendingCorrectionModel? maybeFromJson(Object? raw) {
    final j = jsonMap(raw);
    if (j == null) return null;
    return PendingCorrectionModel(
      proposedClockOutAt: dateOrNull(j['proposed_clock_out_at']),
      status: strOr(j['status']),
    );
  }

  @override
  List<Object?> get props => [proposedClockOutAt, status];
}

/// `GET /visits/{schedule}` 🚧 PLANNED — NOT LIVE.
class VisitDetailModel extends Equatable {
  const VisitDetailModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.status,
    this.date,
    this.dateLabel,
    this.clockInAt,
    this.clockInPlaceLabel,
    this.clockOutAt,
    required this.missingClockout,
    this.pendingCorrection,
  });

  final int id;
  final int clientId;
  final String clientName;
  final String status;
  final DateTime? date;
  final String? dateLabel;
  final DateTime? clockInAt;
  final String? clockInPlaceLabel;
  final DateTime? clockOutAt;
  final bool missingClockout;
  final PendingCorrectionModel? pendingCorrection;

  factory VisitDetailModel.fromJson(Json json) {
    final d = jsonMap(json['data']) ?? json;
    return VisitDetailModel(
      id: intOrNull(d['id']) ?? 0,
      clientId: intOrNull(d['client_id']) ?? 0,
      clientName: strOr(d['client_name']),
      status: strOr(d['status']),
      date: dateOrNull(d['date']),
      dateLabel: str(d['date_label']),
      clockInAt: dateOrNull(d['clock_in_at']),
      clockInPlaceLabel: str(d['clock_in_place_label']),
      clockOutAt: dateOrNull(d['clock_out_at']),
      missingClockout: boolOrNull(d['missing_clockout']) ?? false,
      pendingCorrection: PendingCorrectionModel.maybeFromJson(d['pending_correction']),
    );
  }

  @override
  List<Object?> get props => [
        id, clientId, clientName, status, date, dateLabel, clockInAt,
        clockInPlaceLabel, clockOutAt, missingClockout, pendingCorrection,
      ];
}

enum FixClockoutReason {
  forgotToTapOut('forgot_to_tap_out'),
  phoneDied('phone_died'),
  appProblem('app_problem'),
  somethingElse('something_else');

  const FixClockoutReason(this.value);

  final String value;
}

/// Body of `POST /visits/{schedule}/fix-clockout`.
class FixClockoutRequest extends Equatable {
  const FixClockoutRequest({
    required this.leftAt,
    required this.reason,
    this.note,
    this.clockInAt,
  });

  final DateTime leftAt;
  final FixClockoutReason reason;
  final String? note;

  /// Used only for the client-side check; not sent.
  final DateTime? clockInAt;

  /// Contract: `left_at` after the clock-in and within 24 h of it.
  void validate() {
    final start = clockInAt;
    if (start == null) return;
    if (!leftAt.isAfter(start)) {
      throw RequestValidationException({
        'left_at': ['The time you left must be after you clocked in.'],
      });
    }
    if (leftAt.difference(start) > const Duration(hours: 24)) {
      throw RequestValidationException({
        'left_at': ['The time you left must be within 24 hours of clocking in.'],
      });
    }
  }

  Map<String, dynamic> toJson() => {
        'left_at': formatTimestamp(leftAt),
        'reason': reason.value,
        if (note != null && note!.trim().isNotEmpty) 'note': note!.trim(),
      };

  @override
  List<Object?> get props => [leftAt, reason, note, clockInAt];
}

/// Response of `POST /visits/{schedule}/fix-clockout` (201).
class FixClockoutResultModel extends Equatable {
  const FixClockoutResultModel({
    required this.message,
    required this.visitId,
    required this.status,
    this.proposedClockOutAt,
    this.proposedHours,
    this.hoursLabel,
    this.reviewEta,
  });

  final String message;
  final int visitId;
  final String status;
  final DateTime? proposedClockOutAt;
  final double? proposedHours;
  final String? hoursLabel;
  final String? reviewEta;

  factory FixClockoutResultModel.fromJson(Json json) {
    final d = jsonMap(json['data']) ?? const {};
    return FixClockoutResultModel(
      message: strOr(json['message']),
      visitId: intOrNull(d['visit_id']) ?? 0,
      status: strOr(d['status']),
      proposedClockOutAt: dateOrNull(d['proposed_clock_out_at']),
      proposedHours: dblOrNull(d['proposed_hours']),
      hoursLabel: str(d['hours_label']),
      reviewEta: str(d['review_eta']),
    );
  }

  @override
  List<Object?> get props =>
      [message, visitId, status, proposedClockOutAt, proposedHours, hoursLabel, reviewEta];
}

/// New optional fields of `POST /visits/clock-out` ("Before you go").
///
/// The new flow must send `hospital.was_in_hospital` and `care_not_given`;
/// old callers omit the whole object and the request is unchanged.
class ClockOutAnswers extends Equatable {
  const ClockOutAnswers({
    required this.hospital,
    required this.careNotGiven,
    this.services = const [],
  });

  final HospitalStayModel hospital;
  final bool careNotGiven;

  /// Ids from `GET /services/catalog` — any `groups[].items[].id` or
  /// `summary[].id` ([ServiceCatalogModel.isKnownId]).
  final List<String> services;

  void validate() {
    final errors = hospital.validate();
    if (errors.isNotEmpty) throw RequestValidationException(errors);
  }

  Map<String, dynamic> toJson() => {
        'hospital': hospital.toJson(),
        'care_not_given': careNotGiven,
        if (services.isNotEmpty) 'services': services.toSet().toList(),
      };

  @override
  List<Object?> get props => [hospital, careNotGiven, services];
}

/// Additive fields of the clock-out response (`hospital`, `summary`, …).
class ClockOutExtensionModel extends Equatable {
  const ClockOutExtensionModel({
    this.hospital,
    this.careNotGiven,
    this.services = const [],
    this.rangeLabel,
    this.hoursLabel,
    this.servicesLogged,
    this.sentToOffice,
    this.week,
  });

  /// Includes `days_removed` and `summary_line` ("Sep 24 – 26 · 3 days removed").
  final HospitalStayModel? hospital;
  final bool? careNotGiven;
  final List<String> services;
  final String? rangeLabel;
  final String? hoursLabel;
  final int? servicesLogged;
  final bool? sentToOffice;

  /// "This week · 4 of 5 days" on the done card.
  final WeekProgressModel? week;

  static ClockOutExtensionModel? maybeFromJson(Json json) {
    const keys = ['hospital', 'care_not_given', 'services', 'summary'];
    if (!keys.any(json.containsKey)) return null;
    final summary = jsonMap(json['summary']) ?? const {};
    return ClockOutExtensionModel(
      hospital: HospitalStayModel.maybeFromJson(json['hospital']),
      careNotGiven: boolOrNull(json['care_not_given']),
      services: stringList(json['services']),
      rangeLabel: str(summary['range_label']),
      hoursLabel: str(summary['hours_label']),
      servicesLogged: intOrNull(summary['services_logged']),
      sentToOffice: boolOrNull(summary['sent_to_office']),
      week: WeekProgressModel.maybeFromJson(summary['week']),
    );
  }

  @override
  List<Object?> get props => [
        hospital, careNotGiven, services, rangeLabel, hoursLabel,
        servicesLogged, sentToOffice, week,
      ];
}

/// `summary.week` of the clock-out response.
class WeekProgressModel extends Equatable {
  const WeekProgressModel({required this.done, required this.of, this.label});

  final int done;
  final int of;

  /// "4 of 5 days".
  final String? label;

  static WeekProgressModel? maybeFromJson(Object? raw) {
    final j = jsonMap(raw);
    if (j == null) return null;
    return WeekProgressModel(
      done: intOrNull(j['done']) ?? 0,
      of: intOrNull(j['of']) ?? 0,
      label: str(j['label']),
    );
  }

  @override
  List<Object?> get props => [done, of, label];
}

/// `location_match` of the clock-in response. A mismatch never blocks
/// clock-in; it only flags the visit for the office.
class LocationMatchModel extends Equatable {
  const LocationMatchModel({this.matched, this.distanceFeet, this.label});

  /// `null` (not `false`) when home coordinates or the phone's GPS are
  /// unavailable.
  final bool? matched;
  final int? distanceFeet;

  /// "Location matched".
  final String? label;

  static LocationMatchModel? maybeFromJson(Object? raw) {
    final j = jsonMap(raw);
    if (j == null) return null;
    return LocationMatchModel(
      matched: boolOrNull(j['matched']),
      distanceFeet: intOrNull(j['distance_feet']),
      label: str(j['label']),
    );
  }

  @override
  List<Object?> get props => [matched, distanceFeet, label];
}

class ServiceItemModel extends Equatable {
  const ServiceItemModel({required this.id, required this.label});

  final String id;
  final String label;

  static ServiceItemModel? maybeFromJson(Json j) {
    final id = str(j['id']);
    if (id == null || id.isEmpty) return null;
    return ServiceItemModel(id: id, label: strOr(j['label'], id));
  }

  @override
  List<Object?> get props => [id, label];
}

/// Full-screen Clock layout: 11 items in 3 groups.
class ServiceGroupModel extends Equatable {
  const ServiceGroupModel({required this.key, required this.name, this.items = const []});

  final String key;
  final String name;
  final List<ServiceItemModel> items;

  factory ServiceGroupModel.fromJson(Json j) => ServiceGroupModel(
        key: strOr(j['key']),
        name: strOr(j['name']),
        items: jsonList(j['items']).map(ServiceItemModel.maybeFromJson).whereType<ServiceItemModel>().toList(),
      );

  @override
  List<Object?> get props => [key, name, items];
}

/// Home sheet layout: 6 quick picks, each covering one or more items.
class ServiceSummaryModel extends Equatable {
  const ServiceSummaryModel({required this.id, required this.label, this.covers = const []});

  final String id;
  final String label;
  final List<String> covers;

  static ServiceSummaryModel? maybeFromJson(Json j) {
    final item = ServiceItemModel.maybeFromJson(j);
    if (item == null) return null;
    return ServiceSummaryModel(id: item.id, label: item.label, covers: stringList(j['covers']));
  }

  @override
  List<Object?> get props => [id, label, covers];
}

/// `GET /services/catalog` 🚧 PLANNED — NOT LIVE. Labels follow
/// `Accept-Language`. Which layout ships is open decision D9.
class ServiceCatalogModel extends Equatable {
  const ServiceCatalogModel({this.groups = const [], this.summary = const []});

  final List<ServiceGroupModel> groups;
  final List<ServiceSummaryModel> summary;

  factory ServiceCatalogModel.fromJson(Json json) {
    final d = jsonMap(json['data']) ?? json;
    return ServiceCatalogModel(
      groups: jsonList(d['groups']).map(ServiceGroupModel.fromJson).toList(),
      summary: jsonList(d['summary']).map(ServiceSummaryModel.maybeFromJson).whereType<ServiceSummaryModel>().toList(),
    );
  }

  /// Clock-out accepts any group item id or summary id.
  bool isKnownId(String id) =>
      summary.any((s) => s.id == id) || groups.any((g) => g.items.any((i) => i.id == id));

  /// Label for a stored service id, in either layout.
  String? labelFor(String id) {
    for (final s in summary) {
      if (s.id == id) return s.label;
    }
    for (final g in groups) {
      for (final i in g.items) {
        if (i.id == id) return i.label;
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [groups, summary];
}
