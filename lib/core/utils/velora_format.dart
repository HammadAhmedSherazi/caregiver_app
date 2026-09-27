/// Small date/time formatters used by the redesigned screens
/// (the project does not depend on `intl`).
class VeloraFormat {
  VeloraFormat._();

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December',
  ];
  static const _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  static String monthName(int month) => _months[month - 1];
  static String monthShort(int month) => _months[month - 1].substring(0, 3);
  static String weekday(DateTime d) => _weekdays[d.weekday - 1];
  static String weekdayShort(DateTime d) => _weekdays[d.weekday - 1].substring(0, 3);

  /// `Friday, September 25`
  static String longDate(DateTime d) =>
      '${weekday(d)}, ${monthName(d.month)} ${d.day}';

  /// `Fri, Sep 25`
  static String shortDate(DateTime d) =>
      '${weekdayShort(d)}, ${monthShort(d.month)} ${d.day}';

  /// `Sep 25`
  static String monthDay(DateTime d) => '${monthShort(d.month)} ${d.day}';

  /// `9:02 AM`
  static String time(DateTime d) {
    final local = d.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${local.hour < 12 ? 'AM' : 'PM'}';
  }

  /// `6h 08m`
  static String duration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    return '${hours}h ${minutes}m';
  }

  /// `1:18:32` timer text.
  static String timer(Duration d) {
    final safe = d.isNegative ? Duration.zero : d;
    final h = safe.inHours;
    final m = safe.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = safe.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  /// Greeting for the current hour.
  static String greeting([DateTime? now]) {
    final hour = (now ?? DateTime.now()).hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Monday 00:00 of the week containing [d].
  static DateTime startOfWeek(DateTime d) =>
      dateOnly(d).subtract(Duration(days: d.weekday - 1));

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  static String firstName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    return trimmed.split(RegExp(r'\s+')).first;
  }
}
