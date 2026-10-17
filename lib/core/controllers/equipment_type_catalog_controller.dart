import 'package:flutter/foundation.dart';
import 'package:hvac_admin/core/catalog/equipment_type_catalog_data.dart';
import 'package:hvac_admin/core/models/catalog_option.dart';
import 'package:hvac_admin/data/repositories/customer_repository.dart';

class EquipmentTypeCatalogController extends ChangeNotifier {
  EquipmentTypeCatalogController(this._repository);

  final CustomerRepository _repository;

  List<CatalogOption> _options = EquipmentTypeCatalogData.builtInOptions();
  bool _loading = false;
  bool _loaded = false;

  List<CatalogOption> get options => _options;
  bool get isLoading => _loading;

  Future<void> load({bool force = false}) async {
    if (_loading) return;
    if (_loaded && !force) return;
    _loading = true;
    notifyListeners();
    try {
      _options = await _repository.getEquipmentTypeCatalog();
      _loaded = true;
    } catch (error, stack) {
      debugPrint('EquipmentTypeCatalogController.load failed: $error\n$stack');
      _options = EquipmentTypeCatalogData.builtInOptions();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  String labelFor(String key) {
    for (final option in _options) {
      if (option.key == key) return option.label;
    }
    return EquipmentTypeCatalogData.labelForKey(key);
  }

  Future<CatalogOption> addCustom(String label) async {
    final saved = await _repository.addEquipmentTypeOption(label);
    if (_options.any((option) => option.key == saved.key)) {
      _options = [
        for (final option in _options)
          if (option.key == saved.key) saved else option,
      ];
    } else {
      _options = [..._options, saved]..sort((a, b) => a.label.compareTo(b.label));
    }
    notifyListeners();
    return saved;
  }
}
