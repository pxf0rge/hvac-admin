import 'package:hvac_admin/core/models/office_billing.dart';

class EstimateTotals {
  const EstimateTotals({
    required this.subtotal,
    required this.taxRate,
    required this.tax,
    required this.total,
  });

  final double subtotal;
  final double taxRate;
  final double tax;
  final double total;

  static const defaultTaxRate = 0.0825;

  factory EstimateTotals.fromItems(
    List<BillingLineItem> items, {
    double taxRate = defaultTaxRate,
  }) {
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.total);
    final tax = subtotal * taxRate;
    return EstimateTotals(subtotal: subtotal, taxRate: taxRate, tax: tax, total: subtotal + tax);
  }
}

String nextEstimateNumber() {
  final stamp = DateTime.now().millisecondsSinceEpoch % 100000;
  return 'EST-$stamp';
}
