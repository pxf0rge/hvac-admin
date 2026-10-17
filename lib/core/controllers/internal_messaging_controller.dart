import 'package:flutter/foundation.dart';
import 'package:hvac_admin/core/models/internal_message.dart';
import 'package:hvac_admin/data/repositories/internal_messaging_repository.dart';

class InternalMessagingController extends ChangeNotifier {
  InternalMessagingController(this._repository);

  final InternalMessagingRepository _repository;

  List<InternalThread> _threads = const [];
  final Map<String, List<InternalMessage>> _messagesByThread = {};
  bool _loading = false;
  String? _error;
  int _unread = 0;
  String? _activeThreadId;

  List<InternalThread> get threads => List.unmodifiable(_threads);
  bool get isLoading => _loading;
  String? get error => _error;
  int get unreadCount => _unread;
  String? get activeThreadId => _activeThreadId;

  List<InternalMessage> messagesFor(String threadId) =>
      List.unmodifiable(_messagesByThread[threadId] ?? const []);

  InternalThread? threadById(String id) {
    for (final thread in _threads) {
      if (thread.id == id) return thread;
    }
    return null;
  }

  Future<void> loadInbox({bool force = false}) async {
    if (_loading && !force) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _threads = await _repository.listThreads();
      _unread = _threads.fold<int>(0, (sum, t) => sum + t.unreadCount);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshFromRemote() => loadInbox(force: true);

  Future<void> openThread(String threadId) async {
    _activeThreadId = threadId;
    notifyListeners();
    try {
      final messages = await _repository.listMessages(threadId);
      _messagesByThread[threadId] = messages;
      await _repository.markRead(threadId);
      await loadInbox(force: true);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<InternalThread> startThread({
    required String technicianId,
    String? jobId,
    String subject = '',
  }) async {
    final thread = await _repository.getOrCreateThread(
      technicianId: technicianId,
      jobId: jobId,
      subject: subject,
    );
    await loadInbox(force: true);
    await openThread(thread.id);
    return thread;
  }

  Future<void> send({required String threadId, required String body}) async {
    final saved = await _repository.sendMessage(threadId: threadId, body: body);
    final current = <InternalMessage>[...(_messagesByThread[threadId] ?? const <InternalMessage>[])];
    current.add(saved);
    _messagesByThread[threadId] = current;
    notifyListeners();
    await loadInbox(force: true);
  }
}
