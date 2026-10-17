import 'package:hvac_admin/core/realtime/hvac_realtime_event.dart';

/// Prevents double-handling of the same postgres change and skips local mutation echoes.
class RealtimeEventDeduper {
  RealtimeEventDeduper({
    this.seenTtl = const Duration(seconds: 30),
    this.localEchoWindow = const Duration(seconds: 2),
  });

  final Duration seenTtl;
  final Duration localEchoWindow;

  final Map<String, DateTime> _seen = {};
  final Map<String, DateTime> _localMutations = {};

  void rememberLocalMutation(HvacRealtimeTable table, String recordId) {
    _purge();
    _localMutations['${table.postgresName}:$recordId'] = DateTime.now();
  }

  /// Returns false when this event was already handled or is a local echo.
  bool shouldApply(HvacRealtimeEvent event) {
    _purge();
    final localAt = _localMutations[event.mutationKey];
    if (localAt != null && DateTime.now().difference(localAt) <= localEchoWindow) {
      return false;
    }
    if (_seen.containsKey(event.dedupeKey)) {
      return false;
    }
    _seen[event.dedupeKey] = DateTime.now();
    return true;
  }

  void _purge() {
    final now = DateTime.now();
    _seen.removeWhere((_, at) => now.difference(at) > seenTtl);
    _localMutations.removeWhere((_, at) => now.difference(at) > localEchoWindow);
  }
}
