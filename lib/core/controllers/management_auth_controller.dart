import 'package:flutter/foundation.dart';
import 'package:hvac_admin/core/audit/audit_session_holder.dart';
import 'package:hvac_admin/core/auth/management_sign_in_result.dart';
import 'package:hvac_admin/core/auth/permission_service.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/enums/user_role.dart';
import 'package:hvac_admin/core/models/management_session.dart';
import 'package:hvac_admin/data/datasources/management_auth_service.dart';

abstract class ManagementAuthController extends ChangeNotifier {
  bool get isAuthenticated;
  bool get isBusy;
  ManagementSession? get session;
  UserRole? get role;
  ManagementSignInError? get lastSignInError;
  bool get canViewFinancials;

  bool canOpen(AdminModule module);
  Future<bool> signIn({required String email, required String password});
  Future<void> signOut();
  Future<void> restore();
  void clearSession();
}

class AppManagementAuthController extends ManagementAuthController {
  AppManagementAuthController(this._service);

  final ManagementAuthService _service;
  ManagementSession? _session;
  bool _busy = false;
  ManagementSignInError? _lastSignInError;

  @override
  bool get isAuthenticated => _session != null;

  @override
  bool get isBusy => _busy;

  @override
  ManagementSession? get session => _session;

  @override
  UserRole? get role => _session?.role;

  @override
  ManagementSignInError? get lastSignInError => _lastSignInError;

  @override
  bool get canViewFinancials => _session?.canViewFinancials ?? false;

  @override
  bool canOpen(AdminModule module) => PermissionService.canOpenModule(role, module);

  @override
  Future<bool> signIn({required String email, required String password}) async {
    _busy = true;
    _lastSignInError = null;
    notifyListeners();
    try {
      final result = await _service.signIn(email: email, password: password);
      _session = result.session;
      AuditSessionHolder.session = _session;
      _lastSignInError = result.error;
      return _session != null;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  Future<void> signOut() async {
    await _service.signOut();
    _session = null;
    AuditSessionHolder.session = null;
    _lastSignInError = null;
    notifyListeners();
  }

  @override
  Future<void> restore() async {
    _session = await _service.restore();
    AuditSessionHolder.session = _session;
    notifyListeners();
  }

  @override
  void clearSession() {
    if (_session == null) return;
    _session = null;
    AuditSessionHolder.session = null;
    _lastSignInError = null;
    notifyListeners();
  }
}
