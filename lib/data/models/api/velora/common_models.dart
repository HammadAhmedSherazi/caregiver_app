import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import 'json.dart';

/// Screen keys used by `action` deep links and push payloads (§0).
enum AppScreen {
  home('home'),
  time('time'),
  fixClockout('fix_clockout'),
  report('report'),
  checkIn('check_in'),
  pay('pay'),
  paystub('paystub'),
  docs('docs'),
  upload('upload'),
  inbox('inbox'),
  profile('profile');

  const AppScreen(this.key);

  final String key;

  static AppScreen? fromKey(String? key) {
    for (final s in values) {
      if (s.key == key) return s;
    }
    return null;
  }
}

/// `{ "screen": "<key>", "params": { … } }` — used by dashboard items,
/// notifications and pushes. Unknown screen keys parse to `null` screen so
/// newer server keys never crash older apps.
class AppActionModel extends Equatable {
  const AppActionModel({required this.screenKey, this.params = const {}});

  final String screenKey;
  final Map<String, dynamic> params;

  AppScreen? get screen => AppScreen.fromKey(screenKey);

  static AppActionModel? maybeFromJson(Object? raw) {
    final json = jsonMap(raw);
    final key = str(json?['screen']);
    if (json == null || key == null || key.isEmpty) return null;
    return AppActionModel(screenKey: key, params: jsonMap(json['params']) ?? const {});
  }

  /// Push `data` is flat: `{ "screen": "...", "visit_id": "123", … }`.
  static AppActionModel? fromPushData(Map<String, dynamic> data) {
    final key = str(data['screen']);
    if (key == null || key.isEmpty) return null;
    return AppActionModel(
      screenKey: key,
      params: Map<String, dynamic>.from(data)..remove('screen'),
    );
  }

  int? intParam(String name) => intOrNull(params[name]);
  String? stringParam(String name) => str(params[name]);

  Map<String, dynamic> toJson() => {'screen': screenKey, 'params': params};

  @override
  List<Object?> get props => [screenKey, params];
}

/// `{ "bank": "Chase", "last4": "4821", "label": "Chase ••4821" }`.
/// `bank` may be null — Open decision D4.
class DepositModel extends Equatable {
  const DepositModel({this.bank, this.last4, this.label});

  final String? bank;
  final String? last4;
  final String? label;

  static DepositModel? maybeFromJson(Object? raw) {
    final j = jsonMap(raw);
    if (j == null) return null;
    return DepositModel(bank: str(j['bank']), last4: str(j['last4']), label: str(j['label']));
  }

  @override
  List<Object?> get props => [bank, last4, label];
}

/// Work plan — "any N days" or set days. Source is Open decision D7.
class WorkPlanModel extends Equatable {
  const WorkPlanModel({
    required this.type,
    this.daysPerWeek,
    this.setDays = const [],
    this.label,
  });

  /// `any_days` | `set_days`.
  final String type;
  final int? daysPerWeek;
  final List<String> setDays;
  final String? label;

  bool get isSetDays => type == 'set_days';

  static WorkPlanModel? maybeFromJson(Object? raw) {
    final j = jsonMap(raw);
    if (j == null) return null;
    return WorkPlanModel(
      type: strOr(j['type'], 'any_days'),
      daysPerWeek: intOrNull(j['days_per_week']),
      setDays: stringList(j['set_days']),
      label: str(j['label']),
    );
  }

  @override
  List<Object?> get props => [type, daysPerWeek, setDays, label];
}

/// The caregiver's client (§0 "One client" — Open decision D1).
class ClientSummaryModel extends Equatable {
  const ClientSummaryModel({
    required this.id,
    required this.name,
    this.initials,
    this.address,
    this.plan,
    this.planLabel,
    this.location,
  });

  final int id;
  final String name;
  final String? initials;
  final String? address;
  final WorkPlanModel? plan;
  final String? planLabel;

  /// Home coordinates (`/dashboard` only). Used on the device only — nothing
  /// is tracked in the background and no location is sent.
  final ClientLocationModel? location;

  static ClientSummaryModel? maybeFromJson(Object? raw) {
    final j = jsonMap(raw);
    final id = intOrNull(j?['id']);
    if (j == null || id == null) return null;
    return ClientSummaryModel(
      id: id,
      name: strOr(j['name']),
      initials: str(j['initials']),
      address: str(j['address']),
      plan: WorkPlanModel.maybeFromJson(j['plan']),
      planLabel: str(j['plan_label']),
      location: ClientLocationModel.maybeFromJson(j['location']),
    );
  }

  @override
  List<Object?> get props => [id, name, initials, address, plan, planLabel, location];
}

/// `client.location` in `GET /dashboard` — powers "You're at Robert's home ·
/// within 40 ft" and the device-only geofence reminder.
class ClientLocationModel extends Equatable {
  const ClientLocationModel({
    required this.latitude,
    required this.longitude,
    required this.radiusFeet,
  });

  final double latitude;
  final double longitude;
  final int radiusFeet;

  static ClientLocationModel? maybeFromJson(Object? raw) {
    final j = jsonMap(raw);
    final lat = dblOrNull(j?['latitude']);
    final lng = dblOrNull(j?['longitude']);
    if (j == null || lat == null || lng == null) return null;
    return ClientLocationModel(
      latitude: lat,
      longitude: lng,
      radiusFeet: intOrNull(j['radius_feet']) ?? 300,
    );
  }

  /// Great-circle distance in feet from ([lat], [lng]).
  double distanceFeetFrom(double lat, double lng) {
    const earthRadiusFeet = 20902231.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(lat - latitude);
    final dLng = rad(lng - longitude);
    final a = math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(latitude)) * math.cos(rad(lat)) * math.pow(math.sin(dLng / 2), 2);
    return 2 * earthRadiusFeet * math.asin(math.sqrt(a));
  }

  bool isWithin(double lat, double lng) => distanceFeetFrom(lat, lng) <= radiusFeet;

  @override
  List<Object?> get props => [latitude, longitude, radiusFeet];
}

/// Hospital answer shared by clock-out, check-in and their responses.
class HospitalStayModel extends Equatable {
  const HospitalStayModel({
    required this.wasInHospital,
    this.from,
    this.to,
    this.stillInHospital = false,
    this.daysRemoved,
    this.summaryLine,
  });

  const HospitalStayModel.none() : this(wasInHospital: false);

  final bool wasInHospital;
  final DateTime? from;
  final DateTime? to;
  final bool stillInHospital;

  /// Response only (`POST /visits/clock-out`).
  final int? daysRemoved;

  /// Response only: "Sep 24 – 26 · 3 days removed".
  final String? summaryLine;

  static HospitalStayModel? maybeFromJson(Object? raw) {
    final j = jsonMap(raw);
    if (j == null) return null;
    return HospitalStayModel(
      wasInHospital: boolOrNull(j['was_in_hospital']) ?? false,
      from: dateOrNull(j['from']),
      to: dateOrNull(j['to']),
      stillInHospital: boolOrNull(j['still_in_hospital']) ?? false,
      daysRemoved: intOrNull(j['days_removed']),
      summaryLine: str(j['summary_line']),
    );
  }

  /// Contract rules: `from`/`to` required when in hospital; `to` may be null
  /// only when still in hospital; `to` ≥ `from`.
  Map<String, List<String>> validate([String prefix = 'hospital']) {
    if (!wasInHospital) return const {};
    final errors = <String, List<String>>{};
    if (from == null) errors['$prefix.from'] = ['Choose the date they were admitted.'];
    if (to == null && !stillInHospital) {
      errors['$prefix.to'] = ['Choose the date they came home.'];
    }
    if (from != null && to != null && to!.isBefore(from!)) {
      errors['$prefix.to'] = ['The "came home" date needs to be on or after the admitted date.'];
    }
    return errors;
  }

  Map<String, dynamic> toJson() => {
        'was_in_hospital': wasInHospital,
        'from': wasInHospital && from != null ? formatDate(from!) : null,
        'to': wasInHospital && to != null ? formatDate(to!) : null,
        'still_in_hospital': wasInHospital && stillInHospital,
      };

  @override
  List<Object?> get props => [wasInHospital, from, to, stillInHospital, daysRemoved, summaryLine];
}

/// Label + route shared by several screens.
class LabeledActionModel extends Equatable {
  const LabeledActionModel({this.key, required this.label, this.action});

  final String? key;
  final String label;
  final AppActionModel? action;

  static LabeledActionModel? maybeFromJson(Object? raw) {
    final j = jsonMap(raw);
    if (j == null) return null;
    return LabeledActionModel(
      key: str(j['key']),
      label: strOr(j['label']),
      action: AppActionModel.maybeFromJson(j['action']),
    );
  }

  @override
  List<Object?> get props => [key, label, action];
}
