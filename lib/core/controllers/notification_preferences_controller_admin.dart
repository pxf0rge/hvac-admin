import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Phase 21: per-user notification preferences (admin/office).
///
/// Same shape as the field app. Missing row = nothing muted; critical
/// job-assign in-app notifications are never suppressed (DB-enforced).
class AdminNotificationPreferences {
  const AdminNotificationPreferences({
    required this.inAppEnabled,
    required this.emailEnabled,
    required this.smsEnabled,
    required this.jobAssign,
    required this.messages,
    required this.reminders,
  });

  final bool inAppEnabled;
  final bool emailEnabled;
  final bool smsEnabled;
  final bool jobAssign;
  final bool messages;
  final bool reminders;

  static const allOn = AdminNotificationPreferences(
    inAppEnabled: true,
    emailEnabled: true,
    smsEnabled: true,
    jobAssign: true,
    messages: true,
    reminders: true,
  );

  factory AdminNotificationPreferences.fromRow(Map<String, dynamic> row) {
    bool flag(Object? v) => v is bool ? v : true;
    return AdminNotificationPreferences(
      inAppEnabled: flag(row['in_app_enabled']),
      emailEnabled: flag(row['email_enabled']),
      smsEnabled: flag(row['sms_enabled']),
      jobAssign: flag(row['job_assign']),
      messages: flag(row['messages']),
      reminders: flag(row['reminders']),
    );
  }

  AdminNotificationPreferences copyWith({
    bool? inAppEnabled,
    bool? emailEnabled,
    bool? smsEnabled,
    bool? jobAssign,
    bool? messages,
    bool? reminders,
  }) {
    return AdminNotificationPreferences(
      inAppEnabled: inAppEnabled ?? this.inAppEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      jobAssign: jobAssign ?? this.jobAssign,
      messages: messages ?? this.messages,
      reminders: reminders ?? this.reminders,
    );
  }
}

class AdminNotificationPreferencesRepository {
  AdminNotificationPreferencesRepository(this._client);

  final SupabaseClient _client;

  Future<AdminNotificationPreferences> load() async {
    try {
      final raw = await _client.rpc('get_my_notification_preferences');
      if (raw is Map) {
        return AdminNotificationPreferences.fromRow(Map<String, dynamic>.from(raw));
      }
      return AdminNotificationPreferences.allOn;
    } catch (error) {
      debugPrint('AdminNotificationPreferencesRepository.load fallback: $error');
      return AdminNotificationPreferences.allOn;
    }
  }

  Future<AdminNotificationPreferences> save(
    AdminNotificationPreferences current, {
    bool? inApp,
    bool? email,
    bool? sms,
    bool? jobAssign,
    bool? messages,
    bool? reminders,
  }) async {
    try {
      final raw = await _client.rpc('upsert_my_notification_preferences', params: {
        'p_in_app_enabled': inApp,
        'p_email_enabled': email,
        'p_sms_enabled': sms,
        'p_job_assign': jobAssign,
        'p_messages': messages,
        'p_reminders': reminders,
      });
      if (raw is Map) {
        return AdminNotificationPreferences.fromRow(Map<String, dynamic>.from(raw));
      }
      return current;
    } catch (error) {
      debugPrint('AdminNotificationPreferencesRepository.save fallback: $error');
      return current.copyWith(
        inAppEnabled: inApp,
        emailEnabled: email,
        smsEnabled: sms,
        jobAssign: jobAssign,
        messages: messages,
        reminders: reminders,
      );
    }
  }
}

class AdminNotificationPreferencesController extends ChangeNotifier {
  AdminNotificationPreferencesController(this._repository);

  final AdminNotificationPreferencesRepository _repository;
  AdminNotificationPreferences _preferences = AdminNotificationPreferences.allOn;
  bool _loading = false;
  bool _saving = false;
  String? _error;

  AdminNotificationPreferences get preferences => _preferences;
  bool get isLoading => _loading;
  bool get isSaving => _saving;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _preferences = await _repository.load();
      _error = null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> update({
    bool? inApp,
    bool? email,
    bool? sms,
    bool? jobAssign,
    bool? messages,
    bool? reminders,
  }) async {
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      _preferences = await _repository.save(
        _preferences,
        inApp: inApp,
        email: email,
        sms: sms,
        jobAssign: jobAssign,
        messages: messages,
        reminders: reminders,
      );
    } catch (e) {
      _error = 'Could not save preferences.';
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
}
