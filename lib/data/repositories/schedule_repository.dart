import '../models/schedule_page_model.dart';

abstract class ScheduleRepository {
  Future<SchedulePageData> getSchedulePage({DateTime? selectedDate});
}

class ScheduleRepositoryImpl implements ScheduleRepository {
  static final _defaultSelectedDate = DateTime(2026, 4, 21);

  @override
  Future<SchedulePageData> getSchedulePage({DateTime? selectedDate}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    final date = selectedDate ?? _defaultSelectedDate;
    final monday = _mondayOfWeek(date);

    final days = List.generate(5, (index) {
      final dayDate = monday.add(Duration(days: index));
      return ScheduleDay(
        date: dayDate,
        dayLabel: _weekdayLabel(dayDate.weekday),
        dayNumber: dayDate.day,
        isSelected: _isSameDay(dayDate, date),
      );
    });

    return SchedulePageData(
      monthLabel: _monthLabel(date),
      days: days,
      selectedDate: date,
      appointments: _appointmentsForDate(date),
    );
  }

  List<ScheduleAppointment> _appointmentsForDate(DateTime date) {
    if (!_isSameDay(date, _defaultSelectedDate)) {
      return const [];
    }

    return const [
      ScheduleAppointment(
        timeLabel: '2:00 PM',
        clientName: 'Steven Mark',
        address: '248 Oak Street, Brooklyn, NY 11201',
        status: ScheduleAppointmentStatus.upcoming,
      ),
      ScheduleAppointment(
        timeLabel: '9:00 PM',
        clientName: 'Mary Smith',
        address: '248 Oak Street, Brooklyn, NY 11201',
        status: ScheduleAppointmentStatus.scheduled,
      ),
      ScheduleAppointment(
        timeLabel: '9:00 PM',
        clientName: 'Mary Smith',
        address: '248 Oak Street, Brooklyn, NY 11201',
        status: ScheduleAppointmentStatus.scheduled,
      ),
    ];
  }

  DateTime _mondayOfWeek(DateTime date) {
    final weekday = date.weekday;
    return DateTime(date.year, date.month, date.day - (weekday - DateTime.monday));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
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
