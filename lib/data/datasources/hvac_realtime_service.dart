import 'dart:async';

import 'package:hvac_admin/core/realtime/hvac_realtime_event.dart';

enum RealtimeConnectionStatus { connected, reconnecting, disconnected }

/// Selective Realtime subscriptions. No-op when Supabase is not wired (tests).
abstract class HvacRealtimeService {
  Stream<HvacRealtimeEvent> get events;

  Stream<RealtimeConnectionStatus> get connectionStatus;

  Future<void> startOffice();

  Future<void> stop();

  Future<void> dispose();
}

class NoopRealtimeService implements HvacRealtimeService {
  final _events = StreamController<HvacRealtimeEvent>.broadcast();
  final _connection = StreamController<RealtimeConnectionStatus>.broadcast();
  int startOfficeCalls = 0;
  int stopCalls = 0;

  @override
  Stream<HvacRealtimeEvent> get events => _events.stream;

  @override
  Stream<RealtimeConnectionStatus> get connectionStatus => _connection.stream;

  @override
  Future<void> startOffice() async {
    startOfficeCalls += 1;
    if (!_connection.isClosed) {
      _connection.add(RealtimeConnectionStatus.connected);
    }
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
    if (!_connection.isClosed) {
      _connection.add(RealtimeConnectionStatus.disconnected);
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _events.close();
    await _connection.close();
  }

  /// Test helper: push a synthetic event.
  void emit(HvacRealtimeEvent event) {
    if (!_events.isClosed) _events.add(event);
  }

  /// Test helper: push a synthetic connection status.
  void emitConnection(RealtimeConnectionStatus status) {
    if (!_connection.isClosed) _connection.add(status);
  }
}
