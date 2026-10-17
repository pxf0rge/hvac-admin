import 'package:flutter/foundation.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/data/pagination/paged_result.dart';
import 'package:hvac_admin/data/repositories/customer_repository.dart';

class CustomerController extends ChangeNotifier {
  CustomerController(this._repository);

  final CustomerRepository _repository;

  bool _loading = false;
  String? _loadError;
  List<OfficeCustomer> _customers = const [];
  List<OfficeProperty> _properties = const [];
  final Map<String, PropertyEquipment> _equipmentById = {};
  int _refreshToken = 0;

  bool get isLoading => _loading;
  String? get loadError => _loadError;
  List<OfficeCustomer> get customers => _customers;
  List<OfficeProperty> get properties => _properties;
  int get refreshToken => _refreshToken;

  OfficeCustomer? customerById(String id) {
    for (final customer in _customers) {
      if (customer.id == id) return customer;
    }
    return null;
  }

  OfficeProperty? propertyById(String id) {
    for (final property in _properties) {
      if (property.id == id) return property;
    }
    return null;
  }

  PropertyEquipment? equipmentById(String id) => _equipmentById[id];

  HistoryJob? historyJobById(String jobId) {
    for (final history in _history.values) {
      for (final job in history.jobs) {
        if (job.id == jobId) return job;
      }
    }
    return null;
  }

  List<OfficeProperty> propertiesForCustomer(String customerId) {
    return [for (final property in _properties) if (property.customerId == customerId) property];
  }

  final Map<String, PropertyHistory> _history = {};

  PropertyHistory historyFor(String propertyId) => _history[propertyId] ?? PropertyHistory.empty;

  Future<PropertyHistory> loadPropertyHistory(String propertyId) async {
    final history = await _repository.getPropertyHistory(propertyId);
    _history[propertyId] = history;
    for (final unit in history.equipment) {
      _equipmentById[unit.id] = unit;
    }
    notifyListeners();
    return history;
  }

  Future<void> load({bool force = false}) async {
    if (_loading) return;
    if (!force && _customers.isNotEmpty && _properties.isNotEmpty && _loadError == null) return;

    _loading = true;
    _loadError = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getCustomers(),
        _repository.getProperties(),
      ]);
      _customers = results[0] as List<OfficeCustomer>;
      _properties = results[1] as List<OfficeProperty>;
      if (force) _refreshToken += 1;
    } catch (error, stack) {
      debugPrint('CustomerController.load failed: $error\n$stack');
      _loadError = 'Could not load CRM data.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshFromRemote() => load(force: true);

  Future<PagedResult<OfficeCustomer>> fetchCustomersPage({
    required int offset,
    String? search,
  }) =>
      _repository.getCustomersPage(offset: offset, search: search);

  Future<PagedResult<OfficeProperty>> fetchPropertiesPage({
    required int offset,
    String? search,
  }) =>
      _repository.getPropertiesPage(offset: offset, search: search);

  Future<PagedResult<PropertyEquipment>> fetchEquipmentPage({
    required int offset,
    String? search,
    String? propertyId,
    String? typeKey,
    WarrantyFilter warrantyFilter = WarrantyFilter.any,
  }) async {
    final page = await _repository.getEquipmentPage(
      offset: offset,
      search: search,
      propertyId: propertyId,
      typeKey: typeKey,
      warrantyFilter: warrantyFilter,
    );
    for (final unit in page.items) {
      _equipmentById[unit.id] = unit;
    }
    return page;
  }

  Future<PagedResult<WarrantyArchiveEntry>> fetchWarrantyArchivePage({
    required int offset,
    String? search,
  }) =>
      _repository.searchWarranties(offset: offset, search: search);

  Future<OfficeCustomer> saveCustomer(OfficeCustomer customer) async {
    final saved = await _repository.saveCustomer(customer);
    final index = _customers.indexWhere((item) => item.id == saved.id);
    if (index >= 0) {
      _customers = [..._customers]..[index] = saved;
    } else {
      _customers = [..._customers, saved];
    }
    _refreshToken += 1;
    notifyListeners();
    return saved;
  }

  Future<OfficeProperty> saveProperty(OfficeProperty property) async {
    final saved = await _repository.saveProperty(property);
    final index = _properties.indexWhere((item) => item.id == saved.id);
    if (index >= 0) {
      _properties = [..._properties]..[index] = saved;
    } else {
      _properties = [..._properties, saved];
    }
    _history.remove(saved.id);
    _refreshToken += 1;
    notifyListeners();
    return saved;
  }

  Future<PropertyEquipment> saveEquipment(PropertyEquipment equipment) async {
    final saved = await _repository.saveEquipment(equipment);
    _equipmentById[saved.id] = saved;
    _history.remove(saved.propertyId);
    _refreshToken += 1;
    notifyListeners();
    return saved;
  }

  Future<PropertyWarranty> saveWarranty({
    required String equipmentId,
    required PropertyWarranty warranty,
  }) async {
    final saved = await _repository.saveWarranty(equipmentId: equipmentId, warranty: warranty);
    final unit = _equipmentById[equipmentId] ?? await _repository.getEquipmentById(equipmentId);
    if (unit != null) {
      final updated = unit.copyWith(warranties: [...unit.warranties, saved]);
      _equipmentById[equipmentId] = updated;
      _history.remove(unit.propertyId);
    }
    _refreshToken += 1;
    notifyListeners();
    return saved;
  }

  Future<OfficeCustomer?> ensureCustomerLoaded(String id) async {
    var customer = customerById(id);
    if (customer != null) return customer;
    customer = await _repository.getCustomer(id);
    if (customer == null) return null;
    final index = _customers.indexWhere((item) => item.id == customer!.id);
    if (index >= 0) {
      _customers = [..._customers]..[index] = customer;
    } else {
      _customers = [..._customers, customer];
    }
    final remoteProperties = await _repository.getPropertiesForCustomer(id);
    final byId = {for (final property in _properties) property.id: property};
    for (final property in remoteProperties) {
      byId[property.id] = property;
    }
    _properties = byId.values.toList();
    notifyListeners();
    return customer;
  }

  Future<OfficeProperty?> ensurePropertyLoaded(String id) async {
    var property = propertyById(id);
    if (property != null) return property;
    property = await _repository.getProperty(id);
    if (property == null) return null;
    final index = _properties.indexWhere((item) => item.id == property!.id);
    if (index >= 0) {
      _properties = [..._properties]..[index] = property;
    } else {
      _properties = [..._properties, property];
    }
    await ensureCustomerLoaded(property.customerId);
    notifyListeners();
    return property;
  }

  Future<PropertyEquipment?> ensureEquipmentLoaded(String id) async {
    var unit = equipmentById(id);
    if (unit != null) return unit;
    unit = await _repository.getEquipmentById(id);
    if (unit == null) return null;
    _equipmentById[id] = unit;
    await ensurePropertyLoaded(unit.propertyId);
    await loadPropertyHistory(unit.propertyId);
    notifyListeners();
    return unit;
  }
}
