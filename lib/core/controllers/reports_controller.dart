import 'package:flutter/foundation.dart';
import 'package:hvac_admin/core/billing/invoice_policy.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_billing.dart';
import 'package:hvac_admin/core/models/office_payment.dart';
import 'package:hvac_admin/core/models/office_reports.dart';
import 'package:hvac_admin/core/reports/operational_metrics_calculator.dart';
import 'package:hvac_admin/data/repositories/billing_repository.dart';
import 'package:hvac_admin/data/repositories/reports_repository.dart';

class ReportsController extends ChangeNotifier {
  ReportsController(this._billing, this._reports);

  final BillingRepository _billing;
  final ReportsRepository _reports;

  OperationalReportMetrics _operational = OperationalReportMetrics.empty;
  List<OfficeInvoice> _invoices = const [];
  List<OfficePayment> _payments = const [];
  bool _loading = false;

  bool get isLoading => _loading;

  OfficeReportSnapshot get snapshot {
    final invoices = [..._invoices]..sort((a, b) => b.date.compareTo(a.date));
    final financial = _financialTotals(invoices);

    return OfficeReportSnapshot(
      paid: financial.paid,
      outstanding: financial.outstanding,
      overdue: financial.overdue,
      jobsCompleted: _operational.jobsCompleted,
      jobsOpen: _operational.jobsOpen,
      jobsTotal: _operational.jobsTotal,
      technicians: _operational.technicians,
      volume: _operational.volume,
      invoices: invoices,
      hasFinancialData: financial.hasData,
      hasOperationalData: _operational.hasOperationalData,
      hasWorkflowData: _operational.hasWorkflowData,
    );
  }

  Future<void> load({bool force = false}) async {
    if (!force && _invoices.isNotEmpty && _operational.hasOperationalData) return;
    _loading = true;
    notifyListeners();
    try {
      final results = await Future.wait([
        _billing.getInvoices(),
        _billing.getPayments(),
        _reports.loadOperationalMetrics(),
      ]);
      _invoices = [
        for (final invoice in results[0] as List<OfficeInvoice>)
          InvoicePolicy.withEffectiveStatus(invoice),
      ];
      _payments = results[1] as List<OfficePayment>;
      _operational = results[2] as OperationalReportMetrics;
    } catch (error, stack) {
      debugPrint('ReportsController.load failed: $error\n$stack');
      _invoices = const [];
      _payments = const [];
      _operational = OperationalReportMetrics.empty;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  _FinancialTotals _financialTotals(List<OfficeInvoice> invoices) {
    if (invoices.isEmpty) {
      return const _FinancialTotals(paid: 0, outstanding: 0, overdue: 0, hasData: false);
    }

    final succeededPayments = [
      for (final payment in _payments) if (payment.status == PaymentStatus.succeeded) payment,
    ];

    if (succeededPayments.isNotEmpty) {
      final paid = succeededPayments.fold<double>(0, (sum, payment) => sum + payment.amount);
      var outstanding = 0.0;
      var overdue = 0.0;
      for (final invoice in invoices) {
        switch (invoice.status) {
          case InvoiceStatus.sent:
            outstanding += invoice.amount;
          case InvoiceStatus.overdue:
            overdue += invoice.amount;
          case InvoiceStatus.paid:
          case InvoiceStatus.draft:
          case InvoiceStatus.cancelled:
            break;
        }
      }
      return _FinancialTotals(paid: paid, outstanding: outstanding, overdue: overdue, hasData: true);
    }

    var paid = 0.0;
    var outstanding = 0.0;
    var overdue = 0.0;
    for (final invoice in invoices) {
      switch (invoice.status) {
        case InvoiceStatus.paid:
          paid += invoice.amount;
        case InvoiceStatus.sent:
          outstanding += invoice.amount;
        case InvoiceStatus.overdue:
          overdue += invoice.amount;
        case InvoiceStatus.draft:
        case InvoiceStatus.cancelled:
          break;
      }
    }
    return _FinancialTotals(paid: paid, outstanding: outstanding, overdue: overdue, hasData: true);
  }
}

class _FinancialTotals {
  const _FinancialTotals({
    required this.paid,
    required this.outstanding,
    required this.overdue,
    required this.hasData,
  });

  final double paid;
  final double outstanding;
  final double overdue;
  final bool hasData;
}
