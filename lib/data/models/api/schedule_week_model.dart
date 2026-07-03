import '../base_model.dart';
import 'schedule_item_model.dart';

class ScheduleWeekDayModel extends BaseModel {
  const ScheduleWeekDayModel({
    required this.date,
    required this.weekday,
    required this.weekdayShort,
    required this.dayNumber,
    required this.isToday,
    required this.count,
    required this.visits,
  });

  final String date;
  final String weekday;
  final String weekdayShort;
  final int dayNumber;
  final bool isToday;
  final int count;
  final List<ScheduleItemModel> visits;

  factory ScheduleWeekDayModel.fromJson(Map<String, dynamic> json) {
    final visitsRaw = json['visits'] as List<dynamic>? ?? const [];
    return ScheduleWeekDayModel(
      date: json['date'] as String? ?? '',
      weekday: json['weekday'] as String? ?? '',
      weekdayShort: json['weekday_short'] as String? ?? '',
      dayNumber: json['day_number'] as int? ?? 0,
      isToday: json['is_today'] as bool? ?? false,
      count: json['count'] as int? ?? 0,
      visits: visitsRaw
          .whereType<Map<String, dynamic>>()
          .map(ScheduleItemModel.fromJson)
          .toList(),
    );
  }

  DateTime get dateTime => DateTime.parse(date);

  @override
  Map<String, dynamic> toJson() => {
        'date': date,
        'weekday': weekday,
        'weekday_short': weekdayShort,
        'day_number': dayNumber,
        'is_today': isToday,
        'count': count,
        'visits': visits.map((v) => v.toJson()).toList(),
      };

  @override
  List<Object?> get props =>
      [date, weekday, weekdayShort, dayNumber, isToday, count, visits];
}

class ScheduleWeekModel extends BaseModel {
  const ScheduleWeekModel({
    required this.weekStart,
    required this.weekEnd,
    required this.month,
    required this.days,
  });

  final String weekStart;
  final String weekEnd;
  final String month;
  final List<ScheduleWeekDayModel> days;

  factory ScheduleWeekModel.fromJson(Map<String, dynamic> json) {
    final daysRaw = json['days'] as List<dynamic>? ?? const [];
    return ScheduleWeekModel(
      weekStart: json['week_start'] as String? ?? '',
      weekEnd: json['week_end'] as String? ?? '',
      month: json['month'] as String? ?? '',
      days: daysRaw
          .whereType<Map<String, dynamic>>()
          .map(ScheduleWeekDayModel.fromJson)
          .toList(),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'week_start': weekStart,
        'week_end': weekEnd,
        'month': month,
        'days': days.map((d) => d.toJson()).toList(),
      };

  @override
  List<Object?> get props => [weekStart, weekEnd, month, days];
}
