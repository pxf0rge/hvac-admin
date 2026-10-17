import 'package:hvac_admin/core/models/office_billing.dart';
import 'package:hvac_admin/data/mappers/enum_db.dart';
import 'package:hvac_admin/data/mappers/mapper_helpers.dart';

abstract final class BillingMapper {
  static BillingLineItem lineItemFromRow(Map<String, dynamic> row) {
    return BillingLineItem(
      description: MapperHelpers.str(row['description']),
      quantity: MapperHelpers.dbl(row['quantity']),
      unitPrice: MapperHelpers.dbl(row['unit_price']),
    );
  }

  static Map<String, dynamic> lineItemToRow(BillingLineItem item, {int sortOrder = 0}) => {
        'description': item.description,
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
        'sort_order': sortOrder,
      };

  static OfficeEstimate estimateFromRow(
    Map<String, dynamic> row, {
    List<BillingLineItem> items = const [],
  }) {
    return OfficeEstimate(
      id: MapperHelpers.uuid(row['id']),
      number: MapperHelpers.str(row['number']),
      status: EnumDb.estimateStatusFromDb(MapperHelpers.str(row['status'])),
      date: MapperHelpers.dateOnly(row['issued_on']),
      propertyId: MapperHelpers.uuid(row['property_id']),
      jobId: MapperHelpers.uuid(row['job_id']),
      notes: MapperHelpers.str(row['notes']),
      items: items,
    );
  }

  static Map<String, dynamic> estimateToRow(OfficeEstimate estimate) => {
        'id': estimate.id,
        'number': estimate.number,
        'status': EnumDb.estimateStatus(estimate.status),
        'issued_on': estimate.date,
        'property_id': estimate.propertyId,
        'job_id': estimate.jobId,
        'notes': estimate.notes,
      };

  static OfficeInvoice invoiceFromRow(
    Map<String, dynamic> row, {
    List<BillingLineItem> items = const [],
  }) {
    return OfficeInvoice(
      id: MapperHelpers.uuid(row['id']),
      number: MapperHelpers.str(row['number']),
      status: EnumDb.invoiceStatusFromDb(MapperHelpers.str(row['status'])),
      date: MapperHelpers.dateOnly(row['issued_on']),
      dueDate: MapperHelpers.dateOnly(row['due_on']),
      propertyId: MapperHelpers.uuid(row['property_id']),
      jobId: MapperHelpers.uuid(row['job_id']),
      estimateId: MapperHelpers.strOrNull(row['estimate_id']),
      notes: MapperHelpers.str(row['notes']),
      // Phase 22: invoice-level tax rate (numeric pct or NULL).
      taxRatePct: row['tax_rate_pct'] == null ? null : (row['tax_rate_pct'] as num).toDouble(),
      items: items,
    );
  }

  static Map<String, dynamic> invoiceToRow(OfficeInvoice invoice) => {
        'id': invoice.id,
        'number': invoice.number,
        'status': EnumDb.invoiceStatus(invoice.status),
        'issued_on': invoice.date,
        'due_on': invoice.dueDate,
        'property_id': invoice.propertyId,
        'job_id': invoice.jobId,
        if (invoice.estimateId != null) 'estimate_id': invoice.estimateId,
        'notes': invoice.notes,
        // Phase 22: NULL stays NULL (tax-free legacy invoices).
        'tax_rate_pct': invoice.taxRatePct,
      };

  static List<BillingLineItem> lineItemsFromNested(dynamic nested) {
    if (nested is! List) return const [];
    final rows = <Map<String, dynamic>>[
      for (final entry in nested)
        if (entry is Map<String, dynamic>)
          MapperHelpers.row(entry)
        else if (entry is Map)
          MapperHelpers.row(Map<String, dynamic>.from(entry)),
    ];
    rows.sort((a, b) {
      final left = MapperHelpers.intOrNull(a['sort_order']) ?? 0;
      final right = MapperHelpers.intOrNull(b['sort_order']) ?? 0;
      return left.compareTo(right);
    });
    return [for (final row in rows) lineItemFromRow(row)];
  }
}
