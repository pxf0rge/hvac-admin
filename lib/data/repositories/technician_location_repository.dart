import 'package:hvac_admin/core/tracking/technician_location_fix.dart';

abstract class TechnicianLocationRepository {
  Future<List<TechnicianLocationFix>> historyFor(String technicianId, {int limit = 40});
}
