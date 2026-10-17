import 'package:hvac_admin/core/models/internal_message.dart';

abstract class InternalMessagingRepository {
  Future<List<InternalThread>> listThreads();
  Future<List<InternalMessage>> listMessages(String threadId);
  Future<InternalThread> getOrCreateThread({
    required String technicianId,
    String? jobId,
    String subject = '',
  });
  Future<InternalMessage> sendMessage({
    required String threadId,
    required String body,
  });
  Future<void> markRead(String threadId);
  Future<int> unreadCount();
}
