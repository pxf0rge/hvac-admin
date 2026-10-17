class CompanySettings {
  const CompanySettings({
    required this.companyName,
    required this.phone,
    required this.addressLine,
    required this.city,
    required this.state,
    required this.zip,
    this.logoStoragePath = '',
    this.gpsWorkdayStartMinutes = defaultGpsStartMinutes,
    this.gpsWorkdayEndMinutes = defaultGpsEndMinutes,
    this.gpsTimezone = defaultGpsTimezone,
    this.gpsTimezoneNote = defaultGpsTimezoneNote,
    this.appointmentReminderEnabled = true,
    this.appointmentReminderLeadHours = defaultAppointmentReminderLeadHours,
    this.maintenanceReminderEnabled = true,
  });

  static const defaultGpsStartMinutes = 7 * 60;
  static const defaultGpsEndMinutes = 18 * 60;
  static const defaultGpsTimezone = 'America/Chicago';
  static const defaultGpsTimezoneNote = 'Company local time';
  static const defaultAppointmentReminderLeadHours = 24;

  factory CompanySettings.defaults() => const CompanySettings(
        companyName: 'Arctic HVAC Solutions',
        phone: '',
        addressLine: '',
        city: '',
        state: '',
        zip: '',
      );

  final String companyName;
  final String phone;
  final String addressLine;
  final String city;
  final String state;
  final String zip;
  final String logoStoragePath;

  /// Minutes from midnight (inclusive). Invalid ranges fall back via [normalizedGpsWindow].
  final int gpsWorkdayStartMinutes;
  final int gpsWorkdayEndMinutes;
  final String gpsTimezone;
  final String gpsTimezoneNote;

  final bool appointmentReminderEnabled;
  final int appointmentReminderLeadHours;
  final bool maintenanceReminderEnabled;

  /// Fail closed: empty/invalid → Arctic HVAC Solutions defaults (never 24/7).
  (int, int) get normalizedGpsWindow {
    final start = gpsWorkdayStartMinutes;
    final end = gpsWorkdayEndMinutes;
    if (start < 0 || start > 23 * 60 + 59 || end < 0 || end > 24 * 60) {
      return (defaultGpsStartMinutes, defaultGpsEndMinutes);
    }
    if (start >= end) {
      return (defaultGpsStartMinutes, defaultGpsEndMinutes);
    }
    return (start, end);
  }

  static String? validateGpsHours({required int startMinutes, required int endMinutes}) {
    if (startMinutes < 0 || startMinutes > 23 * 60 + 59) {
      return 'Start time is invalid';
    }
    if (endMinutes < 1 || endMinutes > 24 * 60) {
      return 'End time is invalid';
    }
    if (startMinutes >= endMinutes) {
      return 'End time must be after start time';
    }
    return null;
  }

  static String? validateReminderLeadHours(int hours) {
    if (hours < 1 || hours > 168) {
      return 'Appointment reminder lead time must be between 1 and 168 hours';
    }
    return null;
  }

  int get normalizedAppointmentReminderLeadHours {
    final hours = appointmentReminderLeadHours;
    if (hours < 1 || hours > 168) return defaultAppointmentReminderLeadHours;
    return hours;
  }

  String get formattedAddress {
    final cityState = [city, state].where((part) => part.trim().isNotEmpty).join(', ');
    return [
      if (addressLine.trim().isNotEmpty) addressLine.trim(),
      if (cityState.isNotEmpty) cityState,
      if (zip.trim().isNotEmpty) zip.trim(),
    ].join('\n');
  }

  Map<String, String> get documentVariables => {
        'company_name': companyName,
        'company_phone': phone,
        'company_address': formattedAddress,
        if (logoStoragePath.trim().isNotEmpty) 'company_logo_path': logoStoragePath.trim(),
      };

  CompanySettings copyWith({
    String? companyName,
    String? phone,
    String? addressLine,
    String? city,
    String? state,
    String? zip,
    String? logoStoragePath,
    int? gpsWorkdayStartMinutes,
    int? gpsWorkdayEndMinutes,
    String? gpsTimezone,
    String? gpsTimezoneNote,
    bool? appointmentReminderEnabled,
    int? appointmentReminderLeadHours,
    bool? maintenanceReminderEnabled,
  }) {
    return CompanySettings(
      companyName: companyName ?? this.companyName,
      phone: phone ?? this.phone,
      addressLine: addressLine ?? this.addressLine,
      city: city ?? this.city,
      state: state ?? this.state,
      zip: zip ?? this.zip,
      logoStoragePath: logoStoragePath ?? this.logoStoragePath,
      gpsWorkdayStartMinutes: gpsWorkdayStartMinutes ?? this.gpsWorkdayStartMinutes,
      gpsWorkdayEndMinutes: gpsWorkdayEndMinutes ?? this.gpsWorkdayEndMinutes,
      gpsTimezone: gpsTimezone ?? this.gpsTimezone,
      gpsTimezoneNote: gpsTimezoneNote ?? this.gpsTimezoneNote,
      appointmentReminderEnabled: appointmentReminderEnabled ?? this.appointmentReminderEnabled,
      appointmentReminderLeadHours:
          appointmentReminderLeadHours ?? this.appointmentReminderLeadHours,
      maintenanceReminderEnabled: maintenanceReminderEnabled ?? this.maintenanceReminderEnabled,
    );
  }
}
