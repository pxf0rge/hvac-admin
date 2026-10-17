import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/core/utils/formatters.dart';

abstract final class MessageVariables {
  /// Placeholder until a real portal token URL is minted. Never use example.com domains.
  static const unmintedLink = '';

  static Map<String, String> forJob({
    required HistoryJob job,
    OfficeCustomer? customer,
    OfficeProperty? property,
    String technicianName = 'Arctic HVAC Solutions technician',
    String eta = '30 min',
    String estimateNumber = 'EST-0000',
    String estimateUrl = unmintedLink,
    String invoiceNumber = 'INV-0000',
    String invoiceUrl = unmintedLink,
    String amountDue = '\$0.00',
    String dueDate = '—',
    String documentTitle = 'Service Authorization',
    String documentUrl = unmintedLink,
  }) {
    return {
      'customer_name': customer?.displayName ?? job.technicianName,
      'property_address': property?.fullAddress ?? '',
      'job_number': job.jobNumber,
      'service_date': formatDate(job.date),
      'technician_name': technicianName.isEmpty ? job.technicianName : technicianName,
      'eta': eta,
      'estimate_number': estimateNumber,
      'estimate_url': estimateUrl,
      'invoice_number': invoiceNumber,
      'invoice_url': invoiceUrl,
      'amount_due': amountDue,
      'due_date': dueDate,
      'document_title': documentTitle,
      'document_url': documentUrl,
    };
  }

  static Map<String, String> forCustomer({
    required OfficeCustomer customer,
    OfficeProperty? property,
    String estimateNumber = 'EST-0000',
    String estimateUrl = unmintedLink,
    String invoiceNumber = 'INV-0000',
    String invoiceUrl = unmintedLink,
    String amountDue = '\$0.00',
    String dueDate = '—',
    String documentTitle = 'Service Authorization',
    String documentUrl = unmintedLink,
  }) {
    return {
      'customer_name': customer.displayName,
      'property_address': property?.fullAddress ?? '${customer.city}, ${customer.state}',
      'job_number': '—',
      'service_date': formatDate(isoDate(DateTime.now())),
      'technician_name': 'Arctic HVAC Solutions technician',
      'eta': '30 min',
      'estimate_number': estimateNumber,
      'estimate_url': estimateUrl,
      'invoice_number': invoiceNumber,
      'invoice_url': invoiceUrl,
      'amount_due': amountDue,
      'due_date': dueDate,
      'document_title': documentTitle,
      'document_url': documentUrl,
    };
  }
}
