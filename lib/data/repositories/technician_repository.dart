import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_directory.dart';

abstract class TechnicianRepository {
  Future<List<OfficeTechnician>> getTechnicians();

  Future<OfficeTechnician?> getTechnician(String id);

  Future<TechnicianDetail> getTechnicianDetail(String id);

  Future<List<TechnicianActivity>> getTechnicianActivity(String technicianId);

  Future<OfficeTechnician> saveTechnician({
    String? id,
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    String? profileId,
    TechnicianStatus status = TechnicianStatus.available,
  });

  Future<OfficeTechnician> setAccountEnabled({required String id, required bool enabled});
}
