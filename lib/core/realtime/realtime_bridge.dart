import 'dart:async';

import 'package:hvac_admin/core/controllers/customer_controller.dart';
import 'package:hvac_admin/core/controllers/gps_map_controller.dart';
import 'package:hvac_admin/core/controllers/internal_messaging_controller.dart';
import 'package:hvac_admin/core/controllers/job_controller.dart';
import 'package:hvac_admin/core/controllers/management_auth_controller.dart';
import 'package:hvac_admin/core/controllers/technician_controller.dart';
import 'package:hvac_admin/core/logging/hvac_log.dart';
import 'package:hvac_admin/core/realtime/hvac_realtime_event.dart';
import 'package:hvac_admin/core/realtime/realtime_event_deduper.dart';
import 'package:hvac_admin/data/datasources/hvac_realtime_service.dart';

/// Starts/stops office Realtime subscriptions and refreshes controllers on events.
class RealtimeBridge {
  RealtimeBridge({
    required HvacRealtimeService service,
    required ManagementAuthController management,
    required JobController jobs,
    required TechnicianController technicians,
    required CustomerController customers,
    required GpsMapController gps,
    InternalMessagingController? messaging,
    RealtimeEventDeduper? deduper,
    this.refreshDebounce = const Duration(milliseconds: 350),
    this.pollInterval = const Duration(seconds: 30),
  })  : _service = service,
        _management = management,
        _jobs = jobs,
        _technicians = technicians,
        _customers = customers,
        _gps = gps,
        _messaging = messaging,
        _deduper = deduper ?? RealtimeEventDeduper();

  final HvacRealtimeService _service;
  final ManagementAuthController _management;
  final JobController _jobs;
  final TechnicianController _technicians;
  final CustomerController _customers;
  final GpsMapController _gps;
  final InternalMessagingController? _messaging;
  final RealtimeEventDeduper _deduper;
  final Duration refreshDebounce;
  final Duration pollInterval;

  StreamSubscription<HvacRealtimeEvent>? _eventsSub;
  StreamSubscription<RealtimeConnectionStatus>? _connectionSub;
  Timer? _dispatchTimer;
  Timer? _techniciansTimer;
  Timer? _gpsTimer;
  Timer? _messagingTimer;
  Timer? _pollTimer;
  bool _officeActive = false;
  bool _attached = false;

  RealtimeEventDeduper get deduper => _deduper;

  void attach() {
    if (_attached) return;
    _attached = true;
    _management.addListener(_syncOfficeChannel);
    _eventsSub = _service.events.listen(_onEvent);
    _connectionSub = _service.connectionStatus.listen(_onConnectionStatus);
    _syncOfficeChannel();
  }

  Future<void> dispose() async {
    if (!_attached) return;
    _attached = false;
    _management.removeListener(_syncOfficeChannel);
    await _eventsSub?.cancel();
    _eventsSub = null;
    await _connectionSub?.cancel();
    _connectionSub = null;
    _dispatchTimer?.cancel();
    _techniciansTimer?.cancel();
    _gpsTimer?.cancel();
    _messagingTimer?.cancel();
    _stopPolling();
    await _service.dispose();
  }

  void noteLocalJobMutation(String jobId) {
    _deduper.rememberLocalMutation(HvacRealtimeTable.jobs, jobId);
  }

  void noteLocalAssignmentMutation(String assignmentOrJobId) {
    _deduper.rememberLocalMutation(HvacRealtimeTable.jobAssignments, assignmentOrJobId);
  }

  Future<void> _syncOfficeChannel() async {
    try {
      if (_management.isAuthenticated) {
        if (_officeActive) return;
        _officeActive = true;
        await _service.startOffice();
        HvacLog.info('realtime.subscribed', fields: {'audience': 'office'});
        return;
      }

      if (_officeActive) {
        _officeActive = false;
        await _service.stop();
        _stopPolling();
        HvacLog.info('realtime.stopped');
      }
    } catch (error, stack) {
      HvacLog.error('realtime.subscription_failed', error: error, stack: stack, fields: {
        'audience': 'office',
      });
    }
  }

  void _onConnectionStatus(RealtimeConnectionStatus status) {
    switch (status) {
      case RealtimeConnectionStatus.connected:
        _stopPolling();
      case RealtimeConnectionStatus.reconnecting:
        break;
      case RealtimeConnectionStatus.disconnected:
        _startPolling();
    }
  }

  void _onEvent(HvacRealtimeEvent event) {
    if (!_deduper.shouldApply(event)) return;

    switch (event.table) {
      case HvacRealtimeTable.jobs:
      case HvacRealtimeTable.jobAssignments:
      case HvacRealtimeTable.jobStatusHistory:
      case HvacRealtimeTable.jobPhotos:
      case HvacRealtimeTable.jobDocuments:
        _schedule(_dispatchTimer, (timer) => _dispatchTimer = timer, () async {
          await _jobs.refreshFromRemote();
          await _customers.refreshFromRemote();
        });
      case HvacRealtimeTable.technicians:
        _schedule(_techniciansTimer, (timer) => _techniciansTimer = timer, () async {
          await _technicians.refreshFromRemote();
          await _jobs.reloadTechnicians();
        });
      case HvacRealtimeTable.technicianLocations:
        final technicianId = event.newRecord['technician_id']?.toString() ??
            event.oldRecord['technician_id']?.toString();
        _schedule(_gpsTimer, (timer) => _gpsTimer = timer, () async {
          await _technicians.refreshFromRemote();
          if (technicianId != null) {
            await _gps.refreshLocationHistoryIfLoaded(technicianId);
          }
        });
      case HvacRealtimeTable.notifications:
        break;
      case HvacRealtimeTable.internalMessages:
      case HvacRealtimeTable.internalThreads:
        final messaging = _messaging;
        if (messaging == null) return;
        _schedule(_messagingTimer, (timer) => _messagingTimer = timer, messaging.refreshFromRemote);
    }
  }

  void _schedule(
    Timer? current,
    void Function(Timer?) store,
    Future<void> Function() action,
  ) {
    current?.cancel();
    store(
      Timer(refreshDebounce, () async {
        store(null);
        await action();
      }),
    );
  }

  void _startPolling() {
    if (_pollTimer != null || !_officeActive) return;
    _pollTimer = Timer.periodic(pollInterval, (_) => _refreshAll());
    unawaited(_refreshAll());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _jobs.refreshFromRemote(),
      _technicians.refreshFromRemote(),
      _customers.refreshFromRemote(),
      if (_messaging != null) _messaging.refreshFromRemote(),
    ]);
  }
}
