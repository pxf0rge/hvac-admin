import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/message_history_filter.dart';
import 'package:hvac_admin/core/models/message_thread_summary.dart';
import 'package:hvac_admin/core/models/office_message.dart';

abstract final class MessageThreadGrouper {
  static List<MessageThreadSummary> recentThreads(
    Iterable<OfficeMessage> messages, {
    int limit = 12,
  }) {
    final sorted = [...messages]..sort((a, b) => b.at.compareTo(a.at));
    final counts = <String, int>{};
    final latest = <String, OfficeMessage>{};
    final labels = <String, String>{};
    final types = <String, CommunicationEntityType>{};

    for (final message in sorted) {
      final key = '${message.entityType.name}:${message.entityId}';
      counts[key] = (counts[key] ?? 0) + 1;
      latest.putIfAbsent(key, () => message);
      labels.putIfAbsent(key, () => message.entityLabel);
      types.putIfAbsent(key, () => message.entityType);
    }

    return [
      for (final entry in latest.entries)
        MessageThreadSummary(
          entityType: types[entry.key]!,
          entityId: entry.value.entityId,
          entityLabel: labels[entry.key] ?? entry.value.entityLabel,
          latest: entry.value,
          messageCount: counts[entry.key] ?? 1,
        ),
    ].take(limit).toList();
  }
}
