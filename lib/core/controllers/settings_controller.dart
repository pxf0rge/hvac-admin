import 'package:flutter/foundation.dart';
import 'package:hvac_admin/core/models/company_settings.dart';
import 'package:hvac_admin/core/models/integration_credentials.dart';
import 'package:hvac_admin/core/models/office_user.dart';
import 'package:hvac_admin/data/repositories/settings_repository.dart';

class SettingsController extends ChangeNotifier {
  SettingsController(this._repository);

  final SettingsRepository _repository;
  CompanySettings? _company;
  IntegrationCredentials? _integrations;
  List<OfficeUser> _officeUsers = const [];
  bool _loading = false;
  bool _saving = false;
  bool _savingIntegrations = false;
  String? _error;

  bool get isLoading => _loading;
  bool get isSaving => _saving;
  bool get isSavingIntegrations => _savingIntegrations;
  String? get error => _error;
  CompanySettings? get company => _company;
  IntegrationCredentials? get integrations => _integrations;
  List<OfficeUser> get officeUsers => List.unmodifiable(_officeUsers);

  Map<String, String> get documentVariables => _company?.documentVariables ?? const {};

  Future<void> load({bool force = false}) async {
    if (!force && _company != null && _officeUsers.isNotEmpty) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _repository.getCompanySettings(),
        _repository.getOfficeUsers(),
        _repository.getIntegrationCredentials(),
      ]);
      _company = results[0] as CompanySettings;
      _officeUsers = results[1] as List<OfficeUser>;
      _integrations = results[2] as IntegrationCredentials;
    } catch (error, stack) {
      _error = error.toString();
      debugPrint('SettingsController.load failed: $error\n$stack');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> saveCompany(CompanySettings settings, {required bool canEdit}) async {
    if (!canEdit) return false;
    _saving = true;
    _error = null;
    notifyListeners();
    try {
      _company = await _repository.saveCompanySettings(settings);
      return true;
    } catch (error, stack) {
      _error = error.toString();
      debugPrint('SettingsController.saveCompany failed: $error\n$stack');
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<bool> saveIntegrations(
    IntegrationCredentials credentials, {
    required bool canEdit,
  }) async {
    if (!canEdit) return false;
    _savingIntegrations = true;
    _error = null;
    notifyListeners();
    try {
      _integrations = await _repository.saveIntegrationCredentials(credentials);
      return true;
    } catch (error, stack) {
      _error = error.toString();
      debugPrint('SettingsController.saveIntegrations failed: $error\n$stack');
      return false;
    } finally {
      _savingIntegrations = false;
      notifyListeners();
    }
  }
}
