import 'package:flutter/foundation.dart';

import 'package:hvac_admin/core/billing/estimate_totals.dart';

import 'package:hvac_admin/core/billing/invoice_policy.dart';

import 'package:hvac_admin/core/enums/domain_enums.dart';

import 'package:hvac_admin/core/models/office_billing.dart';

import 'package:hvac_admin/core/models/office_payment.dart';

import 'package:hvac_admin/core/payments/payment_provider.dart';

import 'package:hvac_admin/core/payments/payment_service.dart';

import 'package:hvac_admin/core/utils/formatters.dart';

import 'package:hvac_admin/data/pagination/paged_result.dart';

import 'package:hvac_admin/data/repositories/billing_repository.dart';



class InvoiceController extends ChangeNotifier {

  InvoiceController(this._billing, {PaymentService? payments})

      : _payments = payments ?? PaymentService(repository: _billing, provider: MockPaymentProvider());



  final BillingRepository _billing;

  final PaymentService _payments;

  int _refreshToken = 0;

  final Map<String, List<OfficePayment>> _paymentsByInvoice = {};



  int get refreshToken => _refreshToken;



  Future<PagedResult<OfficeInvoice>> fetchInvoicesPage({

    required int offset,

    String? search,

    InvoiceStatus? status,

    bool overdueOnly = false,

    double? minAmount,

  }) {

    return _billing.getInvoicesPage(

      offset: offset,

      search: _clean(search),

      status: status,

      overdueOnly: overdueOnly,

      minAmount: minAmount,

    );

  }



  Future<OfficeInvoice?> loadInvoice(String id) async {

    final invoice = await _billing.getInvoice(id);

    if (invoice == null) return null;

    await loadPayments(id);

    return InvoicePolicy.withEffectiveStatus(invoice);

  }



  Future<void> loadPayments(String invoiceId) async {

    final payments = await _billing.getPayments(invoiceId: invoiceId);

    _paymentsByInvoice[invoiceId] = payments;

    notifyListeners();

  }



  List<OfficePayment> paymentsForInvoice(String invoiceId) {

    return List.unmodifiable(_paymentsByInvoice[invoiceId] ?? const []);

  }  Future<OfficeInvoice> saveDraft({
    OfficeInvoice? existing,
    required String propertyId,
    required String jobId,
    required String notes,
    required List<BillingLineItem> items,
    String? estimateId,
    int dueInDays = 14,
    double? taxRatePct,
  }) async {
    final issued = isoDate(DateTime.now());
    final due = isoDate(DateTime.now().add(Duration(days: dueInDays)));
    final invoice = existing ??
        OfficeInvoice(
          id: 'inv_${DateTime.now().microsecondsSinceEpoch}',
          number: nextInvoiceNumber(),
          status: InvoiceStatus.draft,
          date: issued,
          dueDate: due,
          propertyId: propertyId,
          jobId: jobId,
          estimateId: estimateId,
          notes: notes,
          items: items,
          taxRatePct: taxRatePct,
        );
    final saved = await _billing.saveInvoice(
      invoice.copyWith(
        notes: notes,
        items: items,
        propertyId: propertyId,
        jobId: jobId,
        estimateId: estimateId ?? invoice.estimateId,
        taxRatePct: taxRatePct ?? invoice.taxRatePct,
      ),
    );
    _refreshToken += 1;
    notifyListeners();
    return saved;
  }



  Future<OfficeInvoice> markSent(String id) => _updateStatus(id, InvoiceStatus.sent);



  Future<OfficeInvoice> markPaid(String id) => _updateStatus(id, InvoiceStatus.paid);



  Future<OfficeInvoice> markVoid(String id) => _updateStatus(id, InvoiceStatus.cancelled);



  Future<PaymentCheckoutSession> startOnlineCheckout(String invoiceId) async {

    final invoice = await _billing.getInvoice(invoiceId);

    if (invoice == null) throw StateError('Invoice not found');

    final session = await _payments.startCheckout(invoice);

    _paymentsByInvoice[invoiceId] = [

      session.payment,

      ...paymentsForInvoice(invoiceId).where((payment) => payment.id != session.payment.id),

    ];

    notifyListeners();

    return session;

  }



  Future<OfficePayment> recordManualPayment(String invoiceId) async {

    final invoice = await _billing.getInvoice(invoiceId);

    if (invoice == null) throw StateError('Invoice not found');

    final payment = await _payments.recordManualPayment(invoice);

    _paymentsByInvoice[invoiceId] = [

      payment,

      ...paymentsForInvoice(invoiceId).where((item) => item.id != payment.id),

    ];

    _refreshToken += 1;

    notifyListeners();

    return payment;

  }



  EstimateTotals totalsFor(OfficeInvoice invoice) => EstimateTotals.fromItems(invoice.items);



  InvoiceStatus displayStatus(OfficeInvoice invoice) => InvoicePolicy.effectiveStatus(invoice);



  Future<OfficeInvoice> _updateStatus(String id, InvoiceStatus status) async {

    final saved = await _billing.updateInvoiceStatus(id, status);

    _refreshToken += 1;

    notifyListeners();

    return InvoicePolicy.withEffectiveStatus(saved);

  }



  String? _clean(String? value) {

    final trimmed = value?.trim();

    if (trimmed == null || trimmed.isEmpty) return null;

    return trimmed;

  }

}


