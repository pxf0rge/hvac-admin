import 'package:hvac_admin/core/config/app_environment.dart';

/// Supabase client config. Staging/production builds must pass URL + publishable key via dart-define.
class SupabaseConfig {
  static const _urlOverride = String.fromEnvironment('SUPABASE_URL');
  static const _keyOverride = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// Dev-only defaults so local `flutter run` works without dart-defines.
  /// Same shared dev project as [hvac_client]. Never used when
  /// [AppEnvironment.requiresExplicitSupabaseConfig] is true.
  static const _devUrl = 'https://zzmhomajzyqoibgqiymg.supabase.co';
  static const _devPublishableKey = 'sb_publishable_SZoGuleNX_W21iFkV1ZrNA_A_lJC4D4';

  static String get url {
    if (_urlOverride.isNotEmpty) return _urlOverride;
    if (AppEnvironment.requiresExplicitSupabaseConfig) {
      throw StateError(_missingDefineMessage('SUPABASE_URL'));
    }
    return _devUrl;
  }

  static String get publishableKey {
    if (_keyOverride.isNotEmpty) return _keyOverride;
    if (AppEnvironment.requiresExplicitSupabaseConfig) {
      throw StateError(_missingDefineMessage('SUPABASE_PUBLISHABLE_KEY'));
    }
    return _devPublishableKey;
  }

  /// Hostname only — safe for boot logs (no keys, no query params).
  static String? get host {
    try {
      return Uri.parse(url).host;
    } catch (_) {
      return null;
    }
  }

  static bool get isConfigured {
    try {
      return url.isNotEmpty && publishableKey.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static String _missingDefineMessage(String define) {
    final env = AppEnvironment.name;
    return '$define is required when HVAC_ENV=$env '
        '(pass --dart-define=$define=...).';
  }
}
