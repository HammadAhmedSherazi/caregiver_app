/// Tolerant JSON readers for the VELORA contract models.
///
/// Every new field is optional on the wire (the API changes are additive),
/// so readers return `null` / a default instead of throwing when a field is
/// missing or has an unexpected type.
library;

typedef Json = Map<String, dynamic>;

Json? jsonMap(Object? v) => v is Map ? Map<String, dynamic>.from(v) : null;

List<Json> jsonList(Object? v) =>
    v is List ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : const [];

List<String> stringList(Object? v) =>
    v is List ? v.map((e) => '$e').toList() : const [];

String? str(Object? v) => v is String ? v : (v == null ? null : '$v');

String strOr(Object? v, [String fallback = '']) => str(v) ?? fallback;

int? intOrNull(Object? v) => v is num ? v.toInt() : int.tryParse('${v ?? ''}');

double? dblOrNull(Object? v) => v is num ? v.toDouble() : double.tryParse('${v ?? ''}');

bool? boolOrNull(Object? v) => v is bool ? v : (v is num ? v != 0 : null);

/// `YYYY-MM-DD` or ISO-8601 with offset.
DateTime? dateOrNull(Object? v) => v is String ? DateTime.tryParse(v) : null;

/// `YYYY-MM-DD` for request payloads.
String formatDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// ISO-8601 with the device's UTC offset (e.g. `2026-09-22T15:00:00-04:00`).
String formatTimestamp(DateTime d) {
  final local = d.toLocal();
  final offset = local.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final h = offset.inHours.abs().toString().padLeft(2, '0');
  final m = offset.inMinutes.remainder(60).abs().toString().padLeft(2, '0');
  String two(int n) => n.toString().padLeft(2, '0');
  return '${formatDate(local)}T${two(local.hour)}:${two(local.minute)}:${two(local.second)}$sign$h:$m';
}
