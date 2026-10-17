import 'package:hvac_admin/core/config/app_environment.dart';
import 'package:hvac_admin/core/config/environment_guard.dart';
import 'package:hvac_admin/core/config/supabase_config.dart';
import 'package:hvac_admin/core/logging/hvac_log.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HvacSupabase {
  static Future<SupabaseClient> initialize() async {
    final url = SupabaseConfig.url;
    EnvironmentGuard.validateSupabaseTarget(url: url, environment: AppEnvironment.current);
    HvacLog.info('app.boot', fields: {
      'env': AppEnvironment.name,
      'supabase_configured': SupabaseConfig.isConfigured,
      if (SupabaseConfig.host != null) 'supabase_host': SupabaseConfig.host,
    });
    await Supabase.initialize(
      url: url,
      publishableKey: SupabaseConfig.publishableKey,
    );
    return Supabase.instance.client;
  }
}
