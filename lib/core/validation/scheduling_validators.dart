import 'package:hvac_admin/core/validation/field_validators.dart';

abstract final class SchedulingValidators {
  static String? endAfterStart(String? start, String? end) {
    final startError = FieldValidators.timeHHmm(start, label: 'Start time');
    final endError = FieldValidators.timeHHmm(end, label: 'End time');
    if (startError != null || endError != null) return startError ?? endError;

    final startParts = start!.trim().split(':');
    final endParts = end!.trim().split(':');
    final startMin = int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMin = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    if (endMin <= startMin) return 'End time must be after start time.';
    return null;
  }
}
