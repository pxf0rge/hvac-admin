import 'package:hvac_admin/core/config/app_environment.dart';

/// Demo login hints for admin — development only.
abstract final class DemoCredentials {
  static bool get showLoginHints => AppEnvironment.isDevelopment;

  static const adminEmail = 'diana@hvacpro.com';
  static const adminPasswordHint = 'OfficeLead!';

  static String get loginHint => '$adminEmail  ·  $adminPasswordHint';
}
