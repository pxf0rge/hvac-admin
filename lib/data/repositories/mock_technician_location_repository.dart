import 'package:hvac_admin/core/tracking/technician_location_fix.dart';
import 'package:hvac_admin/data/datasources/mock_seed_data.dart';
import 'package:hvac_admin/data/repositories/technician_location_repository.dart';

class MockTechnicianLocationRepository implements TechnicianLocationRepository {
  MockTechnicianLocationRepository({Map<String, List<TechnicianLocationFix>>? seed})
      : _byTech = seed ?? _defaultSeed();

  final Map<String, List<TechnicianLocationFix>> _byTech;

  static Map<String, List<TechnicianLocationFix>> _defaultSeed() {
    final now = DateTime.now();
    return {
      MockSeedIds.technicianId: [
        TechnicianLocationFix(
          technicianId: MockSeedIds.technicianId,
          latitude: 39.7817,
          longitude: -89.6501,
          recordedAt: now.subtract(const Duration(minutes: 4)),
          lastAddress: 'Near 77 Oak Lane',
          jobId: MockSeedIds.todayJobId,
        ),
        TechnicianLocationFix(
          technicianId: MockSeedIds.technicianId,
          latitude: 39.7805,
          longitude: -89.6488,
          recordedAt: now.subtract(const Duration(minutes: 18)),
          lastAddress: 'Springfield, IL',
        ),
      ],
    };
  }

  @override
  Future<List<TechnicianLocationFix>> historyFor(String technicianId, {int limit = 40}) async {
    final list = _byTech[technicianId] ?? const [];
    if (list.length <= limit) return List.unmodifiable(list);
    return List.unmodifiable(list.take(limit));
  }
}
