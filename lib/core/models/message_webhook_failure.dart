class MessageWebhookFailure {
  const MessageWebhookFailure({
    required this.id,
    required this.receivedAt,
    required this.provider,
    required this.eventType,
    required this.error,
    this.externalMessageId,
  });

  final String id;
  final DateTime receivedAt;
  final String provider;
  final String eventType;
  final String error;
  final String? externalMessageId;
}
