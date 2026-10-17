import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/catalog_option.dart';
import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/data/pagination/paged_result.dart';

abstract class CustomerRepository {
  Future<List<OfficeCustomer>> getCustomers();
  Future<PagedResult<OfficeCustomer>> getCustomersPage({
    int offset = 0,
    int limit = ListQuery.defaultLimit,
    String? search,
  });
  Future<OfficeCustomer?> getCustomer(String id);
  Future<OfficeCustomer> saveCustomer(OfficeCustomer customer);

  Future<List<OfficeProperty>> getProperties();
  Future<PagedResult<OfficeProperty>> getPropertiesPage({
    int offset = 0,
    int limit = ListQuery.defaultLimit,
    String? search,
  });
  Future<List<OfficeProperty>> getPropertiesForCustomer(String customerId);
  Future<OfficeProperty?> getProperty(String id);
  Future<OfficeProperty> saveProperty(OfficeProperty property);

  Future<List<PropertyEquipment>> getEquipmentForProperty(String propertyId);
  Future<PagedResult<PropertyEquipment>> getEquipmentPage({
    int offset = 0,
    int limit = ListQuery.defaultLimit,
    String? search,
    String? propertyId,
    String? typeKey,
    WarrantyFilter warrantyFilter = WarrantyFilter.any,
  });
  Future<List<CatalogOption>> getEquipmentTypeCatalog();
  Future<CatalogOption> addEquipmentTypeOption(String label);
  Future<PropertyEquipment?> getEquipmentById(String id);
  Future<PropertyEquipment> saveEquipment(PropertyEquipment equipment);
  Future<PropertyWarranty> saveWarranty({
    required String equipmentId,
    required PropertyWarranty warranty,
  });
  Future<PagedResult<WarrantyArchiveEntry>> searchWarranties({
    int offset = 0,
    int limit = ListQuery.defaultLimit,
    String? search,
  });

  Future<PropertyHistory> getPropertyHistory(String propertyId);
}
