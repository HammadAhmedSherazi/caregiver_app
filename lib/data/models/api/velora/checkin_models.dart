import 'package:equatable/equatable.dart';

import '../../../../core/network/api_exception.dart';
import 'common_models.dart';
import 'json.dart';

/// `mode` of a check-in (§8).
enum CheckInMode {
  clocks('clocks'),
  liveInDhs('live_in_dhs'),
  liveInMich('live_in_mich');

  const CheckInMode(this.value);

  final String value;

  static CheckInMode? fromValue(String? v) {
    for (final m in values) {
      if (m.value == v) return m;
    }
    return null;
  }
}

class CheckInTimelineStepModel extends Equatable {
  const CheckInTimelineStepModel({required this.step, this.title, this.label, this.subtitle});

  final int step;
  final String? title;
  final String? label;
  final String? subtitle;

  factory CheckInTimelineStepModel.fromJson(Json j) => CheckInTimelineStepModel(
        step: intOrNull(j['step']) ?? 0,
        title: str(j['title']),
        label: str(j['label']),
        subtitle: str(j['subtitle']),
      );

  @override
  List<Object?> get props => [step, title, label, subtitle];
}

/// Additive fields of each form in `GET /compliance-forms` (§8).
/// `null` on today's live API.
class ComplianceFormExtensionModel extends Equatable {
  const ComplianceFormExtensionModel({
    this.mode,
    this.cadence,
    this.periodStart,
    this.periodEnd,
    this.periodShort,
    this.state,
    this.opensAt,
    this.dueAt,
    this.dueLabel,
    this.payDate,
    this.payLabel,
    this.visitsWithAnswersDone,
    this.visitsWithAnswersTotal,
    this.hospitalStays = const [],
    this.careNotGivenDays,
    this.timeline = const [],
  });

  final CheckInMode? mode;
  final String? cadence;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final String? periodShort;

  /// `upcoming` · `open` · `draft` · `submitted` · `overdue`
  /// (the existing `status` field is unchanged).
  final String? state;
  final DateTime? opensAt;

  /// Open decision D8 — the server decides the rule; the app only shows it.
  final DateTime? dueAt;
  final String? dueLabel;
  final DateTime? payDate;
  final String? payLabel;
  final int? visitsWithAnswersDone;
  final int? visitsWithAnswersTotal;
  final List<HospitalStayModel> hospitalStays;
  final int? careNotGivenDays;
  final List<CheckInTimelineStepModel> timeline;

  static ComplianceFormExtensionModel? maybeFromJson(Json json) {
    const keys = ['mode', 'cadence', 'period_start', 'state', 'due_at', 'timeline', 'summary'];
    if (!keys.any(json.containsKey)) return null;
    final summary = jsonMap(json['summary']) ?? const {};
    final visits = jsonMap(summary['visits_with_answers']) ?? const {};
    return ComplianceFormExtensionModel(
      mode: CheckInMode.fromValue(str(json['mode'])),
      cadence: str(json['cadence']),
      periodStart: dateOrNull(json['period_start']),
      periodEnd: dateOrNull(json['period_end']),
      periodShort: str(json['period_short']),
      state: str(json['state']),
      opensAt: dateOrNull(json['opens_at']),
      dueAt: dateOrNull(json['due_at']),
      dueLabel: str(json['due_label']),
      payDate: dateOrNull(json['pay_date']),
      payLabel: str(json['pay_label']),
      visitsWithAnswersDone: intOrNull(visits['done']),
      visitsWithAnswersTotal: intOrNull(visits['total']),
      hospitalStays: jsonList(summary['hospital_stays'])
          .map(HospitalStayModel.maybeFromJson)
          .whereType<HospitalStayModel>()
          .toList(),
      careNotGivenDays: intOrNull(summary['care_not_given_days']),
      timeline: jsonList(json['timeline']).map(CheckInTimelineStepModel.fromJson).toList(),
    );
  }

  @override
  List<Object?> get props => [
        mode, cadence, periodStart, periodEnd, periodShort, state, opensAt, dueAt, dueLabel,
        payDate, payLabel, visitsWithAnswersDone, visitsWithAnswersTotal, hospitalStays,
        careNotGivenDays, timeline,
      ];
}

/// Additive fields of `/compliance-forms/history` records.
class ComplianceHistoryExtensionModel extends Equatable {
  const ComplianceHistoryExtensionModel({this.signedAt, this.paidAt, this.netPay, this.payId});

  final DateTime? signedAt;
  final DateTime? paidAt;
  final double? netPay;

  /// → Paystub (`GET /pay/{id}`).
  final int? payId;

  static ComplianceHistoryExtensionModel? maybeFromJson(Json json) {
    const keys = ['signed_at', 'paid_at', 'net_pay', 'pay_id'];
    if (!keys.any(json.containsKey)) return null;
    return ComplianceHistoryExtensionModel(
      signedAt: dateOrNull(json['signed_at']),
      paidAt: dateOrNull(json['paid_at']),
      netPay: dblOrNull(json['net_pay']),
      payId: intOrNull(json['pay_id']),
    );
  }

  @override
  List<Object?> get props => [signedAt, paidAt, netPay, payId];
}

/// A Yes/No check-in question with a details box that opens on Yes
/// (`care_not_given`, `missed_or_late`).
class CheckInYesNoAnswer extends Equatable {
  const CheckInYesNoAnswer({required this.answer, this.details});

  static const no = CheckInYesNoAnswer(answer: false);

  static const maxDetailsLength = 2000;

  final bool answer;
  final String? details;

  String? get _trimmedDetails {
    final d = details?.trim();
    return d == null || d.isEmpty ? null : d;
  }

  /// `details` is required when `answer` is true (max 2000 chars).
  Map<String, List<String>> validate(String field) {
    if (!answer) return const {};
    final d = _trimmedDetails;
    if (d == null) return {'$field.details': ['Tell us a little more.']};
    if (d.length > maxDetailsLength) {
      return {'$field.details': ['Keep it under $maxDetailsLength characters.']};
    }
    return const {};
  }

  /// Accepts the object shape and, for older payloads, a bare bool.
  static CheckInYesNoAnswer? maybeFromJson(Object? raw) {
    final flag = boolOrNull(raw);
    if (flag != null) return CheckInYesNoAnswer(answer: flag);
    final j = jsonMap(raw);
    final answer = boolOrNull(j?['answer']);
    if (j == null || answer == null) return null;
    return CheckInYesNoAnswer(answer: answer, details: str(j['details']));
  }

  Map<String, dynamic> toJson() => {'answer': answer, 'details': answer ? _trimmedDetails : null};

  @override
  List<Object?> get props => [answer, details];
}

/// Answers block used by the check-in prefill, draft and submit.
///
/// In `live_in_dhs` / `live_in_mich` modes the prefill answers are all
/// `null` and the app requires all three.
class CheckInAnswers extends Equatable {
  const CheckInAnswers({
    this.hospital,
    this.careNotGiven,
    this.missedOrLate,
    this.additionalNotes,
  });

  final HospitalStayModel? hospital;
  final CheckInYesNoAnswer? careNotGiven;
  final CheckInYesNoAnswer? missedOrLate;
  final String? additionalNotes;

  bool get isComplete => hospital != null && careNotGiven != null && missedOrLate != null;

  Map<String, List<String>> validate([String prefix = 'answers']) => {
        if (hospital != null) ...hospital!.validate('$prefix.hospital'),
        if (careNotGiven != null) ...careNotGiven!.validate('$prefix.care_not_given'),
        if (missedOrLate != null) ...missedOrLate!.validate('$prefix.missed_or_late'),
      };

  static CheckInAnswers? maybeFromJson(Object? raw) {
    final j = jsonMap(raw);
    if (j == null) return null;
    return CheckInAnswers(
      hospital: HospitalStayModel.maybeFromJson(j['hospital']),
      careNotGiven: CheckInYesNoAnswer.maybeFromJson(j['care_not_given']),
      missedOrLate: CheckInYesNoAnswer.maybeFromJson(j['missed_or_late']),
      additionalNotes: str(j['additional_notes']),
    );
  }

  /// Draft allows partial answers — only the known ones are sent.
  Map<String, dynamic> toJson() => {
        if (hospital != null) 'hospital': hospital!.toJson(),
        if (careNotGiven != null) 'care_not_given': careNotGiven!.toJson(),
        if (missedOrLate != null) 'missed_or_late': missedOrLate!.toJson(),
        if (additionalNotes != null)
          'additional_notes': additionalNotes!.trim().isEmpty ? null : additionalNotes!.trim(),
      };

  @override
  List<Object?> get props => [hospital, careNotGiven, missedOrLate, additionalNotes];
}

/// Day state inside a check-in.
enum CheckInDayState {
  worked('worked'),
  notWorked('not_worked'),
  hospital('hospital');

  const CheckInDayState(this.value);

  final String value;

  static CheckInDayState? fromValue(String? v) {
    for (final s in values) {
      if (s.value == v) return s;
    }
    return null;
  }

  /// Tapping a day cycles worked → not worked → hospital (device logic).
  CheckInDayState get next => switch (this) {
        worked => notWorked,
        notWorked => hospital,
        hospital => worked,
      };
}

class CheckInDayModel extends Equatable {
  const CheckInDayModel({required this.date, required this.state, this.locked = false});

  final DateTime date;
  final CheckInDayState state;

  /// Derived from hospital dates — cannot be tapped away.
  final bool locked;

  static CheckInDayModel? maybeFromJson(Json j) {
    final date = dateOrNull(j['date']);
    final state = CheckInDayState.fromValue(str(j['state']));
    if (date == null || state == null) return null;
    return CheckInDayModel(date: date, state: state, locked: boolOrNull(j['locked']) ?? false);
  }

  Map<String, dynamic> toJson() => {'date': formatDate(date), 'state': state.value};

  @override
  List<Object?> get props => [date, state, locked];
}

class CheckInCountsModel extends Equatable {
  const CheckInCountsModel({required this.worked, required this.notWorked, required this.hospital});

  final int worked;
  final int notWorked;
  final int hospital;

  static CheckInCountsModel? maybeFromJson(Object? raw) {
    final j = jsonMap(raw);
    if (j == null) return null;
    return CheckInCountsModel(
      worked: intOrNull(j['worked']) ?? 0,
      notWorked: intOrNull(j['not_worked']) ?? 0,
      hospital: intOrNull(j['hospital']) ?? 0,
    );
  }

  @override
  List<Object?> get props => [worked, notWorked, hospital];
}

/// `check_in` block of `GET /compliance-forms/{id}`. `null` on today's API.
class CheckInDetailModel extends Equatable {
  const CheckInDetailModel({
    this.prefill,
    this.days = const [],
    this.counts,
    this.hoursPerDayEstimate,
    this.calendarFirstWeekday,
    this.calendarDaysInMonth,
    this.signatureType,
    this.confirmationText,
  });

  final CheckInAnswers? prefill;
  final List<CheckInDayModel> days;
  final CheckInCountsModel? counts;

  /// For "3 days (about 17.4 hrs) removed from pay and billing".
  final double? hoursPerDayEstimate;

  /// Month grid alignment (a MICH half-month still shows the full month;
  /// days outside [days] are greyed).
  final int? calendarFirstWeekday;
  final int? calendarDaysInMonth;

  /// `typed_name`.
  final String? signatureType;
  final String? confirmationText;

  static CheckInDetailModel? maybeFromJson(Object? raw) {
    final j = jsonMap(raw);
    if (j == null) return null;
    final sig = jsonMap(j['signature']) ?? const {};
    final calendar = jsonMap(j['calendar']) ?? const {};
    return CheckInDetailModel(
      prefill: CheckInAnswers.maybeFromJson(j['prefill']),
      days: jsonList(j['days']).map(CheckInDayModel.maybeFromJson).whereType<CheckInDayModel>().toList(),
      counts: CheckInCountsModel.maybeFromJson(j['counts']),
      hoursPerDayEstimate: dblOrNull(j['hours_per_day_estimate']),
      calendarFirstWeekday: intOrNull(calendar['first_weekday']),
      calendarDaysInMonth: intOrNull(calendar['days_in_month']),
      signatureType: str(sig['type']),
      confirmationText: str(sig['confirmation_text']),
    );
  }

  @override
  List<Object?> get props => [
        prefill, days, counts, hoursPerDayEstimate, calendarFirstWeekday,
        calendarDaysInMonth, signatureType, confirmationText,
      ];

  /// Estimated hours removed for [hospitalDays] days, or `null` without an
  /// estimate from the server.
  double? hoursRemovedFor(int hospitalDays) {
    final perDay = hoursPerDayEstimate;
    return perDay == null ? null : hospitalDays * perDay;
  }
}

/// Body of `PUT /compliance-forms/{id}/draft` ("Save & exit"). All optional.
class CheckInDraftRequest extends Equatable {
  const CheckInDraftRequest({this.answers, this.changedDays = const []});

  final CheckInAnswers? answers;

  /// May be only the changed days.
  final List<CheckInDayModel> changedDays;

  Map<String, dynamic> toJson() => {
        if (answers != null) 'answers': answers!.toJson(),
        if (changedDays.isNotEmpty) 'days': changedDays.map((d) => d.toJson()).toList(),
      };

  @override
  List<Object?> get props => [answers, changedDays];
}

/// Typed-name body of `POST /compliance-forms/{id}/submit` (new format).
/// The existing drawn-signature body (`answers` map + `signature`) is still
/// used while the planned API is off.
class CheckInSubmitRequest extends Equatable {
  const CheckInSubmitRequest({
    required this.answers,
    this.changedDays = const [],
    required this.signatureName,
    required this.confirmed,
  });

  final CheckInAnswers answers;
  final List<CheckInDayModel> changedDays;
  final String signatureName;
  final bool confirmed;

  void validate() {
    final errors = <String, List<String>>{};
    if (signatureName.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length < 2) {
      errors['signature_name'] = ['Type your full name (first and last).'];
    }
    if (!confirmed) errors['confirmed'] = ['Confirm the care you reported is true.'];
    if (!answers.isComplete) errors['answers'] = ['Answer every question.'];
    errors.addAll(answers.validate());
    if (errors.isNotEmpty) throw RequestValidationException(errors);
  }

  Map<String, dynamic> toJson() => {
        'answers': {
          'hospital': (answers.hospital ?? const HospitalStayModel.none()).toJson(),
          'care_not_given': (answers.careNotGiven ?? CheckInYesNoAnswer.no).toJson(),
          'missed_or_late': (answers.missedOrLate ?? CheckInYesNoAnswer.no).toJson(),
          'additional_notes': (answers.additionalNotes?.trim().isEmpty ?? true)
              ? null
              : answers.additionalNotes!.trim(),
        },
        if (changedDays.isNotEmpty) 'days': changedDays.map((d) => d.toJson()).toList(),
        'signature_name': signatureName.trim(),
        'confirmed': confirmed,
      };

  @override
  List<Object?> get props => [answers, changedDays, signatureName, confirmed];
}

/// Additive fields of the submit response.
class CheckInSubmitExtensionModel extends Equatable {
  const CheckInSubmitExtensionModel({
    this.submittedAt,
    this.counts,
    this.receiptAvailable,
    this.receiptTitle,
    this.payDate,
    this.payLabel,
    this.onTrack,
  });

  final DateTime? submittedAt;
  final CheckInCountsModel? counts;
  final bool? receiptAvailable;
  final String? receiptTitle;
  final DateTime? payDate;
  final String? payLabel;
  final bool? onTrack;

  static CheckInSubmitExtensionModel? maybeFromJson(Json json) {
    const keys = ['counts', 'receipt', 'pay', 'submitted_at'];
    if (!keys.any(json.containsKey)) return null;
    final receipt = jsonMap(json['receipt']) ?? const {};
    final pay = jsonMap(json['pay']) ?? const {};
    return CheckInSubmitExtensionModel(
      submittedAt: dateOrNull(json['submitted_at']),
      counts: CheckInCountsModel.maybeFromJson(json['counts']),
      receiptAvailable: boolOrNull(receipt['available']),
      receiptTitle: str(receipt['title']),
      payDate: dateOrNull(pay['pay_date']),
      payLabel: str(pay['pay_label']),
      onTrack: boolOrNull(pay['on_track']),
    );
  }

  @override
  List<Object?> get props => [submittedAt, counts, receiptAvailable, receiptTitle, payDate, payLabel, onTrack];
}
