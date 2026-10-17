import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/controllers/internal_messaging_controller.dart';
import 'package:hvac_admin/data/repositories/mock_internal_messaging_repository.dart';

void main() {
  test('InternalMessagingController sends and tracks unread for office', () async {
    final repo = MockInternalMessagingRepository();
    final controller = InternalMessagingController(repo);

    final thread = await controller.startThread(technicianId: 'tech-1');
    expect(thread.technicianId, 'tech-1');

    await controller.send(threadId: thread.id, body: 'Please call the office');
    expect(controller.messagesFor(thread.id).length, 1);
    expect(controller.messagesFor(thread.id).first.body, contains('Please call'));

    // Technician reply via repo (other profile)
    repo.setCurrentProfile('tech-profile');
    await repo.sendMessage(threadId: thread.id, body: 'On my way');
    // Switch back to office profile for unread calc
    repo.setCurrentProfile('office-profile-1');
    await controller.loadInbox(force: true);
    expect(controller.unreadCount, greaterThan(0));
  });
}
