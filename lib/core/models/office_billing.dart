import 'package:hvac_admin/core/enums/domain_enums.dart';

class BillingLineItem {
  const BillingLineItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
  });

  final String description;
  final double quantity;
  final double unitPrice;

  double get total => quantity * unitPrice;
}

class OfficeEstimate {
  const OfficeEstimate({
    required this.id,
    required this.number,
    required this.status,
    required this.date,
    required this.propertyId,
    required this.jobId,
    required this.notes,
    required this.items,
  });

  final String id;
  final String number;
  final EstimateStatus status;
  final String date;
  final String propertyId;
  final String jobId;
  final String notes;
  final List<BillingLineItem> items;

  double get amount => items.fold(0, (sum, item) => sum + item.total);

  OfficeEstimate copyWith({
    String? id,
    String? number,
    EstimateStatus? status,
    String? date,
    String? propertyId,
    String? jobId,
    String? notes,
    List<BillingLineItem>? items,
  }) {
    return OfficeEstimate(
      id: id ?? this.id,
      number: number ?? this.number,
      status: status ?? this.status,
      date: date ?? this.date,
      propertyId: propertyId ?? this.propertyId,
      jobId: jobId ?? this.jobId,
      notes: notes ?? this.notes,
      items: items ?? this.items,
    );
  }
}

class OfficeInvoice {
  const OfficeInvoice({
    required this.id,
    required this.number,
    required this.status,
    required this.date,
    required this.dueDate,
    required this.propertyId,
    required this.jobId,
    required this.notes,
    required this.items,
    this.estimateId,
    this.taxRatePct,
  });

  final String id;
  final String number;
  final InvoiceStatus status;
  final String date;
  final String dueDate;
  final String propertyId;
  final String jobId;
  final String? estimateId;
  final String notes;
  final List<BillingLineItem> items;

  /// Phase 22: invoice-level tax percentage (e.g. 8.25). NULL = tax-free.
  final double? taxRatePct;

  /// Pre-tax subtotal (line items).
  double get amount => items.fold(0, (sum, item) => sum + item.total);

  /// Phase 22: tax amount derived from the invoice-level rate.
  double get taxAmount => amount * (taxRatePct ?? 0) / 100.0;

  /// Tax-inclusive grand total (what the customer owes).
  double get grandTotal => amount + taxAmount;

  OfficeInvoice copyWith({
    String? id,
    String? number,
    InvoiceStatus? status,
    String? date,
    String? dueDate,
    String? propertyId,
    String? jobId,
    String? estimateId,
    String? notes,
    List<BillingLineItem>? items,
    double? taxRatePct,
  }) {
    return OfficeInvoice(
      id: id ?? this.id,
      number: number ?? this.number,
      status: status ?? this.status,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      propertyId: propertyId ?? this.propertyId,
      jobId: jobId ?? this.jobId,
      estimateId: estimateId ?? this.estimateId,
      notes: notes ?? this.notes,
      items: items ?? this.items,
      taxRatePct: taxRatePct ?? this.taxRatePct,
    );
  }
}
