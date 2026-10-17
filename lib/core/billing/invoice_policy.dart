import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_billing.dart';

abstract final class InvoicePolicy {
  static bool isPastDue(OfficeInvoice invoice, {DateTime? now}) {
    if (invoice.status == InvoiceStatus.paid || invoice.status == InvoiceStatus.cancelled) {
      return false;
    }
    final due = DateTime.parse('${invoice.dueDate}T00:00:00');
    final today = now ?? DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    return due.isBefore(startOfToday);
  }

  static InvoiceStatus effectiveStatus(OfficeInvoice invoice, {DateTime? now}) {
    if (invoice.status == InvoiceStatus.sent && isPastDue(invoice, now: now)) {
      return InvoiceStatus.overdue;
    }
    return invoice.status;
  }

  static OfficeInvoice withEffectiveStatus(OfficeInvoice invoice, {DateTime? now}) {
    final status = effectiveStatus(invoice, now: now);
    return status == invoice.status ? invoice : invoice.copyWith(status: status);
  }
}

String nextInvoiceNumber() {
  final stamp = DateTime.now().millisecondsSinceEpoch % 100000;
  return 'INV-$stamp';
}
