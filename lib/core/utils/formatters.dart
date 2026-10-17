import 'package:hvac_admin/core/l10n/admin_strings.dart';

String formatCurrency(num amount, {String symbol = r'$'}) {
  final value = amount.toDouble();
  final negative = value < 0;
  final abs = value.abs();
  final whole = abs.truncate();
  final cents = ((abs - whole) * 100).round().clamp(0, 99);
  final wholeText = _groupDigits(whole);
  final prefix = negative ? '-$symbol' : symbol;
  return '$prefix$wholeText.${cents.toString().padLeft(2, '0')}';
}

String _groupDigits(int value) {
  final text = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
    buffer.write(text[i]);
  }
  return buffer.toString();
}

String isoDate(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

String formatPhone(String phone) {
  final digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 10) {
    return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
  }
  if (digits.length == 11 && digits.startsWith('1')) {
    return '+1 (${digits.substring(1, 4)}) ${digits.substring(4, 7)}-${digits.substring(7)}';
  }
  return phone;
}

String formatDate(String isoDate) {
  if (isoDate.isEmpty) return '';
  final parts = isoDate.split('-');
  if (parts.length != 3) return isoDate;
  return '${parts[1]}/${parts[2]}/${parts[0]}';
}

String formatTimeRange(String start, String end) {
  if (start.isEmpty && end.isEmpty) return '';
  if (end.isEmpty) return start;
  return '$start – $end';
}

String todayIso() {
  final now = DateTime.now();
  return isoDate(now);
}

String formatRelativeDate(String isoDate, {AdminStrings? strings}) {
  if (isoDate.isEmpty) return '';
  final parsed = DateTime.tryParse(isoDate);
  if (parsed == null) return formatDate(isoDate);
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(parsed.year, parsed.month, parsed.day);
  final delta = day.difference(today).inDays;
  if (delta == 0) return strings?.today ?? 'Today';
  if (delta == 1) return strings?.tomorrow ?? 'Tomorrow';
  if (delta == -1) return strings?.yesterday ?? 'Yesterday';
  return formatDate(isoDate);
}

String formatDateTime(String timestamp) {
  if (timestamp.isEmpty) return '';
  final parsed = DateTime.tryParse(timestamp);
  if (parsed == null) return timestamp;
  final local = parsed.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final suffix = local.hour >= 12 ? 'PM' : 'AM';
  return '${formatDate(isoDate(local))} $hour:$minute $suffix';
}

int timeToMinutes(String time) {
  final parts = time.split(':');
  return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
}
