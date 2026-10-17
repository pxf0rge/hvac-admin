import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/controllers/document_template_controller.dart';
import 'package:hvac_admin/core/documents/document_renderer.dart';
import 'package:hvac_admin/core/documents/document_sample_data.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/document_template.dart';
import 'package:hvac_admin/data/datasources/mock_document_templates.dart';
import 'package:hvac_admin/data/mappers/document_template_mapper.dart';
import 'package:hvac_admin/data/repositories/mock_document_template_repository.dart';

void main() {
  test('MockDocumentTemplateRepository seeds office templates', () async {
    final repo = MockDocumentTemplateRepository(MockDocumentTemplates.seedLibrary());
    final templates = await repo.getTemplates();
    expect(templates.length, greaterThanOrEqualTo(9));
    expect(templates.any((item) => item.title == 'Service Authorization'), isTrue);
    final serviceAuth = templates.firstWhere((item) => item.id == MockDocumentTemplates.serviceAuthorizationId);
    expect(serviceAuth.currentVersion, 2);
    expect(serviceAuth.isActive, isTrue);
  });

  test('DocumentTemplateMapper round-trips field JSON', () {
    const fields = [MockDocumentTemplates.customerName, MockDocumentTemplates.jobNumber];
    final json = DocumentTemplateMapper.fieldsToJson(fields);
    final parsed = DocumentTemplateMapper.fieldsFromJson(json);
    expect(parsed.length, 2);
    expect(parsed.first.key, 'customer_name');
    expect(parsed.last.autoFillFrom, 'jobNumber');
  });

  test('DocumentRenderer substitutes sample preview values', () {
    const fields = [MockDocumentTemplates.customerName, MockDocumentTemplates.propertyAddress];
    final rendered = DocumentRenderer.render(
      body: 'Customer {{customer_name}} at {{property_address}}.',
      fields: fields,
      fieldValues: DocumentSampleData.valuesFor(fields),
    );
    expect(rendered, contains('Pat Nguyen'));
    expect(rendered, contains('77 Oak Lane'));
  });

  test('DocumentRenderer merges global company variables', () {
    final rendered = DocumentRenderer.render(
      body: 'Prepared by {{company_name}} — {{company_phone}}',
      fields: const [],
      fieldValues: const {},
      globalVariables: const {
        'company_name': 'Arctic HVAC Solutions',
        'company_phone': '(217) 555-0100',
      },
    );
    expect(rendered, contains('Arctic HVAC Solutions'));
    expect(rendered, contains('(217) 555-0100'));
  });

  test('DocumentTemplateController publishes new version without replacing old', () async {
    final repo = MockDocumentTemplateRepository(MockDocumentTemplates.seedLibrary());
    final controller = DocumentTemplateController(repo);
    await controller.load();

    final before = controller.templateById(MockDocumentTemplates.serviceAuthorizationId)!;
    expect(before.versions.length, 2);

    await controller.saveNewVersion(
      id: before.id,
      title: before.title,
      body: '${before.current.body}\n\nUpdated clause.',
      fields: before.current.fields,
      note: 'Test publish',
    );

    final after = controller.templateById(before.id)!;
    expect(after.versions.length, 3);
    expect(after.currentVersion, 3);
    expect(after.versions.first.version, 1);
    expect(after.versions.first.body, isNot(after.current.body));
    expect(after.current.note, 'Test publish');
  });

  test('DocumentTemplateController toggles active status', () async {
    final repo = MockDocumentTemplateRepository(MockDocumentTemplates.seedLibrary());
    final controller = DocumentTemplateController(repo);
    await controller.load();

    final template = controller.templateById('tpl_maintenance_agreement');
    expect(template?.status, DocumentTemplateStatus.draft);

    await controller.toggleActive('tpl_maintenance_agreement');
    expect(controller.templateById('tpl_maintenance_agreement')?.isActive, isTrue);
  });
}
