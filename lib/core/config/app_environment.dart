/// Build-time environment selection via `--dart-define=HVAC_ENV=...`.
enum HvacEnvironment {
  development,
  staging,
  production;

  static HvacEnvironment parse(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'prod':
      case 'production':
        return HvacEnvironment.production;
      case 'staging':
      case 'stage':
        return HvacEnvironment.staging;
      default:
        return HvacEnvironment.development;
    }
  }
}

class AppEnvironment {
  AppEnvironment._();

  static const String name = String.fromEnvironment('HVAC_ENV', defaultValue: 'development');

  static HvacEnvironment get current => HvacEnvironment.parse(name);

  static bool get isProduction => current == HvacEnvironment.production;
  static bool get isStaging => current == HvacEnvironment.staging;
  static bool get isDevelopment => current == HvacEnvironment.development;

  /// Staging and production must pass Supabase URL + publishable key via dart-define.
  static bool get requiresExplicitSupabaseConfig => isStaging || isProduction;
}
