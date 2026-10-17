import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/controllers/communication_controller.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/messaging/message_dispatch_service.dart';
import 'package:hvac_admin/core/messaging/message_sender.dart';
import 'package:hvac_admin/core/messaging/message_templates.dart';
import 'package:hvac_admin/core/messaging/messaging_send_exception.dart';
import 'package:hvac_admin/data/repositories/mock_repositories.dart';

void main() {
  test('MessageTemplateCatalog renders appointment reminder variables', () {
    final template = MessageTemplateCatalog.byKind(MessageTemplateKind.appointmentReminder);
    final body = template.renderBody({
      'customer_name': 'Pat Nguyen',
      'property_address': '77 Oak Lane',
      'service_date': 'Aug 30, 2026',
      'job_number': 'JOB-1001',
    });
    expect(body, contains('Pat Nguyen'));
    expect(body, contains('77 Oak Lane'));
    expect(body, contains('JOB-1001'));
    expect(body, isNot(contains('{{')));
  });

  test('Spanish preferred language selects Spanish catalog template', () {
    final en = MessageTemplateCatalog.byKind(MessageTemplateKind.appointmentReminder);
    final es = MessageTemplateCatalog.byKind(
      MessageTemplateKind.appointmentReminder,
      locale: PreferredLanguage.spanish,
    );
    expect(en.body, contains('Arctic HVAC Solutions reminder'));
    expect(es.body, contains('Recordatorio Arctic HVAC Solutions'));
    expect(es.locale, PreferredLanguage.spanish);
  });

  test('Maintenance renewal template renders variables EN/ES', () {
    final en = MessageTemplateCatalog.byKind(MessageTemplateKind.maintenanceRenewal);
    final es = MessageTemplateCatalog.byKind(
      MessageTemplateKind.maintenanceRenewal,
      locale: PreferredLanguage.spanish,
    );
    final vars = {
      'agreement_title': 'Annual Cool Plan',
      'property_address': '77 Oak Lane',
      'renewal_date': '2026-10-01',
    };
    expect(en.renderBody(vars), contains('Annual Cool Plan'));
    expect(es.renderBody(vars), contains('se renueva'));
  });

  test('English templates stay English regardless of Spanish catalog sibling', () {
    final en = MessageTemplateCatalog.byKind(
      MessageTemplateKind.jobCompleted,
      locale: PreferredLanguage.english,
    );
    expect(en.body, contains('is complete'));
    expect(en.body, isNot(contains('está completo')));
  });

  test('MessageTemplateKindX parses template ids', () {
    expect(MessageTemplateKindX.tryParse('appointment_reminder'), MessageTemplateKind.appointmentReminder);
    expect(MessageTemplateKindX.tryParse('unknown'), isNull);
  });

  test('MockMessageSender records outbound requests', () async {
    final sender = MockMessageSender();
    final result = await sender.send(
      const OutboundSendRequest(
        channel: CommunicationChannel.sms,
        toAddress: '+15551234567',
        body: 'Hello',
      ),
    );
    expect(sender.sent.length, 1);
    expect(result.provider, 'mock');
    expect(result.status, 'sent');
  });

  test('CommunicationController sends template via dispatch service', () async {
    final repo = MockCommunicationRepository();
    final sender = MockMessageSender();
    final dispatch = MessageDispatchService(repository: repo, sender: sender);
    final controller = CommunicationController(repo, dispatch: dispatch);

    final saved = await controller.sendTemplate(
      kind: MessageTemplateKind.appointmentReminder,
      entityType: CommunicationEntityType.job,
      entityId: 'job-1',
      entityLabel: 'JOB-1001',
      toAddress: '+15551234567',
      variables: {
        'customer_name': 'Pat Nguyen',
        'property_address': '77 Oak Lane',
        'service_date': 'Aug 30, 2026',
        'job_number': 'JOB-1001',
      },
    );

    expect(saved.deliveryStatus, 'sent');
    expect(saved.channel, CommunicationChannel.sms);
    expect(saved.localeCode, 'en');
    expect(saved.metadata['locale'], 'en');
    expect(sender.sent.length, 1);
    expect(sender.sent.first.toAddress, '+15551234567');
    expect(controller.messages.first.id, saved.id);
    expect(controller.sendError, isNull);
  });

  test('CommunicationController Spanish template stores locale metadata', () async {
    final repo = MockCommunicationRepository();
    final sender = MockMessageSender();
    final dispatch = MessageDispatchService(repository: repo, sender: sender);
    final controller = CommunicationController(repo, dispatch: dispatch);

    final saved = await controller.sendTemplate(
      kind: MessageTemplateKind.appointmentReminder,
      entityType: CommunicationEntityType.customer,
      entityId: 'cust-1',
      entityLabel: 'Pat Nguyen',
      toAddress: '+15551234567',
      locale: PreferredLanguage.spanish,
      variables: {
        'customer_name': 'Pat Nguyen',
        'property_address': '77 Oak Lane',
        'service_date': 'Aug 30, 2026',
        'job_number': 'JOB-1001',
      },
    );

    expect(saved.body, contains('Recordatorio Arctic HVAC Solutions'));
    expect(saved.localeCode, 'es');
    expect(sender.sent.first.body, contains('Recordatorio'));
    expect(sender.sent.first.metadata['locale'], 'es');
  });

  test('CommunicationController surfaces send failure and retries', () async {
    final repo = MockCommunicationRepository();
    final sender = MockMessageSender()..failNext = true;
    final dispatch = MessageDispatchService(repository: repo, sender: sender);
    final controller = CommunicationController(repo, dispatch: dispatch);

    await expectLater(
      controller.send(
        channel: CommunicationChannel.sms,
        entityType: CommunicationEntityType.customer,
        entityId: 'cust-1',
        entityLabel: 'Pat Nguyen',
        body: 'Test message',
        toAddress: '+15551234567',
      ),
      throwsA(isA<MessagingSendException>()),
    );
    expect(controller.sendError, isNotNull);
    expect(controller.canRetry, isTrue);

    final retried = await controller.retryLastSend();
    expect(retried.deliveryStatus, 'sent');
    expect(sender.sent.length, 2);
    expect(controller.sendError, isNull);
  });
}
