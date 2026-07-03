import '../api/caregiver_api.dart';
import '../mappers/api_mappers.dart';
import '../models/schedule_page_model.dart';

abstract class ScheduleRepository {
  Future<SchedulePageData> getSchedulePage({
    DateTime? selectedDate,
    ScheduleViewMode viewMode = ScheduleViewMode.day,
  });
}

class ScheduleRepositoryImpl implements ScheduleRepository {
  ScheduleRepositoryImpl({required CaregiverApi api}) : _api = api;

  final CaregiverApi _api;

  @override
  Future<SchedulePageData> getSchedulePage({
    DateTime? selectedDate,
    ScheduleViewMode viewMode = ScheduleViewMode.day,
  }) async {
    final date = selectedDate ?? DateTime.now();

    if (viewMode == ScheduleViewMode.week) {
      return _loadWeek(date);
    }

    return _loadDay(date);
  }

  Future<SchedulePageData> _loadDay(DateTime date) async {
    final query = _formatQueryDate(date);
    final response = await _api.getSchedule(
      from: query,
      to: query,
      upcoming: false,
    );

    final days = List.generate(5, (index) {
      final monday = _mondayOfWeek(date);
      final dayDate = monday.add(Duration(days: index));
      return ScheduleDay(
        date: dayDate,
        dayLabel: _weekdayLabel(dayDate.weekday),
        dayNumber: dayDate.day,
        isSelected: _isSameDay(dayDate, date),
      );
    });

    final appointments = response.data
        .where((item) => _isSameDay(item.scheduledStart, date))
        .map(scheduleItemToAppointment)
        .toList();

    return SchedulePageData(
      monthLabel: _monthLabel(date),
      days: days,
      selectedDate: date,
      appointments: appointments,
      viewMode: ScheduleViewMode.day,
    );
  }

  Future<SchedulePageData> _loadWeek(DateTime date) async {
    final week = await _api.getScheduleWeek(date: _formatQueryDate(date));
    final selected = week.days.firstWhere(
      (day) => day.isToday || _isSameDay(day.dateTime, date),
      orElse: () => week.days.first,
    );

    final days = week.days
        .map(
          (day) => ScheduleDay(
            date: day.dateTime,
            dayLabel: day.weekdayShort,
            dayNumber: day.dayNumber,
            isSelected: _isSameDay(day.dateTime, selected.dateTime),
          ),
        )
        .toList();

    final selectedDay = week.days.firstWhere(
      (day) => _isSameDay(day.dateTime, selected.dateTime),
      orElse: () => week.days.first,
    );

    final appointments =
        selectedDay.visits.map(scheduleItemToAppointment).toList();

    return SchedulePageData(
      monthLabel: week.month.toUpperCase(),
      days: days,
      selectedDate: selectedDay.dateTime,
      appointments: appointments,
      viewMode: ScheduleViewMode.week,
    );
  }

  DateTime _mondayOfWeek(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day - (weekday - DateTime.monday));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatQueryDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _monthLabel(DateTime date) {
    const months = [
      'JANUARY',
      'FEBRUARY',
      'MARCH',
      'APRIL',
      'MAY',
      'JUNE',
      'JULY',
      'AUGUST',
      'SEPTEMBER',
      'OCTOBER',
      'NOVEMBER',
      'DECEMBER',
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _weekdayLabel(int weekday) {
    return switch (weekday) {
      DateTime.monday => 'MON',
      DateTime.tuesday => 'TUE',
      DateTime.wednesday => 'WED',
      DateTime.thursday => 'THU',
      DateTime.friday => 'FRI',
      DateTime.saturday => 'SAT',
      DateTime.sunday => 'SUN',
      _ => '',
    };
  }
}
