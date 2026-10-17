import 'package:hvac_admin/core/models/office_billing.dart';
import 'package:hvac_admin/core/validation/field_validators.dart';

/// Thrown when estimate/invoice data fails business validation.
class BillingValidationException implements Exception {
  const BillingValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract final class BillingValidators {
  static void validateEstimate(OfficeEstimate estimate) {
    _validateDocument(
      items: estimate.items,
      amount: estimate.amount,
      document: 'Estimate',
    );
  }

  static void validateInvoice(OfficeInvoice invoice) {
    _validateDocument(
      items: invoice.items,
      amount: invoice.amount,
      document: 'Invoice',
    );
    final dueDateError = FieldValidators.isoDate(invoice.dueDate, label: 'Due date');
    if (dueDateError != null) {
      throw BillingValidationException(dueDateError);
    }
    final dateError = FieldValidators.isoDate(invoice.date, label: 'Invoice date');
    if (dateError != null) {
      throw BillingValidationException(dateError);
    }
  }

  static void _validateDocument({
    required List<BillingLineItem> items,
    required double amount,
    required String document,
  }) {
    if (items.isEmpty) {
      throw BillingValidationException('$document must include at least one line item.');
    }

    for (final item in items) {
      if (item.description.trim().isEmpty) {
        throw BillingValidationException('Each line item needs a description.');
      }
      try {
        FieldValidators.quantity(item.quantity);
        FieldValidators.money(item.unitPrice, field: 'Unit price');
      } on FormatException catch (error) {
        throw BillingValidationException(error.message);
      }
    }

    try {
      FieldValidators.money(amount, field: '$document total');
    } on FormatException catch (error) {
      throw BillingValidationException(error.message);
    }

    if (amount <= 0) {
      throw BillingValidationException('$document total must be greater than zero.');
    }

    final computed = items.fold<double>(0, (sum, item) => sum + item.total);
    if ((computed - amount).abs() > 0.009) {
      throw BillingValidationException('$document total does not match line items.');
    }
  }
}
