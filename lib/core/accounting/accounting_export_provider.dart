import 'package:hvac_admin/core/accounting/accounting_export_schema.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_billing.dart';
import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/core/models/office_payment.dart';

/// Future API connectors (QuickBooks/Xero) implement this without OAuth yet.
abstract class AccountingExportProvider {
  String get id;
  Future<List<AccountingExportRow>> buildRows({
    required List<OfficeInvoice> invoices,
    required List<OfficePayment> payments,
    required Map<String, OfficeProperty> propertiesById,
    required Map<String, OfficeCustomer> customersById,
  });
}

/// Local CSV row builder — default accounting bridge.
class LocalAccountingCsvProvider implements AccountingExportProvider {
  const LocalAccountingCsvProvider();

  @override
  String get id => 'local_csv';

  @override
  Future<List<AccountingExportRow>> buildRows({
    required List<OfficeInvoice> invoices,
    required List<OfficePayment> payments,
    required Map<String, OfficeProperty> propertiesById,
    required Map<String, OfficeCustomer> customersById,
  }) async {
    final paymentsByInvoice = <String, List<OfficePayment>>{};
    for (final payment in payments) {
      paymentsByInvoice.putIfAbsent(payment.invoiceId, () => []).add(payment);
    }

    return [
      for (final invoice in invoices)
        _rowFor(
          invoice,
          paymentsByInvoice[invoice.id] ?? const [],
          propertiesById,
          customersById,
        ),
    ];
  }

  AccountingExportRow _rowFor(
    OfficeInvoice invoice,
    List<OfficePayment> invoicePayments,
    Map<String, OfficeProperty> propertiesById,
    Map<String, OfficeCustomer> customersById,
  ) {
    final property = propertiesById[invoice.propertyId];
    final customer = property == null ? null : customersById[property.customerId];
    final succeeded = [
      for (final p in invoicePayments)
        if (p.status == PaymentStatus.succeeded) p,
    ];
    final paidTotal = succeeded.fold<double>(0, (sum, p) => sum + p.amount);
    final latestPaidAt = succeeded
        .map((p) => p.paidAt ?? p.createdAt)
        .where((s) => s.isNotEmpty)
        .fold<String>('', (best, next) => next.compareTo(best) > 0 ? next : best);
    final providers = {
      for (final p in succeeded) p.provider,
    }.toList()
      ..sort();

    String paymentStatus;
    if (invoice.status == InvoiceStatus.paid || paidTotal >= invoice.amount - 0.001) {
      paymentStatus = 'paid';
    } else if (paidTotal > 0) {
      paymentStatus = 'partial';
    } else if (invoice.status == InvoiceStatus.cancelled) {
      paymentStatus = 'void';
    } else {
      paymentStatus = 'unpaid';
    }

    return AccountingExportRow(
      invoiceNumber: invoice.number,
      invoiceId: invoice.id,
      customerId: customer?.id ?? '',
      customerName: customer?.displayName ?? '',
      propertyAddress: property?.fullAddress ?? '',
      jobId: invoice.jobId,
      issuedOn: invoice.date,
      dueOn: invoice.dueDate,
      amount: invoice.amount,
      currency: 'usd',
      // Phase 22: real invoice-level tax (legacy tax-free invoices stay 0).
      taxAmount: invoice.taxAmount,
      invoiceStatus: invoice.status.name,
      paymentStatus: paymentStatus,
      paymentProvider: providers.isEmpty ? '' : providers.join('|'),
      paymentAmountTotal: paidTotal,
      paymentPaidAt: latestPaidAt.length >= 10 ? latestPaidAt.substring(0, 10) : latestPaidAt,
      paymentIds: [
        for (final p in succeeded) p.id,
      ].join('|'),
    );
  }
}

/// Stub for a future QuickBooks Online connector (no OAuth in this phase).
class QuickBooksAccountingExportStub implements AccountingExportProvider {
  const QuickBooksAccountingExportStub();

  @override
  String get id => 'quickbooks_stub';

  @override
  Future<List<AccountingExportRow>> buildRows({
    required List<OfficeInvoice> invoices,
    required List<OfficePayment> payments,
    required Map<String, OfficeProperty> propertiesById,
    required Map<String, OfficeCustomer> customersById,
  }) {
    throw UnimplementedError(
      'QuickBooks connector is not enabled. Use LocalAccountingCsvProvider and import CSV.',
    );
  }
}
