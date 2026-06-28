import '../api/caregiver_api.dart';
import '../mappers/api_mappers.dart';
import '../models/schedule_page_model.dart';

abstract class ScheduleRepository {
  Future<SchedulePageData> getSchedulePage({DateTime? selectedDate});
}

class ScheduleRepositoryImpl implements ScheduleRepository {
  ScheduleRepositoryImpl({required CaregiverApi api}) : _api = api;

  final CaregiverApi _api;

  @override
  Future<SchedulePageData> getSchedulePage({DateTime? selectedDate}) async {
    final date = selectedDate ?? DateTime.now();
    final monday = _mondayOfWeek(date);
    final friday = monday.add(const Duration(days: 4));

    final response = await _api.getSchedule(
      from: _formatQueryDate(monday),
      to: _formatQueryDate(friday),
      upcoming: false,
    );

    final days = List.generate(5, (index) {
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
