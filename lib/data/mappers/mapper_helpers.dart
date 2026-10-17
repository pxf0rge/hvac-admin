/// Postgres row helpers for domain mappers.
abstract final class MapperHelpers {
  static String str(dynamic value, {String fallback = ''}) => value?.toString() ?? fallback;

  static String? strOrNull(dynamic value) {
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  static String uuid(dynamic value) => str(value);

  static double dbl(dynamic value, {double fallback = 0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? fallback;
  }

  static double? dblOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static String dateOnly(dynamic value) {
    if (value == null) return '';
    final text = value.toString();
    if (text.length >= 10 && text[4] == '-' && text[7] == '-') {
      return text.substring(0, 10);
    }
    return text;
  }

  static String timeHm(dynamic value) {
    if (value == null) return '';
    final text = value.toString();
    final parts = text.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return text;
  }

  static String isoTimestamp(dynamic value) {
    if (value == null) return '';
    if (value is DateTime) return value.toIso8601String();
    return value.toString();
  }

  static int? intOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static final _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static bool isUuid(String value) => _uuidPattern.hasMatch(value);

  static Map<String, dynamic> row(Map<String, dynamic> source) => Map<String, dynamic>.from(source);

  static String newUuid() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final random = (now ^ 0x5f3759df) & 0xffffffffffff;
    final a = (now & 0xffffffff).toRadixString(16).padLeft(8, '0');
    final b = ((now >> 32) & 0xffff).toRadixString(16).padLeft(4, '0');
    final c = (0x4000 | (random & 0x0fff)).toRadixString(16).padLeft(4, '0');
    final d = (0x8000 | ((random >> 12) & 0x3fff)).toRadixString(16).padLeft(4, '0');
    final e = (random >> 26).toRadixString(16).padLeft(12, '0');
    return '$a-$b-$c-$d-$e';
  }
}
