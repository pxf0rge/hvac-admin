import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_billing.dart';
import 'package:hvac_admin/core/models/office_payment.dart';
import 'package:hvac_admin/data/pagination/paged_result.dart';

abstract class BillingRepository {
  Future<List<OfficeEstimate>> getEstimates({EstimateStatus? status});
  Future<PagedResult<OfficeEstimate>> getEstimatesPage({
    int offset = 0,
    int limit = ListQuery.defaultLimit,
    String? search,
    EstimateStatus? status,
  });
  Future<OfficeEstimate?> getEstimate(String id);
  Future<OfficeEstimate> saveEstimate(OfficeEstimate estimate);
  Future<OfficeEstimate> updateEstimateStatus(String id, EstimateStatus status);
  Future<OfficeInvoice?> getInvoiceForEstimate(String estimateId);
  Future<OfficeInvoice> convertEstimateToInvoice(String estimateId);
  Future<List<OfficeInvoice>> getInvoices({InvoiceStatus? status});
  Future<PagedResult<OfficeInvoice>> getInvoicesPage({
    int offset = 0,
    int limit = ListQuery.defaultLimit,
    String? search,
    InvoiceStatus? status,
    bool overdueOnly = false,
    double? minAmount,
  });
  Future<OfficeInvoice?> getInvoice(String id);
  Future<OfficeInvoice> saveInvoice(OfficeInvoice invoice);
  Future<OfficeInvoice> updateInvoiceStatus(String id, InvoiceStatus status);
  Future<List<OfficePayment>> getPayments({String? invoiceId});
  Future<OfficePayment?> paymentByProviderId(String provider, String providerPaymentId);
  Future<OfficePayment> savePayment(OfficePayment payment);
}
