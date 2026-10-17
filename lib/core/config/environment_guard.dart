import 'package:hvac_admin/core/config/app_environment.dart';

/// Guards against pointing staging/production builds at the wrong Supabase project.
abstract final class EnvironmentGuard {
  EnvironmentGuard._();

  /// Public ref for the embedded development Supabase project (local `flutter run` only).
  static const devProjectRef = 'zzmhomajzyqoibgqiymg';

  /// Optional compile-time allowlist: `SUPABASE_URL` host must match this ref.
  static const expectedProjectRef = String.fromEnvironment('SUPABASE_PROJECT_REF');

  /// Optional cross-check refs (set in CI for staging/production pipelines).
  static const stagingProjectRef = String.fromEnvironment('STAGING_PROJECT_REF');
  static const productionProjectRef = String.fromEnvironment('PRODUCTION_PROJECT_REF');

  static const demoUserEmails = [
    'diana@hvacpro.com',
    'carlos@hvacpro.com',
  ];

  static String? projectRefFromUrl(String url) {
    final host = Uri.tryParse(url)?.host ?? '';
    if (!host.endsWith('.supabase.co')) return null;
    final ref = host.split('.').first;
    return ref.isEmpty ? null : ref;
  }

  static void validateSupabaseTarget({
    required String url,
    required HvacEnvironment environment,
  }) {
    if (environment == HvacEnvironment.development) return;

    final host = Uri.tryParse(url)?.host ?? '';
    if (host.contains(devProjectRef)) {
      throw StateError(
        '${environment.name} cannot use the shared development Supabase project ($devProjectRef). '
        'Provision a dedicated Supabase project — see docs/backups-and-migration.md.',
      );
    }
    if (host.isEmpty || !host.endsWith('.supabase.co')) {
      throw StateError('SUPABASE_URL must be a valid https://<ref>.supabase.co URL.');
    }

    final ref = projectRefFromUrl(url);
    if (ref == null) {
      throw StateError('Could not parse Supabase project ref from SUPABASE_URL.');
    }

    validateProjectRefRules(
      environment: environment,
      projectRef: ref,
      expectedProjectRef: expectedProjectRef,
      stagingProjectRef: stagingProjectRef,
      productionProjectRef: productionProjectRef,
    );
  }

  /// Pure rules used at boot and in unit tests (inject refs explicitly).
  static void validateProjectRefRules({
    required HvacEnvironment environment,
    required String projectRef,
    String expectedProjectRef = '',
    String stagingProjectRef = '',
    String productionProjectRef = '',
  }) {
    if (expectedProjectRef.isNotEmpty && projectRef != expectedProjectRef) {
      throw StateError(
        'SUPABASE_URL points at $projectRef but SUPABASE_PROJECT_REF=$expectedProjectRef. '
        'Fix dart-defines for ${environment.name}.',
      );
    }

    if (environment == HvacEnvironment.production &&
        stagingProjectRef.isNotEmpty &&
        projectRef == stagingProjectRef) {
      throw StateError(
        'Production build cannot target the staging Supabase project ($stagingProjectRef).',
      );
    }

    if (environment == HvacEnvironment.staging &&
        productionProjectRef.isNotEmpty &&
        projectRef == productionProjectRef) {
      throw StateError(
        'Staging build cannot target the production Supabase project ($productionProjectRef).',
      );
    }

    if (environment == HvacEnvironment.production &&
        productionProjectRef.isNotEmpty &&
        projectRef != productionProjectRef) {
      throw StateError(
        'Production build must use production project $productionProjectRef (got $projectRef).',
      );
    }

    if (environment == HvacEnvironment.staging &&
        stagingProjectRef.isNotEmpty &&
        projectRef != stagingProjectRef) {
      throw StateError(
        'Staging build must use staging project $stagingProjectRef (got $projectRef).',
      );
    }
  }
}
