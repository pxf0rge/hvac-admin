import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_message.dart';

/// Optional filters for message history queries.
class MessageHistoryFilter {
  const MessageHistoryFilter({this.channel, this.from, this.to});

  final CommunicationChannel? channel;
  final DateTime? from;
  final DateTime? to;

  MessageHistoryFilter copyWith({
    CommunicationChannel? channel,
    DateTime? from,
    DateTime? to,
    bool clearChannel = false,
    bool clearFrom = false,
    bool clearTo = false,
  }) {
    return MessageHistoryFilter(
      channel: clearChannel ? null : (channel ?? this.channel),
      from: clearFrom ? null : (from ?? this.from),
      to: clearTo ? null : (to ?? this.to),
    );
  }

  bool matches(OfficeMessageLike message) {
    if (channel != null && message.channel != channel) return false;
    final at = DateTime.tryParse(message.at);
    if (from != null && at != null && at.isBefore(from!)) return false;
    if (to != null && at != null && at.isAfter(to!)) return false;
    return true;
  }
}

/// Links a stored message to a customer, property, or job record.
class MessageEntityRef {
  const MessageEntityRef({required this.entityType, required this.entityId});

  final CommunicationEntityType entityType;
  final String entityId;

  bool matches(CommunicationEntityType type, String id) =>
      entityType == type && entityId == id;
}
