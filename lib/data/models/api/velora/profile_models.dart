import 'package:equatable/equatable.dart';

import '../../../../core/network/api_exception.dart';
import 'common_models.dart';
import 'json.dart';

class EmergencyContactModel extends Equatable {
  const EmergencyContactModel({required this.name, required this.phone});

  final String name;
  final String phone;

  static EmergencyContactModel? maybeFromJson(Object? raw) {
    final j = jsonMap(raw);
    if (j == null) return null;
    return EmergencyContactModel(name: strOr(j['name']), phone: strOr(j['phone']));
  }

  Map<String, dynamic> toJson() => {'name': name, 'phone': phone};

  @override
  List<Object?> get props => [name, phone];
}

/// `settings` in `GET /me` and the body/response of `PUT /me/settings`.
class CaregiverSettingsModel extends Equatable {
  const CaregiverSettingsModel({
    this.language,
    this.reminders,
    this.faceIdEnabled,
  });

  /// `en` | `ar`.
  final String? language;
  final bool? reminders;
  final bool? faceIdEnabled;

  static CaregiverSettingsModel? maybeFromJson(Object? raw) {
    final j = jsonMap(raw);
    if (j == null) return null;
    return CaregiverSettingsModel(
      language: str(j['language']),
      reminders: boolOrNull(j['reminders']),
      faceIdEnabled: boolOrNull(j['face_id_enabled']),
    );
  }

  /// All optional — only the provided keys are sent.
  Map<String, dynamic> toJson() => {
        'language': ?language,
        'reminders': ?reminders,
        'face_id_enabled': ?faceIdEnabled,
      };

  void validate() {
    if (language != null && language != 'en' && language != 'ar') {
      throw RequestValidationException({
        'language': ['Language must be "en" or "ar".'],
      });
    }
    if (toJson().isEmpty) {
      throw RequestValidationException({
        'settings': ['Nothing to save.'],
      });
    }
  }

  @override
  List<Object?> get props => [language, reminders, faceIdEnabled];
}

/// `pending_changes[]` in `GET /me` — info changes waiting for the office.
class PendingChangeModel extends Equatable {
  const PendingChangeModel({
    required this.id,
    required this.fields,
    required this.status,
    this.createdAt,
    this.reviewEta,
  });

  final int id;
  final List<String> fields;

  /// `pending` until the office approves or rejects.
  final String status;
  final DateTime? createdAt;
  final String? reviewEta;

  bool get isPending => status == 'pending';

  static PendingChangeModel? maybeFromJson(Object? raw) {
    final j = jsonMap(raw);
    final id = intOrNull(j?['id']);
    if (j == null || id == null) return null;
    return PendingChangeModel(
      id: id,
      fields: stringList(j['fields']),
      status: strOr(j['status'], 'pending'),
      createdAt: dateOrNull(j['created_at']),
      reviewEta: str(j['review_eta']),
    );
  }

  @override
  List<Object?> get props => [id, fields, status, createdAt, reviewEta];
}

class OfficeContactModel extends Equatable {
  const OfficeContactModel({required this.name, this.phone, this.phoneLabel, this.hoursLabel});

  final String name;
  final String? phone;
  final String? phoneLabel;

  /// "Mon – Fri, 9 AM – 5 PM" (Help screen).
  final String? hoursLabel;

  static OfficeContactModel? maybeFromJson(Object? raw) {
    final j = jsonMap(raw);
    if (j == null) return null;
    return OfficeContactModel(
      name: strOr(j['name']),
      phone: str(j['phone']),
      phoneLabel: str(j['phone_label']),
      hoursLabel: str(j['hours_label']),
    );
  }

  @override
  List<Object?> get props => [name, phone, phoneLabel, hoursLabel];
}

/// `live_in_exemption` in `GET /me` — powers the live-in Clock screen. The
/// existing boolean `live_in` is unchanged.
class LiveInExemptionModel extends Equatable {
  const LiveInExemptionModel({required this.approved, this.approvedThrough});

  final bool approved;
  final DateTime? approvedThrough;

  static LiveInExemptionModel? maybeFromJson(Object? raw) {
    final j = jsonMap(raw);
    if (j == null) return null;
    return LiveInExemptionModel(
      approved: boolOrNull(j['approved']) ?? false,
      approvedThrough: dateOrNull(j['approved_through']),
    );
  }

  @override
  List<Object?> get props => [approved, approvedThrough];
}

/// New (additive) fields of `GET /me` (§10). `null` on today's live API.
class MeExtensionModel extends Equatable {
  const MeExtensionModel({
    this.client,
    this.deposit,
    this.emergencyContact,
    this.settings,
    this.pendingChanges = const [],
    this.office,
    this.liveInExemption,
  });

  final ClientSummaryModel? client;
  final DepositModel? deposit;
  final EmergencyContactModel? emergencyContact;
  final CaregiverSettingsModel? settings;
  final List<PendingChangeModel> pendingChanges;
  final OfficeContactModel? office;
  final LiveInExemptionModel? liveInExemption;

  static MeExtensionModel? maybeFromJson(Json json) {
    const keys = ['client', 'deposit', 'emergency_contact', 'settings', 'pending_changes', 'office',
      'live_in_exemption',
    ];
    if (!keys.any(json.containsKey)) return null;
    return MeExtensionModel(
      client: ClientSummaryModel.maybeFromJson(json['client']),
      deposit: DepositModel.maybeFromJson(json['deposit']),
      emergencyContact: EmergencyContactModel.maybeFromJson(json['emergency_contact']),
      settings: CaregiverSettingsModel.maybeFromJson(json['settings']),
      pendingChanges: jsonList(json['pending_changes'])
          .map(PendingChangeModel.maybeFromJson)
          .whereType<PendingChangeModel>()
          .toList(),
      office: OfficeContactModel.maybeFromJson(json['office']),
      liveInExemption: LiveInExemptionModel.maybeFromJson(json['live_in_exemption']),
    );
  }

  @override
  List<Object?> get props => [client, deposit, emergencyContact, settings, pendingChanges, office, liveInExemption];
}

/// Body of `POST /me/info-change` — at least one field. Bank changes are
/// **not** sent here (they go through `POST /documents`, `direct_deposit_form`).
class InfoChangeRequest extends Equatable {
  const InfoChangeRequest({this.mobile, this.email, this.address, this.emergencyContact});

  final String? mobile;
  final String? email;
  final String? address;
  final EmergencyContactModel? emergencyContact;

  Map<String, dynamic> toJson() {
    String? clean(String? v) => (v == null || v.trim().isEmpty) ? null : v.trim();
    return {
      'mobile': ?clean(mobile),
      'email': ?clean(email),
      'address': ?clean(address),
      if (emergencyContact != null &&
          (emergencyContact!.name.trim().isNotEmpty || emergencyContact!.phone.trim().isNotEmpty))
        'emergency_contact': emergencyContact!.toJson(),
    };
  }

  void validate() {
    if (toJson().isEmpty) {
      throw RequestValidationException({
        'info_change': ['Change at least one field before sending.'],
      });
    }
    final e = email?.trim();
    if (e != null && e.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e)) {
      throw RequestValidationException({
        'email': ['Enter a valid email address.'],
      });
    }
  }

  @override
  List<Object?> get props => [mobile, email, address, emergencyContact];
}

/// Response of `POST /me/info-change`: the request stays **pending** — the
/// live profile does not change until the office approves.
class InfoChangeResultModel extends Equatable {
  const InfoChangeResultModel({required this.message, required this.change});

  final String message;
  final PendingChangeModel change;

  static InfoChangeResultModel? maybeFromJson(Json json) {
    final change = PendingChangeModel.maybeFromJson(json['data']);
    if (change == null) return null;
    return InfoChangeResultModel(message: strOr(json['message']), change: change);
  }

  @override
  List<Object?> get props => [message, change];
}

/// Response of `POST /privacy/data-request` (201 new, 200 existing).
class PrivacyRequestResultModel extends Equatable {
  const PrivacyRequestResultModel({required this.message, required this.id, this.dueBy});

  final String message;
  final int id;
  final DateTime? dueBy;

  static PrivacyRequestResultModel? maybeFromJson(Json json) {
    final data = jsonMap(json['data']);
    final id = intOrNull(data?['id']);
    if (id == null) return null;
    return PrivacyRequestResultModel(
      message: strOr(json['message']),
      id: id,
      dueBy: dateOrNull(data?['due_by']),
    );
  }

  @override
  List<Object?> get props => [message, id, dueBy];
}

/// Body of `POST /devices` (§11).
class DeviceRegistrationRequest extends Equatable {
  const DeviceRegistrationRequest({
    required this.token,
    required this.platform,
    required this.appVersion,
    required this.language,
  });

  final String token;

  /// `ios` | `android`.
  final String platform;
  final String appVersion;
  final String language;

  void validate() {
    final errors = <String, List<String>>{};
    if (token.trim().isEmpty) errors['token'] = ['Missing push token.'];
    if (platform != 'ios' && platform != 'android') errors['platform'] = ['Unknown platform.'];
    if (errors.isNotEmpty) throw RequestValidationException(errors);
  }

  Map<String, dynamic> toJson() => {
        'token': token,
        'platform': platform,
        'app_version': appVersion,
        'language': language,
      };

  @override
  List<Object?> get props => [token, platform, appVersion, language];
}
