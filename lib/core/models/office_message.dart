import 'package:hvac_admin/core/enums/domain_enums.dart';

abstract interface class OfficeMessageLike {
  String get at;
  CommunicationChannel get channel;
}

class OfficeMessage implements OfficeMessageLike {
  const OfficeMessage({
    required this.id,
    required this.at,
    required this.channel,
    required this.direction,
    required this.entityType,
    required this.entityId,
    required this.entityLabel,
    required this.body,
    this.subject = '',
    this.provider = 'mock',
    this.providerMessageId,
    this.templateKind,
    this.deliveryStatus = 'logged',
    this.toAddress = '',
    this.metadata = const {},
  });

  final String id;
  final String at;
  final CommunicationChannel channel;
  final MessageDirection direction;
  final CommunicationEntityType entityType;
  final String entityId;
  final String entityLabel;
  final String body;
  final String subject;
  final String provider;
  final String? providerMessageId;
  final String? templateKind;
  final String deliveryStatus;
  final String toAddress;
  final Map<String, String> metadata;

  String? get localeCode => metadata['locale'];
}
