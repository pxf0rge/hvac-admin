import 'package:hvac_admin/core/models/maintenance_agreement.dart';

abstract class MaintenanceAgreementRepository {
  Future<List<MaintenanceAgreement>> getAgreements();
  Future<MaintenanceAgreement?> getAgreement(String id);
  Future<MaintenanceAgreement> saveAgreement(MaintenanceAgreement agreement, {double? annualAmount});
}
