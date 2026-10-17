import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/logging/hvac_log.dart';
import 'package:hvac_admin/core/messaging/message_sender.dart';
import 'package:hvac_admin/core/messaging/messaging_send_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseMessageSender implements MessageSender {
  SupabaseMessageSender(this._client);

  final SupabaseClient _client;

  @override
  Future<OutboundSendResult> send(OutboundSendRequest request) async {
    if (request.channel == CommunicationChannel.system) {
      return const OutboundSendResult(provider: 'system', providerMessageId: '', status: 'logged');
    }

    try {
      final response = await _client.functions.invoke(
        'send-message',
        body: {
          'channel': request.channel.name,
          'to_address': request.toAddress,
          'body': request.body,
          'subject': request.subject,
          if (request.templateKind != null) 'template_kind': request.templateKind,
          'metadata': request.metadata,
        },
      );

      final status = response.status;
      final data = response.data;
      if (status >= 400) {
        final error = MessagingSendException.fromFunctionResponse(status: status, data: data);
        HvacLog.warn('messaging.send_failed', fields: {
          'code': error.code,
          'channel': request.channel.name,
          'status': status,
        });
        throw error;
      }

      if (data is! Map) {
        throw MessagingSendException('invalid_response', 'send-message returned unexpected payload');
      }

      final result = OutboundSendResult(
        provider: data['provider']?.toString() ?? 'unknown',
        providerMessageId: data['provider_message_id']?.toString() ?? '',
        status: data['status']?.toString() ?? 'sent',
      );
      HvacLog.info('messaging.sent', fields: {
        'provider': result.provider,
        'channel': request.channel.name,
        'provider_message_id': result.providerMessageId,
      });
      return result;
    } on MessagingSendException {
      rethrow;
    } catch (error, stack) {
      HvacLog.error('messaging.send_failed', error: error, stack: stack, fields: {
        'channel': request.channel.name,
      });
      throw MessagingSendException('send_failed', error.toString());
    }
  }
}
