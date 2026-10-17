import 'package:hvac_admin/core/models/fleet_asset.dart';

abstract class FleetRepository {
  Future<List<FleetAsset>> getAssets();

  Future<List<FleetAssignment>> getAssignmentHistory(String fleetAssetId);

  Future<FleetAsset> saveAsset(FleetAsset asset);

  Future<FleetAsset> assignAsset({
    required String fleetAssetId,
    required String technicianId,
    String notes = '',
  });

  Future<FleetAsset> unassignAsset({required String fleetAssetId, String notes = ''});
}
