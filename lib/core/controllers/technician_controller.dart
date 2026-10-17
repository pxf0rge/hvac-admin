import 'package:flutter/foundation.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/core/realtime/realtime_bridge.dart';
import 'package:hvac_admin/data/repositories/technician_repository.dart';

class TechnicianController extends ChangeNotifier {
  TechnicianController(this._technicians);

  final TechnicianRepository _technicians;
  RealtimeBridge? _realtime;

  void bindRealtime(RealtimeBridge bridge) => _realtime = bridge;

  bool _loading = false;
  String? _loadError;
  List<OfficeTechnician> _list = const [];
  final Map<String, TechnicianDetail> _details = {};
  int _refreshToken = 0;

  bool get isLoading => _loading;
  String? get loadError => _loadError;
  List<OfficeTechnician> get technicians => _list;
  int get refreshToken => _refreshToken;

  OfficeTechnician? technicianById(String id) {
    for (final tech in _list) {
      if (tech.id == id) return tech;
    }
    return _details[id]?.technician;
  }

  TechnicianDetail? detailFor(String id) => _details[id];

  Future<void> load({bool force = false}) async {
    if (_loading) return;
    if (!force && _list.isNotEmpty && _loadError == null) return;
    _loading = true;
    _loadError = null;
    notifyListeners();
    try {
      _list = await _technicians.getTechnicians();
      if (force) _refreshToken += 1;
    } catch (error, stack) {
      _loadError = error.toString();
      debugPrint('TechnicianController.load failed: $error\n$stack');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refreshFromRemote() => load(force: true);

  Future<TechnicianDetail> loadDetail(String id) async {
    final detail = await _technicians.getTechnicianDetail(id);
    _details[id] = detail;
    _replaceInList(detail.technician);
    notifyListeners();
    return detail;
  }

  Future<OfficeTechnician> saveTechnician({
    String? id,
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    String? profileId,
    TechnicianStatus status = TechnicianStatus.available,
  }) async {
    final saved = await _technicians.saveTechnician(
      id: id,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      email: email,
      profileId: profileId,
      status: status,
    );
    _replaceInList(saved);
    _details.remove(saved.id);
    _refreshToken += 1;
    notifyListeners();
    return saved;
  }

  Future<OfficeTechnician> setAccountEnabled({required String id, required bool enabled}) async {
    final saved = await _technicians.setAccountEnabled(id: id, enabled: enabled);
    _replaceInList(saved);
    final detail = _details[id];
    if (detail != null) {
      _details[id] = TechnicianDetail(
        technician: saved,
        activity: detail.activity,
        recentJobs: detail.recentJobs,
        assignedAssetLabel: detail.assignedAssetLabel,
      );
    }
    _refreshToken += 1;
    notifyListeners();
    return saved;
  }

  void _replaceInList(OfficeTechnician saved) {
    final index = _list.indexWhere((tech) => tech.id == saved.id);
    if (index >= 0) {
      _list = [..._list]..[index] = saved;
    } else {
      _list = [..._list, saved];
    }
  }
}
