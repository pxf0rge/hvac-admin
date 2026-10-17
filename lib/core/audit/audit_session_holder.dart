import 'package:hvac_admin/core/models/management_session.dart';

/// Current management session for mock audit actor attribution.
abstract final class AuditSessionHolder {
  static ManagementSession? session;
}
