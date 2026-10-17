import 'package:flutter/foundation.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/maintenance_agreement.dart';
import 'package:hvac_admin/data/repositories/maintenance_agreement_repository.dart';

class MaintenanceAgreementController extends ChangeNotifier {
  MaintenanceAgreementController(this._repository);

  final MaintenanceAgreementRepository _repository;
  bool _loading = false;
  List<MaintenanceAgreement> _agreements = const [];

  bool get isLoading => _loading;
  List<MaintenanceAgreement> get agreements => List.unmodifiable(_agreements);

  MaintenanceAgreement? agreementById(String id) {
    for (final agreement in _agreements) {
      if (agreement.id == id) return agreement;
    }
    return null;
  }

  List<MaintenanceAgreement> agreementsFor({
    String? propertyId,
    String? customerId,
    String? query,
    MaintenanceAgreementStatus? status,
    bool expiringOnly = false,
    int expiringWithinDays = 30,
    DateTime? now,
  }) {
    final needle = query?.trim().toLowerCase() ?? '';
    final anchor = now ?? DateTime.now();
    return [
      for (final agreement in _agreements)
        if ((propertyId == null || agreement.propertyId == propertyId) &&
            (customerId == null || agreement.customerId == customerId) &&
            (status == null || agreement.status == status) &&
            (!expiringOnly || agreement.isRenewalDueWithinDays(expiringWithinDays, now: anchor)) &&
            (needle.isEmpty ||
                agreement.title.toLowerCase().contains(needle) ||
                agreement.notes.toLowerCase().contains(needle)))
          agreement,
    ];
  }

  Future<void> load({bool force = false}) async {
    if (!force && _agreements.isNotEmpty) return;
    _loading = true;
    notifyListeners();
    try {
      _agreements = [...await _repository.getAgreements()];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<MaintenanceAgreement> saveAgreement(
    MaintenanceAgreement agreement, {
    double? annualAmount,
  }) async {
    final saved = await _repository.saveAgreement(agreement, annualAmount: annualAmount);
    final index = _agreements.indexWhere((item) => item.id == saved.id);
    if (index < 0) {
      _agreements = [..._agreements, saved];
    } else {
      final copy = [..._agreements];
      copy[index] = saved;
      _agreements = copy;
    }
    notifyListeners();
    return saved;
  }

  Future<void> setStatus(String id, MaintenanceAgreementStatus status) async {
    final current = agreementById(id);
    if (current == null) return;
    await saveAgreement(current.copyWith(status: status));
  }
}
