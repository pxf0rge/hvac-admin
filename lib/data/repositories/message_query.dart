import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/message_history_filter.dart';
import 'package:hvac_admin/core/models/office_message.dart';

abstract final class MessageQuery {
  static bool matchesEntity(
    OfficeMessage message, {
    CommunicationEntityType? entityType,
    String? entityId,
    List<MessageEntityRef>? entities,
  }) {
    if (entities != null && entities.isNotEmpty) {
      return entities.any((ref) => ref.matches(message.entityType, message.entityId));
    }
    if (entityType != null && message.entityType != entityType) return false;
    if (entityId != null && message.entityId != entityId) return false;
    return true;
  }

  static bool matchesSearch(OfficeMessage message, String? search) {
    final needle = search?.trim();
    if (needle == null || needle.isEmpty) return true;
    final haystack = '${message.entityLabel} ${message.body} ${message.subject} ${message.toAddress}'.toLowerCase();
    return haystack.contains(needle.toLowerCase());
  }

  static Iterable<OfficeMessage> apply({
    required Iterable<OfficeMessage> messages,
    CommunicationEntityType? entityType,
    String? entityId,
    List<MessageEntityRef>? entities,
    MessageHistoryFilter? filter,
    String? search,
  }) {
    return messages.where((message) {
      if (!matchesEntity(message, entityType: entityType, entityId: entityId, entities: entities)) {
        return false;
      }
      if (filter != null && !filter.matches(message)) return false;
      if (!matchesSearch(message, search)) return false;
      return true;
    });
  }
}
