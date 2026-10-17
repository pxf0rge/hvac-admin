import 'package:hvac_admin/core/config/app_environment.dart';
import 'package:hvac_admin/core/config/supabase_config.dart';
import 'package:hvac_admin/data/wiring/repository_wiring.dart';

/// Ensures staging/production boots never wire mock domain repositories.
abstract final class ProductionBootGuard {
  ProductionBootGuard._();

  static const _mockTypePrefix = 'Mock';

  /// Call after [RepositoryWiring.create] when Supabase initialized successfully.
  static void validate({
    required HvacAdminRepositoryBundle bundle,
    required bool supabaseConnected,
  }) {
    if (!AppEnvironment.requiresExplicitSupabaseConfig) return;

    if (!supabaseConnected) {
      throw StateError(
        'Production/staging boot requires a live Supabase client. '
        'Pass HVAC_ENV=${AppEnvironment.name} with SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY.',
      );
    }

    if (!SupabaseConfig.isConfigured) {
      throw StateError(
        'SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY are required when HVAC_ENV=${AppEnvironment.name}.',
      );
    }

    final violations = <String>[];
    void check(Object dependency, String label) {
      final type = dependency.runtimeType.toString();
      if (type.startsWith(_mockTypePrefix)) {
        violations.add('$label → $type');
      }
    }

    check(bundle.managementAuth, 'managementAuth');
    check(bundle.customers, 'customers');
    check(bundle.jobs, 'jobs');
    check(bundle.technicians, 'technicians');
    check(bundle.fleet, 'fleet');
    check(bundle.reports, 'reports');
    check(bundle.billing, 'billing');
    check(bundle.communication, 'communication');
    check(bundle.inventory, 'inventory');
    check(bundle.maintenanceAgreements, 'maintenanceAgreements');
    check(bundle.settings, 'settings');
    check(bundle.documentTemplates, 'documentTemplates');
    check(bundle.locations, 'locations');
    check(bundle.realtime, 'realtime');

    if (violations.isNotEmpty) {
      throw StateError(
        'Production boot wired mock dependencies:\n${violations.map((v) => '  • $v').join('\n')}',
      );
    }
  }
}
