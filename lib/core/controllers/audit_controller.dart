import 'package:flutter/foundation.dart';
import 'package:hvac_admin/core/audit/audit_actions.dart';
import 'package:hvac_admin/core/models/audit_log_record.dart';
import 'package:hvac_admin/data/repositories/audit_repository.dart';

class AuditController extends ChangeNotifier {
  AuditController(this._repository);

  final AuditRepository _repository;
  List<AuditLogRecord> _entries = const [];
  bool _loading = false;
  String? _error;
  String? _actionFilter;
  String _actorQuery = '';
  DateTime? _from;
  DateTime? _to;

  bool get isLoading => _loading;
  String? get error => _error;
  List<AuditLogRecord> get entries => List.unmodifiable(_entries);
  String? get actionFilter => _actionFilter;
  String get actorQuery => _actorQuery;
  DateTime? get from => _from;
  DateTime? get to => _to;

  static const actionOptions = <String>[
    AuditActions.authLogin,
    AuditActions.settingsUpdate,
    AuditActions.templatePublish,
    AuditActions.invoiceVoid,
    AuditActions.jobAssign,
    AuditActions.jobReassign,
    AuditActions.jobUnassign,
    AuditActions.invoiceStatus,
    AuditActions.accountingExport,
  ];

  Future<void> load({
    bool force = false,
    String? action,
    String? actorQuery,
    DateTime? from,
    DateTime? to,
  }) async {
    if (!force && _entries.isNotEmpty && action == null && actorQuery == null && from == null && to == null) {
      return;
    }
    _actionFilter = action ?? _actionFilter;
    _actorQuery = actorQuery ?? _actorQuery;
    _from = from ?? _from;
    _to = to ?? _to;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _entries = await _repository.queryEntries(
        action: _actionFilter,
        actorQuery: _actorQuery.isEmpty ? null : _actorQuery,
        from: _from,
        to: _to,
      );
    } catch (error, stack) {
      _error = error.toString();
      debugPrint('AuditController.load failed: $error\n$stack');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> applyFilters({
    String? action,
    required String actorQuery,
    DateTime? from,
    DateTime? to,
  }) async {
    await load(
      force: true,
      action: action?.isEmpty == true ? null : action,
      actorQuery: actorQuery,
      from: from,
      to: to,
    );
  }

  void clearFilters() {
    _actionFilter = null;
    _actorQuery = '';
    _from = null;
    _to = null;
  }
}
