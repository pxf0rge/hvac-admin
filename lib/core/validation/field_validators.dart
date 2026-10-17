abstract final class FieldValidators {
  static String? requiredText(String? value, {required String label}) {
    if (value == null || value.trim().isEmpty) return '$label is required';
    return null;
  }

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Email is required';
    if (!text.contains('@') || !text.contains('.')) return 'Enter a valid email';
    return null;
  }

  static String? phone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return 'Enter a valid phone number';
    return null;
  }

  static String? zipCode(String? value) {
    final text = value?.trim() ?? '';
    if (text.length < 5) return 'Enter a valid ZIP code';
    return null;
  }

  static bool isIsoDate(String value) {
    final parts = value.split('-');
    if (parts.length != 3) return false;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return false;
    return DateTime(year, month, day).year == year && DateTime(year, month, day).month == month;
  }

  static String? isoDate(String? value, {required String label}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$label is required';
    if (!isIsoDate(text)) return '$label must be YYYY-MM-DD';
    return null;
  }

  static String? timeHHmm(String? value, {required String label}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$label is required';
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(text);
    if (match == null) return '$label must be HH:mm';
    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      return '$label must be HH:mm';
    }
    return null;
  }

  /// Throws [FormatException] with a user-safe message when invalid.
  static void money(double value, {String field = 'Amount'}) {
    if (value.isNaN || value.isInfinite) {
      throw FormatException('$field is not a valid amount.');
    }
    if (value < 0) {
      throw FormatException('$field cannot be negative.');
    }
    if (value > 1e9) {
      throw FormatException('$field is too large.');
    }
  }

  /// Throws [FormatException] with a user-safe message when invalid.
  static void quantity(double value, {String field = 'Quantity'}) {
    if (value.isNaN || value.isInfinite) {
      throw FormatException('$field is not a valid quantity.');
    }
    if (value <= 0) {
      throw FormatException('$field must be greater than zero.');
    }
    if (value > 1e6) {
      throw FormatException('$field is too large.');
    }
  }

  static String? positiveDecimal(String? value, {required String label}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$label is required';
    final parsed = double.tryParse(text);
    if (parsed == null) return '$label must be a number';
    try {
      quantity(parsed, field: label);
      return null;
    } on FormatException catch (error) {
      return error.message;
    }
  }
}
