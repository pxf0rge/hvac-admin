import 'package:hvac_admin/core/enums/domain_enums.dart';

enum MessageTemplateKind {
  appointmentReminder,
  technicianOnTheWay,
  jobCompleted,
  estimateLink,
  invoiceLink,
  documentLink,
  maintenanceRenewal,
}

extension MessageTemplateKindX on MessageTemplateKind {
  String get id => switch (this) {
        MessageTemplateKind.appointmentReminder => 'appointment_reminder',
        MessageTemplateKind.technicianOnTheWay => 'technician_on_the_way',
        MessageTemplateKind.jobCompleted => 'job_completed',
        MessageTemplateKind.estimateLink => 'estimate_link',
        MessageTemplateKind.invoiceLink => 'invoice_link',
        MessageTemplateKind.documentLink => 'document_link',
        MessageTemplateKind.maintenanceRenewal => 'maintenance_renewal',
      };

  String get label => switch (this) {
        MessageTemplateKind.appointmentReminder => 'Appointment reminder',
        MessageTemplateKind.technicianOnTheWay => 'Technician on the way',
        MessageTemplateKind.jobCompleted => 'Job completed',
        MessageTemplateKind.estimateLink => 'Estimate link',
        MessageTemplateKind.invoiceLink => 'Invoice link',
        MessageTemplateKind.documentLink => 'Document link',
        MessageTemplateKind.maintenanceRenewal => 'Maintenance renewal',
      };

  static MessageTemplateKind? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final kind in MessageTemplateKind.values) {
      if (kind.id == raw) return kind;
    }
    return null;
  }
}

class MessageTemplate {
  const MessageTemplate({
    required this.kind,
    required this.channel,
    required this.body,
    this.subject = '',
    this.locale = PreferredLanguage.english,
  });

  final MessageTemplateKind kind;
  final CommunicationChannel channel;
  final String subject;
  final String body;
  final PreferredLanguage locale;

  String renderSubject(Map<String, String> vars) {
    var subj = subject;
    for (final entry in vars.entries) {
      subj = subj.replaceAll('{{${entry.key}}}', entry.value);
    }
    return subj.replaceAll(RegExp(r'\{\{[a-z0-9_]+\}\}'), '—');
  }

  String renderBody(Map<String, String> vars) {
    var text = body;
    for (final entry in vars.entries) {
      text = text.replaceAll('{{${entry.key}}}', entry.value);
    }
    return text.replaceAll(RegExp(r'\{\{[a-z0-9_]+\}\}'), '—');
  }
}

abstract final class MessageTemplateCatalog {
  static const appointmentReminderSms = MessageTemplate(
    kind: MessageTemplateKind.appointmentReminder,
    channel: CommunicationChannel.sms,
    body:
        'Arctic HVAC Solutions reminder: appointment for {{customer_name}} at {{property_address}} on {{service_date}} ({{job_number}}). Reply STOP to opt out.',
  );

  static const appointmentReminderSmsEs = MessageTemplate(
    kind: MessageTemplateKind.appointmentReminder,
    channel: CommunicationChannel.sms,
    locale: PreferredLanguage.spanish,
    body:
        'Recordatorio Arctic HVAC Solutions: cita para {{customer_name}} en {{property_address}} el {{service_date}} ({{job_number}}). Responda STOP para cancelar.',
  );

  static const onTheWaySms = MessageTemplate(
    kind: MessageTemplateKind.technicianOnTheWay,
    channel: CommunicationChannel.sms,
    body: '{{technician_name}} is on the way to {{property_address}} for {{job_number}}. ETA {{eta}}.',
  );

  static const onTheWaySmsEs = MessageTemplate(
    kind: MessageTemplateKind.technicianOnTheWay,
    channel: CommunicationChannel.sms,
    locale: PreferredLanguage.spanish,
    body:
        '{{technician_name}} va en camino a {{property_address}} para {{job_number}}. ETA {{eta}}.',
  );

  static const jobCompletedSms = MessageTemplate(
    kind: MessageTemplateKind.jobCompleted,
    channel: CommunicationChannel.sms,
    body: 'Arctic HVAC Solutions: work on {{job_number}} at {{property_address}} is complete. Thanks, {{customer_name}}.',
  );

  static const jobCompletedSmsEs = MessageTemplate(
    kind: MessageTemplateKind.jobCompleted,
    channel: CommunicationChannel.sms,
    locale: PreferredLanguage.spanish,
    body:
        'Arctic HVAC Solutions: el trabajo {{job_number}} en {{property_address}} está completo. Gracias, {{customer_name}}.',
  );

  static const estimateLinkEmail = MessageTemplate(
    kind: MessageTemplateKind.estimateLink,
    channel: CommunicationChannel.email,
    subject: 'Your Arctic HVAC Solutions estimate {{estimate_number}}',
    body:
        'Hi {{customer_name}},\n\nYour estimate {{estimate_number}} for {{property_address}} is ready:\n{{estimate_url}}\n\n— Arctic HVAC Solutions',
  );

  static const estimateLinkEmailEs = MessageTemplate(
    kind: MessageTemplateKind.estimateLink,
    channel: CommunicationChannel.email,
    locale: PreferredLanguage.spanish,
    subject: 'Su presupuesto Arctic HVAC Solutions {{estimate_number}}',
    body:
        'Hola {{customer_name}},\n\nSu presupuesto {{estimate_number}} para {{property_address}} está listo:\n{{estimate_url}}\n\n— Arctic HVAC Solutions',
  );

  static const invoiceLinkEmail = MessageTemplate(
    kind: MessageTemplateKind.invoiceLink,
    channel: CommunicationChannel.email,
    subject: 'Invoice {{invoice_number}} from Arctic HVAC Solutions',
    body:
        'Hi {{customer_name}},\n\nYour invoice {{invoice_number}} for {{property_address}} is ready:\n{{invoice_url}}\n\nAmount due: {{amount_due}}\nDue date: {{due_date}}\n\n— Arctic HVAC Solutions',
  );

  static const invoiceLinkEmailEs = MessageTemplate(
    kind: MessageTemplateKind.invoiceLink,
    channel: CommunicationChannel.email,
    locale: PreferredLanguage.spanish,
    subject: 'Factura {{invoice_number}} de Arctic HVAC Solutions',
    body:
        'Hola {{customer_name}},\n\nSu factura {{invoice_number}} para {{property_address}} está lista:\n{{invoice_url}}\n\nMonto adeudado: {{amount_due}}\nFecha de vencimiento: {{due_date}}\n\n— Arctic HVAC Solutions',
  );

  static const documentLinkEmail = MessageTemplate(
    kind: MessageTemplateKind.documentLink,
    channel: CommunicationChannel.email,
    subject: 'Signed document for {{job_number}}',
    body:
        'Hi {{customer_name}},\n\nYour signed {{document_title}} for {{job_number}} is available:\n{{document_url}}\n\n— Arctic HVAC Solutions',
  );

  static const documentLinkEmailEs = MessageTemplate(
    kind: MessageTemplateKind.documentLink,
    channel: CommunicationChannel.email,
    locale: PreferredLanguage.spanish,
    subject: 'Documento firmado para {{job_number}}',
    body:
        'Hola {{customer_name}},\n\nSu {{document_title}} firmado para {{job_number}} está disponible:\n{{document_url}}\n\n— Arctic HVAC Solutions',
  );

  static const maintenanceRenewalSms = MessageTemplate(
    kind: MessageTemplateKind.maintenanceRenewal,
    channel: CommunicationChannel.sms,
    body:
        'Arctic HVAC Solutions: your {{agreement_title}} plan for {{property_address}} renews around {{renewal_date}}. Reply or call us to renew.',
  );

  static const maintenanceRenewalSmsEs = MessageTemplate(
    kind: MessageTemplateKind.maintenanceRenewal,
    channel: CommunicationChannel.sms,
    locale: PreferredLanguage.spanish,
    body:
        'Arctic HVAC Solutions: su plan {{agreement_title}} para {{property_address}} se renueva cerca de {{renewal_date}}. Responda o llámenos para renovar.',
  );

  /// English catalog (default / UI picker).
  static const List<MessageTemplate> all = [
    appointmentReminderSms,
    onTheWaySms,
    jobCompletedSms,
    estimateLinkEmail,
    invoiceLinkEmail,
    documentLinkEmail,
    maintenanceRenewalSms,
  ];

  static const List<MessageTemplate> _spanish = [
    appointmentReminderSmsEs,
    onTheWaySmsEs,
    jobCompletedSmsEs,
    estimateLinkEmailEs,
    invoiceLinkEmailEs,
    documentLinkEmailEs,
    maintenanceRenewalSmsEs,
  ];

  /// Resolves template body/subject for [locale]. Missing Spanish falls back to English.
  static MessageTemplate byKind(
    MessageTemplateKind kind, {
    PreferredLanguage locale = PreferredLanguage.english,
  }) {
    final pool = locale == PreferredLanguage.spanish ? _spanish : all;
    for (final template in pool) {
      if (template.kind == kind) return template;
    }
    return all.firstWhere((template) => template.kind == kind);
  }
}
