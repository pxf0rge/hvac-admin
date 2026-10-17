import 'package:hvac_admin/core/models/document_template.dart';

/// Sample values for admin template preview (professional English).
abstract final class DocumentSampleData {
  static const previewValues = <String, String>{
    'customer_name': 'Pat Nguyen',
    'property_address': '77 Oak Lane, Springfield, IL 62704',
    'job_number': 'JOB-RLS-21',
    'service_date': 'Aug 28, 2026',
    'equipment': 'Carrier split · 3 ton',
    'work_summary': 'Replaced failed run capacitor and verified cooling performance.',
    'findings': 'Compressor amp draw within spec after repair.',
    'warranty_term': '12 months parts and labor',
  };

  static Map<String, String> valuesFor(List<DocumentFieldDef> fields) {
    return {
      for (final field in fields)
        field.key: previewValues[field.key] ?? (field.required ? 'Sample ${field.label}' : ''),
    };
  }
}
