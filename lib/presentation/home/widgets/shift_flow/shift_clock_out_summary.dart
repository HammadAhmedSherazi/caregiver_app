import '../../../../data/models/home_dashboard_model.dart';

class ShiftClockOutSummary {
  const ShiftClockOutSummary({
    required this.clientName,
    required this.clockInTime,
    required this.clockOutTime,
    required this.totalHours,
    required this.totalHoursCompact,
  });

  final String clientName;
  final String clockInTime;
  final String clockOutTime;
  final String totalHours;
  final String totalHoursCompact;

  static ShiftClockOutSummary fromShift(ActiveShift shift) {
    final startedAt = shift.shiftStartedAt ?? DateTime.now();
    final endedAt = DateTime.now();
    final duration = endedAt.difference(startedAt);

    return ShiftClockOutSummary(
      clientName: shift.clientName,
      clockInTime: _formatClockTime(startedAt),
      clockOutTime: _formatClockTime(endedAt),
      totalHours: _formatTotalHours(duration),
      totalHoursCompact: _formatTotalHoursCompact(duration),
    );
  }

  static String _formatClockTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  static String _formatTotalHours(Duration duration) {
    final hours = duration.inHours;
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    return '${hours}h ${minutes}m';
  }

  static String _formatTotalHoursCompact(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }
}
