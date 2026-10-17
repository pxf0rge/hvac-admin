import 'package:flutter/foundation.dart';
import 'package:hvac_admin/core/billing/estimate_totals.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_billing.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/data/pagination/paged_result.dart';
import 'package:hvac_admin/data/repositories/billing_repository.dart';

class EstimateController extends ChangeNotifier {
  EstimateController(this._billing);

  final BillingRepository _billing;
  bool _loading = false;
  String? _error;
  int _refreshToken = 0;

  bool get isLoading => _loading;
  String? get error => _error;
  int get refreshToken => _refreshToken;

  Future<PagedResult<OfficeEstimate>> fetchEstimatesPage({
    required int offset,
    String? search,
    EstimateStatus? status,
  }) {
    return _billing.getEstimatesPage(offset: offset, search: _clean(search), status: status);
  }

  Future<OfficeEstimate?> loadEstimate(String id) => _billing.getEstimate(id);

  Future<OfficeInvoice?> invoiceForEstimate(String estimateId) => _billing.getInvoiceForEstimate(estimateId);

  Future<OfficeEstimate> saveDraft({
    OfficeEstimate? existing,
    required String propertyId,
    required String jobId,
    required String notes,
    required List<BillingLineItem> items,
  }) async {
    final estimate = existing ??
        OfficeEstimate(
          id: 'est_${DateTime.now().microsecondsSinceEpoch}',
          number: nextEstimateNumber(),
          status: EstimateStatus.draft,
          date: isoDate(DateTime.now()),
          propertyId: propertyId,
          jobId: jobId,
          notes: notes,
          items: items,
        );
    final saved = await _billing.saveEstimate(
      estimate.copyWith(notes: notes, items: items, propertyId: propertyId, jobId: jobId),
    );
    _refreshToken += 1;
    notifyListeners();
    return saved;
  }

  Future<OfficeEstimate> markSent(String id) => _updateStatus(id, EstimateStatus.sent);

  Future<OfficeEstimate> markApproved(String id) => _updateStatus(id, EstimateStatus.approved);

  Future<OfficeEstimate> markDeclined(String id) => _updateStatus(id, EstimateStatus.declined);

  Future<OfficeInvoice> convertToInvoice(String estimateId) async {
    final invoice = await _billing.convertEstimateToInvoice(estimateId);
    _refreshToken += 1;
    notifyListeners();
    return invoice;
  }

  Future<OfficeEstimate> _updateStatus(String id, EstimateStatus status) async {
    final saved = await _billing.updateEstimateStatus(id, status);
    _refreshToken += 1;
    notifyListeners();
    return saved;
  }

  EstimateTotals totalsFor(OfficeEstimate estimate) => EstimateTotals.fromItems(estimate.items);

  String? _clean(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
