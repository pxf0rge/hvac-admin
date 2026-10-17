import 'package:hvac_admin/core/audit/audit_actions.dart';

import 'package:hvac_admin/core/audit/audit_metadata.dart';

import 'package:hvac_admin/core/audit/audit_recording.dart';

import 'package:hvac_admin/core/audit/in_memory_audit_log.dart';

import 'package:hvac_admin/core/models/document_template.dart';

import 'package:hvac_admin/data/repositories/document_template_repository.dart';



class MockDocumentTemplateRepository implements DocumentTemplateRepository {

  MockDocumentTemplateRepository(List<ManagedDocumentTemplate> seed, {InMemoryAuditLog? auditLog})

      : _templates = [...seed],

        _auditLog = auditLog;



  final List<ManagedDocumentTemplate> _templates;

  final InMemoryAuditLog? _auditLog;



  @override

  Future<List<ManagedDocumentTemplate>> getTemplates() async => List.unmodifiable(_templates);



  @override

  Future<ManagedDocumentTemplate?> getById(String id) async {

    for (final template in _templates) {

      if (template.id == id) return template;

    }

    return null;

  }



  @override

  Future<List<ManagedDocumentTemplate>> getActiveTemplates() async {

    return [for (final template in _templates) if (template.isActive) template];

  }



  @override

  Future<ManagedDocumentTemplate> save(ManagedDocumentTemplate template) async {

    final index = _templates.indexWhere((item) => item.id == template.id);

    final previous = index >= 0 ? _templates[index] : null;

    if (index < 0) {

      _templates.add(template);

      recordMockAudit(

        _auditLog,

        action: AuditActions.templatePublish,

        entityType: 'document_template',

        entityId: template.id,

        metadata: AuditMetadata.templatePublish(

          templateId: template.id,

          title: template.title,

          version: template.currentVersion,

          note: 'created',

        ),

      );

    } else {

      _templates[index] = template;

      if (previous != null && !previous.isActive && template.isActive) {

        recordMockAudit(

          _auditLog,

          action: AuditActions.templatePublish,

          entityType: 'document_template',

          entityId: template.id,

          metadata: AuditMetadata.templatePublish(

            templateId: template.id,

            title: template.title,

            version: template.currentVersion,

            note: 'activated',

          ),

        );

      } else if (previous != null && template.versions.length > previous.versions.length) {

        recordMockAudit(

          _auditLog,

          action: AuditActions.templatePublish,

          entityType: 'document_template',

          entityId: template.id,

          metadata: AuditMetadata.templatePublish(

            templateId: template.id,

            title: template.title,

            version: template.currentVersion,

            note: 'new_version',

          ),

        );

      }

    }

    return template;

  }

}

