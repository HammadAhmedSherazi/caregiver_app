import 'package:equatable/equatable.dart';

enum ScheduleViewMode { day, week }

enum ScheduleAppointmentStatus { upcoming, scheduled }

class ScheduleDay extends Equatable {
  const ScheduleDay({
    required this.date,
    required this.dayLabel,
    required this.dayNumber,
    required this.isSelected,
  });

  final DateTime date;
  final String dayLabel;
  final int dayNumber;
  final bool isSelected;

  @override
  List<Object?> get props => [date, dayLabel, dayNumber, isSelected];
}

class ScheduleAppointment extends Equatable {
  const ScheduleAppointment({
    required this.timeLabel,
    required this.clientName,
    required this.address,
    required this.status,
  });

  final String timeLabel;
  final String clientName;
  final String address;
  final ScheduleAppointmentStatus status;

  @override
  List<Object?> get props => [timeLabel, clientName, address, status];
}

class SchedulePageData extends Equatable {
  const SchedulePageData({
    required this.monthLabel,
    required this.days,
    required this.appointments,
    this.viewMode = ScheduleViewMode.day,
    this.selectedDate,
  });

  final String monthLabel;
  final List<ScheduleDay> days;
  final List<ScheduleAppointment> appointments;
  final ScheduleViewMode viewMode;
  final DateTime? selectedDate;

  SchedulePageData copyWith({
    String? monthLabel,
    List<ScheduleDay>? days,
    List<ScheduleAppointment>? appointments,
    ScheduleViewMode? viewMode,
    DateTime? selectedDate,
  }) {
    return SchedulePageData(
      monthLabel: monthLabel ?? this.monthLabel,
      days: days ?? this.days,
      appointments: appointments ?? this.appointments,
      viewMode: viewMode ?? this.viewMode,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }

  @override
  List<Object?> get props => [
        monthLabel,
        days,
        appointments,
        viewMode,
        selectedDate,
      ];
}
