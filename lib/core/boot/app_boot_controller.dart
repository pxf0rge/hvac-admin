import 'package:flutter/foundation.dart';

/// Gates routing behind one-time boot work (session restore, initial loads).
///
/// The router shows the splash route until [isReady], then sends the user to
/// their destination automatically (dashboard when a session was restored), so
/// the login screen never flashes for returning office users.
class AppBootController extends ChangeNotifier {
  bool _isReady = false;
  Uri? _pendingLocation;

  /// Whether boot work finished and the router may leave the splash screen.
  bool get isReady => _isReady;

  /// Deep link captured before boot finished, restored once ready.
  Uri? get pendingLocation => _pendingLocation;

  /// Fallback for callers without an explicit boot phase (e.g. some tests).
  void markReady() {
    if (_isReady) return;
    _isReady = true;
    notifyListeners();
  }

  /// Remembers a deep link that must survive until the user can open it:
  /// either captured while booting, or bounced to the login screen because
  /// the user wasn't signed in yet.
  void hold(Uri location, {required bool authenticated}) {
    if (authenticated || _pendingLocation != null) return;
    if (location.path == '/splash' || location.path == '/login') return;
    _pendingLocation = location;
  }

  /// Returns and clears the held deep link (if any).
  Uri? consumePending() {
    final pending = _pendingLocation;
    _pendingLocation = null;
    return pending;
  }

  /// Runs [task] and marks the app ready afterwards (even on failure).
  Future<void> run(Future<void> Function() task) async {
    try {
      await task();
    } finally {
      markReady();
    }
  }
}
