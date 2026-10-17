import 'dart:async';
import 'dart:math' as math;

import 'package:hvac_admin/core/logging/hvac_log.dart';
import 'package:hvac_admin/core/realtime/hvac_realtime_event.dart';
import 'package:hvac_admin/data/datasources/hvac_realtime_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseRealtimeService implements HvacRealtimeService {
  SupabaseRealtimeService(this._client);

  final SupabaseClient _client;
  final _events = StreamController<HvacRealtimeEvent>.broadcast();
  final _connection = StreamController<RealtimeConnectionStatus>.broadcast();
  RealtimeChannel? _channel;
  bool _officeActive = false;
  Timer? _reconnectTimer;
  int _reconnectAttempt = 0;

  static const _tables = [
    'jobs',
    'job_assignments',
    'job_status_history',
    'job_photos',
    'job_documents',
    'notifications',
    'technicians',
    'technician_locations',
    'internal_messages',
    'internal_threads',
  ];

  static const _maxReconnectAttempts = 8;
  static const _baseReconnectDelay = Duration(milliseconds: 500);
  static const _maxReconnectDelay = Duration(seconds: 30);

  @override
  Stream<HvacRealtimeEvent> get events => _events.stream;

  @override
  Stream<RealtimeConnectionStatus> get connectionStatus => _connection.stream;

  @override
  Future<void> startOffice() async {
    await _tearDownChannel();
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempt = 0;
    _officeActive = true;
    await _openChannel();
  }

  Future<void> _openChannel() async {
    if (!_officeActive) return;

    final userId = _client.auth.currentUser?.id ?? 'anon';
    final channel = _client.channel('hvac-office-$userId');

    for (final table in _tables) {
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        callback: _onPayload,
      );
    }

    channel.subscribe(_onSubscribeStatus);
    _channel = channel;
  }

  void _onSubscribeStatus(RealtimeSubscribeStatus status, Object? error) {
    switch (status) {
      case RealtimeSubscribeStatus.subscribed:
        _reconnectAttempt = 0;
        _emitConnection(RealtimeConnectionStatus.connected);
      case RealtimeSubscribeStatus.channelError:
      case RealtimeSubscribeStatus.timedOut:
      case RealtimeSubscribeStatus.closed:
        if (status != RealtimeSubscribeStatus.subscribed) {
          HvacLog.warn('realtime.channel_lost', fields: {
            'status': status.name,
            'attempt': _reconnectAttempt,
            if (error != null) 'error': error.toString(),
          });
          _emitConnection(RealtimeConnectionStatus.reconnecting);
          _scheduleReconnect();
        }
    }
  }

  void _scheduleReconnect() {
    if (!_officeActive) return;
    if (_reconnectAttempt >= _maxReconnectAttempts) {
      HvacLog.error('realtime.reconnect_failed', fields: {'attempts': _reconnectAttempt});
      _emitConnection(RealtimeConnectionStatus.disconnected);
      return;
    }

    _reconnectAttempt += 1;
    final exponent = math.min(_reconnectAttempt - 1, 6);
    final delayMs = math.min(
      _maxReconnectDelay.inMilliseconds,
      _baseReconnectDelay.inMilliseconds * math.pow(2, exponent).toInt(),
    );

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: delayMs), () async {
      if (!_officeActive) return;
      try {
        await _tearDownChannel();
        await _openChannel();
      } catch (error, stack) {
        HvacLog.error('realtime.reconnect_failed', error: error, stack: stack, fields: {
          'attempt': _reconnectAttempt,
        });
        _scheduleReconnect();
      }
    });
  }

  void _onPayload(PostgresChangePayload payload) {
    final table = HvacRealtimeTable.tryParse(payload.table);
    if (table == null) return;

    final changeType = switch (payload.eventType) {
      PostgresChangeEvent.insert => HvacRealtimeChangeType.insert,
      PostgresChangeEvent.update => HvacRealtimeChangeType.update,
      PostgresChangeEvent.delete => HvacRealtimeChangeType.delete,
      PostgresChangeEvent.all => null,
    };
    if (changeType == null) return;

    final record = payload.newRecord.isNotEmpty ? payload.newRecord : payload.oldRecord;
    final id = record['id']?.toString();
    if (id == null || id.isEmpty) return;

    if (_events.isClosed) return;
    _events.add(
      HvacRealtimeEvent(
        table: table,
        changeType: changeType,
        recordId: id,
        commitTimestamp: payload.commitTimestamp,
        newRecord: Map<String, dynamic>.from(payload.newRecord),
        oldRecord: Map<String, dynamic>.from(payload.oldRecord),
      ),
    );
  }

  void _emitConnection(RealtimeConnectionStatus status) {
    if (_connection.isClosed) return;
    _connection.add(status);
  }

  Future<void> _tearDownChannel() async {
    final channel = _channel;
    _channel = null;
    if (channel != null) {
      await _client.removeChannel(channel);
    }
  }

  @override
  Future<void> stop() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _reconnectAttempt = 0;
    _officeActive = false;
    await _tearDownChannel();
    _emitConnection(RealtimeConnectionStatus.disconnected);
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _events.close();
    await _connection.close();
  }
}
