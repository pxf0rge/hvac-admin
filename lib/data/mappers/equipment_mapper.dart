import 'package:hvac_admin/core/catalog/equipment_type_catalog_data.dart';

import 'package:hvac_admin/core/models/office_directory.dart';

import 'package:hvac_admin/data/mappers/mapper_helpers.dart';



abstract final class EquipmentMapper {

  static PropertyEquipment fromRow(

    Map<String, dynamic> row, {

    List<PropertyWarranty> warranties = const [],

    List<NamedRecord> photos = const [],

    List<NamedRecord> manuals = const [],

    List<String> serviceJobIds = const [],

    Map<String, String> typeLabels = const {},

  }) {

    final typeKey = MapperHelpers.str(row['type']);

    return PropertyEquipment(

      id: MapperHelpers.uuid(row['id']),

      propertyId: MapperHelpers.uuid(row['property_id']),

      name: MapperHelpers.str(row['name']),

      manufacturer: MapperHelpers.str(row['manufacturer']),

      model: MapperHelpers.str(row['model']),

      serial: MapperHelpers.str(row['serial']),

      typeKey: typeKey,

      typeLabel: _typeLabelFromRow(row, typeKey, typeLabels),

      capacity: MapperHelpers.str(row['capacity']),

      installedOn: MapperHelpers.dateOnly(row['installed_on']),

      installer: MapperHelpers.str(row['installer']),

      warranties: warranties,

      photos: photos,

      manuals: manuals,

      serviceJobIds: serviceJobIds,

    );

  }



  static String _typeLabelFromRow(

    Map<String, dynamic> row,

    String typeKey,

    Map<String, String> typeLabels,

  ) {

    final nested = row['equipment_type_catalog'];

    if (nested is Map) return MapperHelpers.str(nested['label']);

    final catalogLabel = typeLabels[typeKey];

    if (catalogLabel != null && catalogLabel.isNotEmpty) return catalogLabel;

    return EquipmentTypeCatalogData.labelForKey(typeKey);

  }



  static Map<String, dynamic> toRow(PropertyEquipment equipment) => {

        'id': equipment.id,

        'property_id': equipment.propertyId,

        'name': equipment.name,

        'manufacturer': equipment.manufacturer,

        'model': equipment.model,

        'serial': equipment.serial,

        'type': equipment.typeKey,

        'capacity': equipment.capacity,

        'installed_on': equipment.installedOn.isEmpty ? null : equipment.installedOn,

        'installer': equipment.installer,

      };



  static PropertyWarranty warrantyFromRow(Map<String, dynamic> row) {

    return PropertyWarranty(

      title: MapperHelpers.str(row['title']),

      serial: MapperHelpers.str(row['serial']),

      expiresOn: MapperHelpers.dateOnly(row['expires_on']),

    );

  }



  static Map<String, dynamic> warrantyToRow({

    required String equipmentId,

    required PropertyWarranty warranty,

  }) =>

      {

        'equipment_id': equipmentId,

        'title': warranty.title,

        'serial': warranty.serial,

        'expires_on': warranty.expiresOn,

      };



  static NamedRecord mediaFromRow(Map<String, dynamic> row) {

    return NamedRecord(

      title: MapperHelpers.str(row['title']),

      date: MapperHelpers.dateOnly(row['recorded_on']),

      meta: MapperHelpers.strOrNull(row['meta']),

    );

  }

}


