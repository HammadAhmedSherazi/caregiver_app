import 'package:equatable/equatable.dart';

import 'common_models.dart';
import 'json.dart';

/// Visit inside a `GET /time/week` day. Hours come from the server.
class TimeVisitModel extends Equatable {
  const TimeVisitModel({
    required this.id,
    this.clockInAt,
    this.clockOutAt,
    this.totalHours,
    this.hoursLabel,
    this.services = const [],
    this.servicesLabel,
    this.status,
  });

  final int id;
  final DateTime? clockInAt;
  final DateTime? clockOutAt;
  final double? totalHours;
  final String? hoursLabel;
  final List<String> services;
  final String? servicesLabel;
  final String? status;

  static TimeVisitModel? maybeFromJson(Object? raw) {
    final j = jsonMap(raw);
    final id = intOrNull(j?['id']);
    if (j == null || id == null) return null;
    return TimeVisitModel(
      id: id,
      clockInAt: dateOrNull(j['clock_in_at']),
      clockOutAt: dateOrNull(j['clock_out_at']),
      totalHours: dblOrNull(j['total_hours']),
      hoursLabel: str(j['hours_label']),
      services: stringList(j['services']),
      servicesLabel: str(j['services_label']),
      status: str(j['status']),
    );
  }

  @override
  List<Object?> get props =>
      [id, clockInAt, clockOutAt, totalHours, hoursLabel, services, servicesLabel, status];
}

class TimeWeekDayModel extends Equatable {
  const TimeWeekDayModel({
    this.date,
    required this.weekdayShort,
    required this.dayNumber,
    required this.isToday,
    required this.isSetDay,
    required this.state,
    required this.stateLabel,
    this.note,
    this.visit,
    this.cta,
  });

  final DateTime? date;
  final String weekdayShort;
  final int dayNumber;
  final bool isToday;
  final bool isSetDay;

  /// `sent` · `not_started` · `missed` · `missing_clockout` · `day_off` ·
  /// `not_set_day` · `pending_fix`.
  final String state;
  final String stateLabel;
  final String? note;
  final TimeVisitModel? visit;
  final LabeledActionModel? cta;

  factory TimeWeekDayModel.fromJson(Json j) => TimeWeekDayModel(
        date: dateOrNull(j['date']),
        weekdayShort: strOr(j['weekday_short']),
        dayNumber: intOrNull(j['day_number']) ?? 0,
        isToday: boolOrNull(j['is_today']) ?? false,
        isSetDay: boolOrNull(j['is_set_day']) ?? false,
        state: strOr(j['state']),
        stateLabel: strOr(j['state_label']),
        note: str(j['note']),
        visit: TimeVisitModel.maybeFromJson(j['visit']),
        cta: LabeledActionModel.maybeFromJson(j['cta']),
      );

  @override
  List<Object?> get props =>
      [date, weekdayShort, dayNumber, isToday, isSetDay, state, stateLabel, note, visit, cta];
}

/// `GET /time/week` 🚧 PLANNED — NOT LIVE.
class TimeWeekModel extends Equatable {
  const TimeWeekModel({
    this.weekStart,
    this.weekEnd,
    required this.label,
    this.plan,
    required this.daysDone,
    this.daysOf,
    this.hours,
    this.hoursLabel,
    required this.days,
    this.footnote,
  });

  final DateTime? weekStart;
  final DateTime? weekEnd;
  final String label;
  final WorkPlanModel? plan;
  final int daysDone;
  final int? daysOf;
  final double? hours;
  final String? hoursLabel;

  /// Always 7 entries, newest first.
  final List<TimeWeekDayModel> days;
  final String? footnote;

  factory TimeWeekModel.fromJson(Json json) {
    final d = jsonMap(json['data']) ?? json;
    final summary = jsonMap(d['summary']) ?? const {};
    return TimeWeekModel(
      weekStart: dateOrNull(d['week_start']),
      weekEnd: dateOrNull(d['week_end']),
      label: strOr(d['label']),
      plan: WorkPlanModel.maybeFromJson(d['plan']),
      daysDone: intOrNull(summary['days_done']) ?? 0,
      daysOf: intOrNull(summary['days_of']),
      hours: dblOrNull(summary['hours']),
      hoursLabel: str(summary['hours_label']),
      days: jsonList(d['days']).map(TimeWeekDayModel.fromJson).toList(),
      footnote: str(d['footnote']),
    );
  }

  @override
  List<Object?> get props =>
      [weekStart, weekEnd, label, plan, daysDone, daysOf, hours, hoursLabel, days, footnote];
}

class ApprovedHoursModel extends Equatable {
  const ApprovedHoursModel({
    required this.limit,
    required this.used,
    required this.remaining,
    required this.percentUsed,
    this.warning,
  });

  final double limit;
  final double used;
  final double remaining;
  final int percentUsed;
  final String? warning;

  static ApprovedHoursModel? maybeFromJson(Object? raw) {
    final j = jsonMap(raw);
    if (j == null) return null;
    return ApprovedHoursModel(
      limit: dblOrNull(j['limit']) ?? 0,
      used: dblOrNull(j['used']) ?? 0,
      remaining: dblOrNull(j['remaining']) ?? 0,
      percentUsed: intOrNull(j['percent_used']) ?? 0,
      warning: str(j['warning']),
    );
  }

  @override
  List<Object?> get props => [limit, used, remaining, percentUsed, warning];
}

class ClockInRateModel extends Equatable {
  const ClockInRateModel({
    required this.completed,
    required this.total,
    required this.percent,
    required this.requiredPercent,
    required this.meetsRequirement,
    this.note,
  });

  final int completed;
  final int total;
  final int percent;
  final int requiredPercent;
  final bool meetsRequirement;
  final String? note;

  static ClockInRateModel? maybeFromJson(Object? raw) {
    final j = jsonMap(raw);
    if (j == null) return null;
    return ClockInRateModel(
      completed: intOrNull(j['completed']) ?? 0,
      total: intOrNull(j['total']) ?? 0,
      percent: intOrNull(j['percent']) ?? 0,
      requiredPercent: intOrNull(j['required_percent']) ?? 85,
      meetsRequirement: boolOrNull(j['meets_requirement']) ?? false,
      note: str(j['note']),
    );
  }

  @override
  List<Object?> get props => [completed, total, percent, requiredPercent, meetsRequirement, note];
}

/// `GET /time/month` 🚧 PLANNED — NOT LIVE.
class TimeMonthModel extends Equatable {
  const TimeMonthModel({
    required this.month,
    required this.label,
    required this.daysWorked,
    this.hours,
    this.hoursLabel,
    this.approvedHours,
    this.clockInRate,
    this.firstWeekday,
    this.calendar = const {},
  });

  /// `YYYY-MM`.
  final String month;
  final String label;
  final int daysWorked;
  final double? hours;
  final String? hoursLabel;
  final ApprovedHoursModel? approvedHours;
  final ClockInRateModel? clockInRate;

  /// ISO weekday of day 1 (1 = Monday), as sent by the server.
  final int? firstWeekday;

  /// Day of month → `worked` · `needs_fix` · `not_worked` · `future`.
  final Map<int, String> calendar;

  factory TimeMonthModel.fromJson(Json json) {
    final d = jsonMap(json['data']) ?? json;
    final cal = jsonMap(d['calendar']) ?? const {};
    return TimeMonthModel(
      month: strOr(d['month']),
      label: strOr(d['label']),
      daysWorked: intOrNull(d['days_worked']) ?? 0,
      hours: dblOrNull(d['hours']),
      hoursLabel: str(d['hours_label']),
      approvedHours: ApprovedHoursModel.maybeFromJson(d['approved_hours']),
      clockInRate: ClockInRateModel.maybeFromJson(d['clock_in_rate']),
      firstWeekday: intOrNull(cal['first_weekday']),
      calendar: {
        for (final day in jsonList(cal['days']))
          if (intOrNull(day['day']) != null) intOrNull(day['day'])!: strOr(day['state']),
      },
    );
  }

  @override
  List<Object?> get props =>
      [month, label, daysWorked, hours, hoursLabel, approvedHours, clockInRate, firstWeekday, calendar];
}
