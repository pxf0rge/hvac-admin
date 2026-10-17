import 'package:hvac_admin/core/models/internal_message.dart';
import 'package:hvac_admin/data/mappers/mapper_helpers.dart';
import 'package:hvac_admin/data/repositories/internal_messaging_repository.dart';

class MockInternalMessagingRepository implements InternalMessagingRepository {
  final List<InternalThread> _threads = [];
  final Map<String, List<InternalMessage>> _messages = {};
  final Map<String, String> _reads = {}; // key: '$profileId::$threadId'
  String _profileId = 'office-profile-1';

  void setCurrentProfile(String profileId) => _profileId = profileId;

  String _readKey(String threadId) => '$_profileId::$threadId';

  @override
  Future<List<InternalThread>> listThreads() async {
    final sorted = [..._threads]
      ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return [
      for (final thread in sorted)
        InternalThread(
          id: thread.id,
          technicianId: thread.technicianId,
          technicianName: thread.technicianName,
          jobId: thread.jobId,
          jobNumber: thread.jobNumber,
          subject: thread.subject,
          lastMessagePreview: thread.lastMessagePreview,
          lastMessageAt: thread.lastMessageAt,
          unreadCount: _unreadFor(thread.id),
        ),
    ];
  }

  @override
  Future<List<InternalMessage>> listMessages(String threadId) async {
    return List.unmodifiable(_messages[threadId] ?? const []);
  }

  @override
  Future<InternalThread> getOrCreateThread({
    required String technicianId,
    String? jobId,
    String subject = '',
  }) async {
    for (final thread in _threads) {
      if (thread.technicianId == technicianId && thread.jobId == jobId) {
        return thread;
      }
    }
    final created = InternalThread(
      id: MapperHelpers.newUuid(),
      technicianId: technicianId,
      technicianName: 'Technician',
      jobId: jobId,
      subject: subject,
      lastMessageAt: DateTime.now().toUtc().toIso8601String(),
    );
    _threads.add(created);
    _messages[created.id] = [];
    return created;
  }

  @override
  Future<InternalMessage> sendMessage({
    required String threadId,
    required String body,
  }) async {
    final text = body.trim();
    if (text.isEmpty) throw ArgumentError('Message body is required');
    final message = InternalMessage(
      id: MapperHelpers.newUuid(),
      threadId: threadId,
      senderProfileId: _profileId,
      senderKind: _profileId.contains('tech')
          ? InternalSenderKind.technician
          : InternalSenderKind.office,
      body: text,
      createdAt: DateTime.now().toUtc().toIso8601String(),
      senderName: _profileId.contains('tech') ? 'Technician' : 'Office',
    );
    final list = _messages.putIfAbsent(threadId, () => []);
    list.add(message);
    final index = _threads.indexWhere((t) => t.id == threadId);
    if (index >= 0) {
      final t = _threads[index];
      _threads[index] = InternalThread(
        id: t.id,
        technicianId: t.technicianId,
        technicianName: t.technicianName,
        jobId: t.jobId,
        jobNumber: t.jobNumber,
        subject: t.subject,
        lastMessagePreview: text,
        lastMessageAt: message.createdAt,
        unreadCount: t.unreadCount,
      );
    }
    _reads[_readKey(threadId)] = message.createdAt;
    return message;
  }

  @override
  Future<void> markRead(String threadId) async {
    _reads[_readKey(threadId)] = DateTime.now().toUtc().toIso8601String();
  }

  @override
  Future<int> unreadCount() async {
    var total = 0;
    for (final thread in _threads) {
      total += _unreadFor(thread.id);
    }
    return total;
  }

  int _unreadFor(String threadId) {
    final lastRead = _reads[_readKey(threadId)];
    final messages = _messages[threadId] ?? const [];
    if (messages.isEmpty) return 0;
    return messages.where((m) {
      if (m.senderProfileId == _profileId) return false;
      if (lastRead == null) return true;
      return m.createdAt.compareTo(lastRead) > 0;
    }).length;
  }
}
