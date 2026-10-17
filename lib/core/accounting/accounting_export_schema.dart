/// Canonical CSV columns for accounting export (Phase 14).
abstract final class AccountingExportColumns {
  static const headers = <String>[
    'invoice_number',
    'invoice_id',
    'customer_id',
    'customer_name',
    'property_address',
    'job_id',
    'issued_on',
    'due_on',
    'amount',
    'currency',
    'tax_amount',
    'invoice_status',
    'payment_status',
    'payment_provider',
    'payment_amount_total',
    'payment_paid_at',
    'payment_ids',
  ];
}

class AccountingExportRow {
  const AccountingExportRow({
    required this.invoiceNumber,
    required this.invoiceId,
    required this.customerId,
    required this.customerName,
    required this.propertyAddress,
    required this.jobId,
    required this.issuedOn,
    required this.dueOn,
    required this.amount,
    required this.currency,
    required this.taxAmount,
    required this.invoiceStatus,
    required this.paymentStatus,
    required this.paymentProvider,
    required this.paymentAmountTotal,
    required this.paymentPaidAt,
    required this.paymentIds,
  });

  final String invoiceNumber;
  final String invoiceId;
  final String customerId;
  final String customerName;
  final String propertyAddress;
  final String jobId;
  final String issuedOn;
  final String dueOn;
  final double amount;
  final String currency;
  final double taxAmount;
  final String invoiceStatus;
  final String paymentStatus;
  final String paymentProvider;
  final double paymentAmountTotal;
  final String paymentPaidAt;
  final String paymentIds;

  List<String> toCsvCells() => [
        invoiceNumber,
        invoiceId,
        customerId,
        customerName,
        propertyAddress,
        jobId,
        issuedOn,
        dueOn,
        amount.toStringAsFixed(2),
        currency,
        taxAmount.toStringAsFixed(2),
        invoiceStatus,
        paymentStatus,
        paymentProvider,
        paymentAmountTotal.toStringAsFixed(2),
        paymentPaidAt,
        paymentIds,
      ];
}
