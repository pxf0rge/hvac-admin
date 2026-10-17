import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/message_history_filter.dart';
import 'package:hvac_admin/core/models/office_directory.dart';

abstract final class MessageThreadBuilder {
  static List<MessageEntityRef> forCustomer({
    required String customerId,
    required Iterable<OfficeProperty> properties,
    required Iterable<HistoryJob> jobs,
  }) {
    final propertyIds = properties.map((item) => item.id).toSet();
    return [
      MessageEntityRef(entityType: CommunicationEntityType.customer, entityId: customerId),
      for (final id in propertyIds)
        MessageEntityRef(entityType: CommunicationEntityType.property, entityId: id),
      for (final job in jobs)
        if (propertyIds.contains(job.propertyId))
          MessageEntityRef(entityType: CommunicationEntityType.job, entityId: job.id),
    ];
  }

  static List<MessageEntityRef> forJob({
    required String jobId,
    String? customerId,
  }) {
    return [
      MessageEntityRef(entityType: CommunicationEntityType.job, entityId: jobId),
      if (customerId != null)
        MessageEntityRef(entityType: CommunicationEntityType.customer, entityId: customerId),
    ];
  }
}
