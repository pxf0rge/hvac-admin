import 'package:hvac_admin/core/models/catalog_option.dart';

abstract final class EquipmentTypeCatalogData {
  static const builtInLabels = <String, String>{
    'central_ac': 'Central AC',
    'heat_pump': 'Heat Pump',
    'furnace': 'Furnace',
    'mini_split': 'Mini Split',
    'air_handler': 'Air Handler',
    'condenser': 'Condenser',
    'package_unit': 'Package Unit',
  };

  static List<CatalogOption> builtInOptions() => [
        for (final entry in builtInLabels.entries)
          CatalogOption(key: entry.key, label: entry.value, isSystem: true),
      ];

  static String labelForKey(String key) {
    final builtIn = builtInLabels[key];
    if (builtIn != null) return builtIn;
    if (key.startsWith('custom_')) {
      return _humanize(key.substring('custom_'.length));
    }
    return _humanize(key);
  }

  static String _humanize(String value) {
    final cleaned = value.replaceAll('_', ' ').trim();
    if (cleaned.isEmpty) return 'Custom type';
    return cleaned.split(' ').map((part) {
      if (part.isEmpty) return part;
      return '${part[0].toUpperCase()}${part.substring(1)}';
    }).join(' ');
  }
}
