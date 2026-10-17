import 'package:hvac_admin/core/models/document_template.dart';

/// Substitutes `{{field_key}}` placeholders with field values.
abstract final class DocumentRenderer {
  static String render({
    required String body,
    required List<DocumentFieldDef> fields,
    required Map<String, String> fieldValues,
    Map<String, String> globalVariables = const {},
    String blank = '______',
  }) {
    var text = body;
    for (final entry in globalVariables.entries) {
      final value = entry.value.trim();
      text = text.replaceAll(
        '{{${entry.key}}}',
        value.isEmpty ? blank : value,
      );
    }
    for (final field in fields) {
      final value = fieldValues[field.key]?.trim();
      text = text.replaceAll(
        '{{${field.key}}}',
        (value == null || value.isEmpty) ? blank : value,
      );
    }
    text = text.replaceAll(RegExp(r'\{\{[a-z0-9_]+\}\}'), blank);
    return text.trim();
  }
}
