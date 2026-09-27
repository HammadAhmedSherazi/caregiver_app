import '../../core/utils/velora_format.dart';
import '../../data/models/api/visit_model.dart';

/// Helpers that turn `GET /visits` results into the week / month views
/// used by Home ("This week") and the Time tab.
extension VisitModelX on VisitModel {
  DateTime get day => VeloraFormat.dateOnly(clockInAt.toLocal());

  /// Clock is still open but the visit is not the live one (or it started on
  /// an earlier day, i.e. the clock ran past midnight).
  bool get isMissingClockOut {
    if (clockOutAt != null) return false;
    if (!isActive) return true;
    return !VeloraFormat.sameDay(day, DateTime.now());
  }

  bool get isOpenToday => clockOutAt == null && isActive && !isMissingClockOut;

  Duration? get worked {
    if (totalHours != null) {
      return Duration(minutes: (totalHours! * 60).round());
    }
    final out = clockOutAt;
    if (out == null) return null;
    return out.difference(clockInAt);
  }
}

class DayVisits {
  const DayVisits(this.date, this.visits);

  final DateTime date;
  final List<VisitModel> visits;

  bool get isToday => VeloraFormat.sameDay(date, DateTime.now());
  bool get isFuture => date.isAfter(VeloraFormat.dateOnly(DateTime.now()));
  bool get hasVisit => visits.isNotEmpty;
  bool get needsFix => visits.any((v) => v.isMissingClockOut);
  bool get worked => visits.any((v) => v.clockOutAt != null);

  Duration get total => visits.fold(
        Duration.zero,
        (sum, v) => sum + (v.worked ?? Duration.zero),
      );
}

class VisitPeriodSummary {
  VisitPeriodSummary._(this.days);

  /// Days from [start] (inclusive) for [length] days.
  factory VisitPeriodSummary.range(
    List<VisitModel> visits, {
    required DateTime start,
    required int length,
  }) {
    final days = List.generate(length, (i) {
      final date = DateTime(start.year, start.month, start.day + i);
      return DayVisits(
        date,
        visits.where((v) => VeloraFormat.sameDay(v.day, date)).toList()
          ..sort((a, b) => a.clockInAt.compareTo(b.clockInAt)),
      );
    });
    return VisitPeriodSummary._(days);
  }

  factory VisitPeriodSummary.week(List<VisitModel> visits, [DateTime? anchor]) {
    return VisitPeriodSummary.range(
      visits,
      start: VeloraFormat.startOfWeek(anchor ?? DateTime.now()),
      length: 7,
    );
  }

  factory VisitPeriodSummary.month(List<VisitModel> visits, [DateTime? anchor]) {
    final a = anchor ?? DateTime.now();
    final first = DateTime(a.year, a.month);
    final length = DateTime(a.year, a.month + 1, 0).day;
    return VisitPeriodSummary.range(visits, start: first, length: length);
  }

  final List<DayVisits> days;

  int get daysWorked => days.where((d) => d.worked).length;
  int get fixCount => days.where((d) => d.needsFix).length;
  int get visitCount => days.fold(0, (n, d) => n + d.visits.length);

  Duration get total =>
      days.fold(Duration.zero, (sum, d) => sum + d.total);
}
