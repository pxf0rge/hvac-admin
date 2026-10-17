import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/messaging/messaging_send_exception.dart';

class OutboundSendRequest {
  const OutboundSendRequest({
    required this.channel,
    required this.toAddress,
    required this.body,
    this.subject = '',
    this.templateKind,
    this.metadata = const {},
  });

  final CommunicationChannel channel;
  final String toAddress;
  final String body;
  final String subject;
  final String? templateKind;
  final Map<String, String> metadata;
}

class OutboundSendResult {
  const OutboundSendResult({
    required this.provider,
    required this.providerMessageId,
    required this.status,
  });

  final String provider;
  final String providerMessageId;
  final String status;
}

abstract class MessageSender {
  Future<OutboundSendResult> send(OutboundSendRequest request);
}

class MockMessageSender implements MessageSender {
  MockMessageSender({int startId = 1000}) : _next = startId;

  int _next;
  final List<OutboundSendRequest> sent = [];
  bool failNext = false;

  @override
  Future<OutboundSendResult> send(OutboundSendRequest request) async {
    sent.add(request);
    if (failNext) {
      failNext = false;
      throw MessagingSendException('send_failed', 'Mock provider rejected the message');
    }
    final id = 'mock_${_next++}';
    return OutboundSendResult(provider: 'mock', providerMessageId: id, status: 'sent');
  }
}
