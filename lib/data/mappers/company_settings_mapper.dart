import 'package:hvac_admin/core/models/company_settings.dart';
import 'package:hvac_admin/data/mappers/mapper_helpers.dart';

abstract final class CompanySettingsMapper {
  static CompanySettings fromRow(Map<String, dynamic> row) {
    final start = _minutesFromTime(row['gps_workday_start']) ?? CompanySettings.defaultGpsStartMinutes;
    final end = _minutesFromTime(row['gps_workday_end']) ?? CompanySettings.defaultGpsEndMinutes;
    final window = CompanySettings.validateGpsHours(startMinutes: start, endMinutes: end) == null
        ? (start, end)
        : (CompanySettings.defaultGpsStartMinutes, CompanySettings.defaultGpsEndMinutes);

    final leadRaw = row['appointment_reminder_lead_hours'];
    final leadHours = leadRaw is int
        ? leadRaw
        : int.tryParse(leadRaw?.toString() ?? '') ??
            CompanySettings.defaultAppointmentReminderLeadHours;

    return CompanySettings(
      companyName: MapperHelpers.str(row['company_name']),
      phone: MapperHelpers.str(row['phone']),
      addressLine: MapperHelpers.str(row['address_line']),
      city: MapperHelpers.str(row['city']),
      state: MapperHelpers.str(row['state']),
      zip: MapperHelpers.str(row['zip']),
      logoStoragePath: MapperHelpers.str(row['logo_storage_path']),
      gpsWorkdayStartMinutes: window.$1,
      gpsWorkdayEndMinutes: window.$2,
      gpsTimezone: MapperHelpers.str(row['gps_timezone']).isEmpty
          ? CompanySettings.defaultGpsTimezone
          : MapperHelpers.str(row['gps_timezone']),
      gpsTimezoneNote: MapperHelpers.str(row['gps_timezone_note']).isEmpty
          ? CompanySettings.defaultGpsTimezoneNote
          : MapperHelpers.str(row['gps_timezone_note']),
      appointmentReminderEnabled: row['appointment_reminder_enabled'] != false,
      appointmentReminderLeadHours:
          CompanySettings.validateReminderLeadHours(leadHours) == null
              ? leadHours
              : CompanySettings.defaultAppointmentReminderLeadHours,
      maintenanceReminderEnabled: row['maintenance_reminder_enabled'] != false,
    );
  }

  static Map<String, dynamic> toRow(CompanySettings settings) {
    final window = settings.normalizedGpsWindow;
    return {
      'id': 1,
      'company_name': settings.companyName.trim(),
      'phone': settings.phone.trim(),
      'address_line': settings.addressLine.trim(),
      'city': settings.city.trim(),
      'state': settings.state.trim(),
      'zip': settings.zip.trim(),
      'logo_storage_path': settings.logoStoragePath.trim(),
      'gps_workday_start': _timeFromMinutes(window.$1),
      'gps_workday_end': _timeFromMinutes(window.$2),
      'gps_timezone': settings.gpsTimezone.trim().isEmpty
          ? CompanySettings.defaultGpsTimezone
          : settings.gpsTimezone.trim(),
      'gps_timezone_note': settings.gpsTimezoneNote.trim().isEmpty
          ? CompanySettings.defaultGpsTimezoneNote
          : settings.gpsTimezoneNote.trim(),
      'appointment_reminder_enabled': settings.appointmentReminderEnabled,
      'appointment_reminder_lead_hours': settings.normalizedAppointmentReminderLeadHours,
      'maintenance_reminder_enabled': settings.maintenanceReminderEnabled,
    };
  }

  static int? _minutesFromTime(Object? raw) {
    if (raw == null) return null;
    final text = raw.toString().trim();
    if (text.isEmpty) return null;
    final parts = text.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return hour * 60 + minute;
  }

  static String _timeFromMinutes(int minutes) {
    final clamped = minutes.clamp(0, 24 * 60);
    final hour = clamped ~/ 60;
    final minute = clamped % 60;
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }
}
