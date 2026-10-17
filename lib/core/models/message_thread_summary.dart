import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_message.dart';

/// Latest message in a conversation thread grouped by linked entity.
class MessageThreadSummary {
  const MessageThreadSummary({
    required this.entityType,
    required this.entityId,
    required this.entityLabel,
    required this.latest,
    required this.messageCount,
  });

  final CommunicationEntityType entityType;
  final String entityId;
  final String entityLabel;
  final OfficeMessage latest;
  final int messageCount;

  String get preview => latest.body.length > 96 ? '${latest.body.substring(0, 96)}…' : latest.body;
}
