import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/controllers/communication_controller.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/messaging/message_dispatch_service.dart';
import 'package:hvac_admin/core/messaging/message_sender.dart';
import 'package:hvac_admin/core/messaging/message_thread_builder.dart';
import 'package:hvac_admin/core/messaging/message_thread_grouper.dart';
import 'package:hvac_admin/core/models/message_history_filter.dart';
import 'package:hvac_admin/data/datasources/mock_seed_data.dart';
import 'package:hvac_admin/data/repositories/mock_repositories.dart';

void main() {
  test('MockCommunicationRepository returns customer thread with inbound reply', () async {
    final repo = MockCommunicationRepository();
    final entities = MessageThreadBuilder.forCustomer(
      customerId: MockSeedIds.customerId,
      properties: [],
      jobs: [],
    );
    final messages = await repo.getMessages(entities: entities);
    expect(messages.any((item) => item.direction == MessageDirection.inbound), isTrue);
    expect(messages.any((item) => item.body.contains('Thanks! We will be home.')), isTrue);
  });

  test('MockCommunicationRepository scopes job history to job and customer', () async {
    final repo = MockCommunicationRepository();
    final entities = MessageThreadBuilder.forJob(
      jobId: MockSeedIds.jobId,
      customerId: MockSeedIds.customerId,
    );
    final messages = await repo.getMessages(entities: entities);
    expect(messages.any((item) => item.entityType == CommunicationEntityType.job), isTrue);
    expect(messages.any((item) => item.entityType == CommunicationEntityType.customer), isTrue);
  });

  test('MessageHistoryFilter limits results by channel', () async {
    final repo = MockCommunicationRepository();
    final smsOnly = await repo.getMessages(
      filter: const MessageHistoryFilter(channel: CommunicationChannel.sms),
    );
    expect(smsOnly.every((item) => item.channel == CommunicationChannel.sms), isTrue);
  });

  test('Message query search matches customer phone', () async {
    final repo = MockCommunicationRepository();
    final page = await repo.getMessagesPage(search: '2175550100');
    expect(page.items, isNotEmpty);
    expect(page.items.any((item) => item.toAddress.contains('2175550100')), isTrue);
  });

  test('MockCommunicationRepository ingestInbound simulates webhook', () async {
    final repo = MockCommunicationRepository();
    final saved = await repo.ingestInbound(
      channel: CommunicationChannel.sms,
      entityType: CommunicationEntityType.customer,
      entityId: MockSeedIds.customerId,
      entityLabel: 'Pat Nguyen',
      body: 'Can we reschedule?',
      toAddress: '2175550100',
      providerMessageId: 'twilio-in-1',
    );
    expect(saved.direction, MessageDirection.inbound);
    expect(saved.deliveryStatus, 'received');
    final thread = await repo.getMessages(
      entityType: CommunicationEntityType.customer,
      entityId: MockSeedIds.customerId,
    );
    expect(thread.first.body, 'Can we reschedule?');
  });

  test('MessageThreadGrouper builds recent threads', () async {
    final repo = MockCommunicationRepository();
    final messages = await repo.getMessages();
    final threads = MessageThreadGrouper.recentThreads(messages);
    expect(threads.length, greaterThanOrEqualTo(2));
    expect(threads.first.latest.at, isNotEmpty);
  });

  test('CommunicationController fetchRecentThreads groups conversations', () async {
    final repo = MockCommunicationRepository();
    final controller = CommunicationController(
      repo,
      dispatch: MessageDispatchService(repository: repo, sender: MockMessageSender()),
    );
    final threads = await controller.fetchRecentThreads();
    expect(threads.any((item) => item.entityLabel.contains('Pat')), isTrue);
    expect(threads.any((item) => item.entityLabel.contains('JOB-RLS-21')), isTrue);
  });
}
