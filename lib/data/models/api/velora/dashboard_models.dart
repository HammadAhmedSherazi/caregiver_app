import 'package:equatable/equatable.dart';

import 'common_models.dart';
import 'json.dart';

class DashboardWeekDayModel extends Equatable {
  const DashboardWeekDayModel({
    this.date,
    required this.weekdayShort,
    required this.dayNumber,
    required this.state,
    this.hours,
  });

  final DateTime? date;
  final String weekdayShort;
  final int dayNumber;

  /// `worked` · `needs_fix` · `missed` · `off` · `today` · `upcoming`.
  final String state;
  final double? hours;

  factory DashboardWeekDayModel.fromJson(Json j) => DashboardWeekDayModel(
        date: dateOrNull(j['date']),
        weekdayShort: strOr(j['weekday_short']),
        dayNumber: intOrNull(j['day_number']) ?? 0,
        state: strOr(j['state']),
        hours: dblOrNull(j['hours']),
      );

  @override
  List<Object?> get props => [date, weekdayShort, dayNumber, state, hours];
}

class DashboardWeekModel extends Equatable {
  const DashboardWeekModel({
    this.weekStart,
    this.weekEnd,
    this.planType,
    required this.done,
    this.of,
    this.days = const [],
    this.missedNote,
  });

  final DateTime? weekStart;
  final DateTime? weekEnd;
  final String? planType;
  final int done;
  final int? of;
  final List<DashboardWeekDayModel> days;
  final LabeledActionModel? missedNote;

  static DashboardWeekModel? maybeFromJson(Object? raw) {
    final j = jsonMap(raw);
    if (j == null) return null;
    return DashboardWeekModel(
      weekStart: dateOrNull(j['week_start']),
      weekEnd: dateOrNull(j['week_end']),
      planType: str(j['plan_type']),
      done: intOrNull(j['done']) ?? 0,
      of: intOrNull(j['of']),
      days: jsonList(j['days']).map(DashboardWeekDayModel.fromJson).toList(),
      missedNote: LabeledActionModel.maybeFromJson(j['missed_note']),
    );
  }

  @override
  List<Object?> get props => [weekStart, weekEnd, planType, done, of, days, missedNote];
}

/// `needs_attention[]` — ordered by urgency; its length is the badge count.
class NeedsAttentionItemModel extends Equatable {
  const NeedsAttentionItemModel({
    required this.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String key;
  final String title;
  final String? subtitle;
  final AppActionModel? action;

  factory NeedsAttentionItemModel.fromJson(Json j) => NeedsAttentionItemModel(
        key: strOr(j['key']),
        title: strOr(j['title']),
        subtitle: str(j['subtitle']),
        action: AppActionModel.maybeFromJson(j['action']),
      );

  @override
  List<Object?> get props => [key, title, subtitle, action];
}

class NextPaydayModel extends Equatable {
  const NextPaydayModel({
    this.date,
    required this.label,
    this.lastPaidAmount,
    this.lastPaidDate,
    this.lastPaidLabel,
    this.action,
  });

  final DateTime? date;
  final String label;
  final double? lastPaidAmount;
  final DateTime? lastPaidDate;
  final String? lastPaidLabel;
  final AppActionModel? action;

  static NextPaydayModel? maybeFromJson(Object? raw) {
    final j = jsonMap(raw);
    if (j == null) return null;
    final last = jsonMap(j['last_paid']) ?? const {};
    return NextPaydayModel(
      date: dateOrNull(j['date']),
      label: strOr(j['label']),
      lastPaidAmount: dblOrNull(last['amount']),
      lastPaidDate: dateOrNull(last['date']),
      lastPaidLabel: str(last['label']),
      action: AppActionModel.maybeFromJson(j['action']),
    );
  }

  @override
  List<Object?> get props => [date, label, lastPaidAmount, lastPaidDate, lastPaidLabel, action];
}

/// Additive fields of `GET /dashboard` (§2). `null` on today's live API.
class DashboardExtensionModel extends Equatable {
  const DashboardExtensionModel({
    this.client,
    this.week,
    this.needsAttention = const [],
    this.nextPayday,
  });

  final ClientSummaryModel? client;
  final DashboardWeekModel? week;
  final List<NeedsAttentionItemModel> needsAttention;
  final NextPaydayModel? nextPayday;

  static DashboardExtensionModel? maybeFromJson(Json json) {
    const keys = ['client', 'week', 'needs_attention', 'next_payday'];
    if (!keys.any(json.containsKey)) return null;
    return DashboardExtensionModel(
      client: ClientSummaryModel.maybeFromJson(json['client']),
      week: DashboardWeekModel.maybeFromJson(json['week']),
      needsAttention: jsonList(json['needs_attention']).map(NeedsAttentionItemModel.fromJson).toList(),
      nextPayday: NextPaydayModel.maybeFromJson(json['next_payday']),
    );
  }

  @override
  List<Object?> get props => [client, week, needsAttention, nextPayday];
}
