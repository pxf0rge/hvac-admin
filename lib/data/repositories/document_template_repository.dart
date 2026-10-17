import 'package:hvac_admin/core/models/document_template.dart';

abstract class DocumentTemplateRepository {
  Future<List<ManagedDocumentTemplate>> getTemplates();
  Future<ManagedDocumentTemplate?> getById(String id);
  Future<List<ManagedDocumentTemplate>> getActiveTemplates();
  Future<ManagedDocumentTemplate> save(ManagedDocumentTemplate template);
}
