import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('admin routes define nested detail paths', () {
    final routes = File('lib/core/routing/admin_routes.dart').readAsStringSync();
    expect(routes, contains("path: ':id'"));
    expect(routes, contains('CustomerDetailPage'));
    expect(routes, contains('PropertyDetailPage'));
    expect(routes, contains('GlobalSearchPage'));
    expect(routes, contains('AdminModule.customers'));
    expect(routes, contains('AdminModule.invoices'));
  });
}
