import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/message_history_filter.dart';
import 'package:hvac_admin/core/models/message_webhook_failure.dart';
import 'package:hvac_admin/core/models/office_message.dart';
import 'package:hvac_admin/data/pagination/paged_result.dart';

abstract class CommunicationRepository {
  Future<List<OfficeMessage>> getMessages({
    CommunicationEntityType? entityType,
    String? entityId,
    List<MessageEntityRef>? entities,
    MessageHistoryFilter? filter,
    int limit = 200,
  });
  Future<PagedResult<OfficeMessage>> getMessagesPage({
    int offset = 0,
    int limit = ListQuery.defaultLimit,
    String? search,
    CommunicationEntityType? entityType,
    String? entityId,
    List<MessageEntityRef>? entities,
    MessageHistoryFilter? filter,
  });
  Future<OfficeMessage> save(OfficeMessage message);
  Future<List<MessageWebhookFailure>> getWebhookFailures({int limit = 10});
}
