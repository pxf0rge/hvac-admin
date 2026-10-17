import 'package:hvac_admin/core/models/office_message.dart';
import 'package:hvac_admin/data/mappers/enum_db.dart';
import 'package:hvac_admin/data/mappers/mapper_helpers.dart';

abstract final class MessageMapper {
  static OfficeMessage fromRow(Map<String, dynamic> row) {
    return OfficeMessage(
      id: MapperHelpers.uuid(row['id']),
      at: MapperHelpers.isoTimestamp(row['at']),
      channel: EnumDb.communicationChannelFromDb(MapperHelpers.str(row['channel'])),
      direction: EnumDb.messageDirectionFromDb(MapperHelpers.str(row['direction'])),
      entityType: EnumDb.communicationEntityTypeFromDb(MapperHelpers.str(row['entity_type'])),
      entityId: MapperHelpers.uuid(row['entity_id']),
      entityLabel: MapperHelpers.str(row['entity_label']),
      body: MapperHelpers.str(row['body']),
      subject: MapperHelpers.str(row['subject']),
      provider: MapperHelpers.str(row['provider'], fallback: 'mock'),
      providerMessageId: MapperHelpers.strOrNull(row['provider_message_id']),
      templateKind: MapperHelpers.strOrNull(row['template_kind']),
      deliveryStatus: MapperHelpers.str(row['delivery_status'], fallback: 'logged'),
      toAddress: MapperHelpers.str(row['to_address']),
      metadata: _metadataFrom(row['metadata']),
    );
  }

  static Map<String, dynamic> toRow(OfficeMessage message) => {
        'channel': EnumDb.communicationChannel(message.channel),
        'direction': EnumDb.messageDirection(message.direction),
        'entity_type': EnumDb.communicationEntityType(message.entityType),
        'entity_id': message.entityId,
        'entity_label': message.entityLabel,
        'subject': message.subject,
        'body': message.body,
        'provider': message.provider,
        if (message.providerMessageId != null && message.providerMessageId!.isNotEmpty)
          'provider_message_id': message.providerMessageId,
        if (message.templateKind != null) 'template_kind': message.templateKind,
        'delivery_status': message.deliveryStatus,
        'to_address': message.toAddress,
        'metadata': message.metadata,
      };

  static Map<String, dynamic> toInsertRow(OfficeMessage message) {
    if (!MapperHelpers.isUuid(message.entityId)) {
      throw StateError('Entity id must be a UUID for Supabase message persistence');
    }
    return toRow(message);
  }

  static Map<String, String> _metadataFrom(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final entry in raw.entries)
        if (entry.key != null) entry.key.toString(): entry.value?.toString() ?? '',
    };
  }
}
