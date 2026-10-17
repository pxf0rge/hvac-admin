import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/messaging/message_sender.dart';
import 'package:hvac_admin/core/messaging/message_templates.dart';
import 'package:hvac_admin/core/models/office_message.dart';
import 'package:hvac_admin/data/repositories/communication_repository.dart';

class MessageDispatchService {
  MessageDispatchService({
    required CommunicationRepository repository,
    required MessageSender sender,
  })  : _repository = repository,
        _sender = sender;

  final CommunicationRepository _repository;
  final MessageSender _sender;

  Future<OfficeMessage> sendTemplate({
    required MessageTemplateKind kind,
    required CommunicationEntityType entityType,
    required String entityId,
    required String entityLabel,
    required String toAddress,
    required Map<String, String> variables,
    PreferredLanguage locale = PreferredLanguage.english,
  }) async {
    final template = MessageTemplateCatalog.byKind(kind, locale: locale);
    final body = template.renderBody(variables);
    final subject = template.renderSubject(variables);
    final metadata = <String, String>{
      ...variables,
      'locale': locale.code,
    };
    final result = await _sender.send(
      OutboundSendRequest(
        channel: template.channel,
        toAddress: toAddress,
        body: body,
        subject: subject,
        templateKind: kind.id,
        metadata: metadata,
      ),
    );

    final message = OfficeMessage(
      id: 'msg_${DateTime.now().microsecondsSinceEpoch}',
      at: DateTime.now().toIso8601String(),
      channel: template.channel,
      direction: MessageDirection.outbound,
      entityType: entityType,
      entityId: entityId,
      entityLabel: entityLabel,
      body: body,
      subject: subject,
      provider: result.provider,
      providerMessageId: result.providerMessageId,
      templateKind: kind.id,
      deliveryStatus: result.status,
      toAddress: toAddress,
      metadata: {'locale': locale.code},
    );
    return _repository.save(message);
  }

  Future<OfficeMessage> sendCustom({
    required CommunicationChannel channel,
    required CommunicationEntityType entityType,
    required String entityId,
    required String entityLabel,
    required String toAddress,
    required String body,
    String subject = '',
  }) async {
    final result = await _sender.send(
      OutboundSendRequest(
        channel: channel,
        toAddress: toAddress,
        body: body,
        subject: subject,
      ),
    );
    final message = OfficeMessage(
      id: 'msg_${DateTime.now().microsecondsSinceEpoch}',
      at: DateTime.now().toIso8601String(),
      channel: channel,
      direction: MessageDirection.outbound,
      entityType: entityType,
      entityId: entityId,
      entityLabel: entityLabel,
      body: body.trim(),
      subject: subject.trim(),
      provider: result.provider,
      providerMessageId: result.providerMessageId,
      deliveryStatus: result.status,
      toAddress: toAddress,
    );
    return _repository.save(message);
  }
}
