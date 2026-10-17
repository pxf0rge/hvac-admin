import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/document_template.dart';

/// Customer-facing templates stay in professional English.
abstract final class MockDocumentTemplates {
  static const customerName = DocumentFieldDef(
    key: 'customer_name',
    label: 'Customer name',
    autoFillFrom: 'customerName',
  );
  static const propertyAddress = DocumentFieldDef(
    key: 'property_address',
    label: 'Property address',
    autoFillFrom: 'fullAddress',
  );
  static const jobNumber = DocumentFieldDef(
    key: 'job_number',
    label: 'Job number',
    autoFillFrom: 'jobNumber',
  );
  static const serviceDate = DocumentFieldDef(
    key: 'service_date',
    label: 'Service date',
    autoFillFrom: 'scheduledDate',
  );
  static const equipment = DocumentFieldDef(
    key: 'equipment',
    label: 'Equipment',
    autoFillFrom: 'equipment',
    required: false,
  );
  static const workSummary = DocumentFieldDef(
    key: 'work_summary',
    label: 'Work summary',
    autoFillFrom: 'description',
    multiline: true,
  );
  static const findings = DocumentFieldDef(
    key: 'findings',
    label: 'Findings / notes',
    multiline: true,
  );
  static const warrantyTerm = DocumentFieldDef(
    key: 'warranty_term',
    label: 'Warranty term',
    required: false,
  );

  static const fieldCatalog = [
    customerName,
    propertyAddress,
    jobNumber,
    serviceDate,
    equipment,
    workSummary,
    findings,
    warrantyTerm,
  ];

  static const serviceAuthorizationId = 'tpl_service_authorization';

  static List<ManagedDocumentTemplate> seedLibrary() {
    return [
      _managed(
        id: serviceAuthorizationId,
        title: 'Service Authorization',
        body: '''
I, {{customer_name}}, authorize Arctic HVAC Solutions to perform service at {{property_address}} for job {{job_number}} on {{service_date}}.

Equipment on file: {{equipment}}

I understand diagnostic fees and authorized repair charges may apply.
''',
        fields: const [customerName, propertyAddress, jobNumber, serviceDate, equipment],
        multiVersion: true,
        lastUpdated: '2026-08-22T11:00:00',
      ),
      _managed(
        id: 'tpl_diagnostic_consent',
        title: 'Diagnostic Consent',
        body: '''
Customer {{customer_name}} consents to diagnostic evaluation of HVAC equipment at {{property_address}}.

Job: {{job_number}}
Scheduled: {{service_date}}
Equipment: {{equipment}}

Findings: {{findings}}
''',
        fields: const [customerName, propertyAddress, jobNumber, serviceDate, equipment, findings],
      ),
      _managed(
        id: 'tpl_responsibility_release',
        title: 'Responsibility / Release',
        body: '''
{{customer_name}} acknowledges responsibility for access, utilities, and pets at {{property_address}} during service on {{service_date}} ({{job_number}}).

Work summary: {{work_summary}}
''',
        fields: const [customerName, propertyAddress, serviceDate, jobNumber, workSummary],
      ),
      _managed(
        id: 'tpl_completion_form',
        title: 'Completion Form',
        body: '''
Service for job {{job_number}} at {{property_address}} is complete as of {{service_date}}.

Customer: {{customer_name}}
Equipment: {{equipment}}
Work performed: {{work_summary}}
''',
        fields: const [jobNumber, propertyAddress, serviceDate, customerName, equipment, workSummary],
      ),
      _managed(
        id: 'tpl_installation_agreement',
        title: 'Installation Agreement',
        body: '''
{{customer_name}} agrees to installation services at {{property_address}} under job {{job_number}} on {{service_date}}.

Equipment: {{equipment}}
Scope: {{work_summary}}
''',
        fields: const [customerName, propertyAddress, jobNumber, serviceDate, equipment, workSummary],
      ),
      _managed(
        id: 'tpl_equipment_acceptance',
        title: 'Equipment Acceptance',
        body: '''
{{customer_name}} accepts delivery/condition of equipment {{equipment}} at {{property_address}} for job {{job_number}}.

Notes: {{findings}}
''',
        fields: const [customerName, equipment, propertyAddress, jobNumber, findings],
      ),
      _managed(
        id: 'tpl_installation_completion',
        title: 'Installation Completion',
        body: '''
Installation for job {{job_number}} is complete. Customer {{customer_name}} confirms work at {{property_address}} on {{service_date}}.

Equipment: {{equipment}}
Summary: {{work_summary}}
''',
        fields: const [jobNumber, customerName, propertyAddress, serviceDate, equipment, workSummary],
      ),
      _managed(
        id: 'tpl_warranty_registration',
        title: 'Warranty Registration',
        body: '''
Warranty registration for {{equipment}} at {{property_address}}.

Customer: {{customer_name}}
Job: {{job_number}}
Service date: {{service_date}}
Warranty term: {{warranty_term}}
''',
        fields: const [equipment, propertyAddress, customerName, jobNumber, serviceDate, warrantyTerm],
      ),
      _managed(
        id: 'tpl_maintenance_agreement',
        title: 'Maintenance Agreement',
        body: '''
{{customer_name}} enrolls the property at {{property_address}} in a maintenance plan covering {{equipment}}.

Job reference: {{job_number}}
Start date: {{service_date}}
Notes: {{findings}}
''',
        fields: const [customerName, propertyAddress, equipment, jobNumber, serviceDate, findings],
        status: DocumentTemplateStatus.draft,
      ),
    ];
  }

  static ManagedDocumentTemplate _managed({
    required String id,
    required String title,
    required String body,
    required List<DocumentFieldDef> fields,
    DocumentTemplateStatus status = DocumentTemplateStatus.active,
    String lastUpdated = '2026-08-20T09:15:00',
    bool multiVersion = false,
  }) {
    final initial = DocumentTemplateVersion(
      version: 1,
      createdAt: '2026-08-01T08:00:00',
      body: body,
      fields: fields,
      note: 'Initial office template',
    );
    final versions = multiVersion
        ? [
            initial.copyWith(
              body: body.replaceAll('may apply.', 'may apply pending office approval.'),
            ),
            DocumentTemplateVersion(
              version: 2,
              createdAt: '2026-08-22T11:00:00',
              body: body,
              fields: fields,
              note: 'Clarified diagnostic fee language',
            ),
          ]
        : [initial];
    return ManagedDocumentTemplate(
      id: id,
      title: title,
      status: status,
      lastUpdated: lastUpdated,
      versions: versions,
    );
  }
}
