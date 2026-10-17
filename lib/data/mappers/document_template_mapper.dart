import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/document_template.dart';
import 'package:hvac_admin/data/mappers/enum_db.dart';
import 'package:hvac_admin/data/mappers/mapper_helpers.dart';

abstract final class DocumentTemplateMapper {
  static ManagedDocumentTemplate fromRows(
    Map<String, dynamic> templateRow,
    List<Map<String, dynamic>> versionRows,
  ) {
    final versions = [
      for (final row in versionRows)
        DocumentTemplateVersion(
          id: MapperHelpers.strOrNull(row['id']),
          version: MapperHelpers.intOrNull(row['version']) ?? 1,
          createdAt: MapperHelpers.isoTimestamp(row['created_at']),
          body: MapperHelpers.str(row['body']),
          fields: fieldsFromJson(row['fields']),
          note: MapperHelpers.str(row['note']),
        ),
    ]..sort((a, b) => a.version.compareTo(b.version));

    return ManagedDocumentTemplate(
      id: MapperHelpers.uuid(templateRow['id']),
      title: MapperHelpers.str(templateRow['title']),
      status: EnumDb.documentTemplateStatusFromDb(MapperHelpers.str(templateRow['status'])),
      lastUpdated: MapperHelpers.isoTimestamp(templateRow['last_updated']),
      versions: versions,
    );
  }

  static List<DocumentFieldDef> fieldsFromJson(dynamic raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map)
          DocumentFieldDef(
            key: MapperHelpers.str(item['key']),
            label: MapperHelpers.str(item['label']),
            required: item['required'] != false,
            autoFillFrom: MapperHelpers.strOrNull(item['auto_fill_from']),
            multiline: item['multiline'] == true,
          ),
    ];
  }

  static List<Map<String, dynamic>> fieldsToJson(List<DocumentFieldDef> fields) => [
        for (final field in fields)
          {
            'key': field.key,
            'label': field.label,
            if (!field.required) 'required': false,
            if (field.autoFillFrom != null) 'auto_fill_from': field.autoFillFrom,
            if (field.multiline) 'multiline': true,
          },
      ];
}
