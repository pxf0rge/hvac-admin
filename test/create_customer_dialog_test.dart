import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/controllers/customer_controller.dart';
import 'package:hvac_admin/data/repositories/mock_repositories.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/customers/create_crm_dialog.dart';
import 'package:provider/provider.dart';

/// Opens the create-customer dialog from a minimal host so the layout can be
/// exercised at a short viewport without booting the whole admin app.
Widget _host(CustomerController controller) {
  return ChangeNotifierProvider<CustomerController>.value(
    value: controller,
    child: MaterialApp(
      theme: AppTheme.dark,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showCreateCustomerDialog(context),
              child: const Text('open dialog'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('new customer validation banner does not overflow the dialog', (WidgetTester tester) async {
    // Short viewport: the dialog is tight even before the banner appears.
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = CustomerController(MockCustomerRepository());
    addTearDown(controller.dispose);
    await tester.pumpWidget(_host(controller));

    await tester.tap(find.text('open dialog'));
    await tester.pumpAndSettle();
    expect(find.text('New customer'), findsOneWidget);

    // Submitting the empty form surfaces a validation banner inside the dialog.
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('First name is required'), findsOneWidget);
    // A RenderFlex overflow is reported as a test exception.
    expect(tester.takeException(), isNull);
    expect(find.text('Preferred language (SMS/email)'), findsOneWidget);

    // The banner makes the form taller than the dialog, so it must scroll
    // instead of overflowing (this is the layout that used to overflow).
    final scrollView = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(SingleChildScrollView),
    );
    expect(scrollView, findsOneWidget);
    final contentHeight = tester
        .getSize(find.descendant(of: scrollView, matching: find.byType(Column)).first)
        .height;
    final viewportHeight = tester.getSize(scrollView).height;
    expect(
      contentHeight,
      greaterThan(viewportHeight),
      reason: 'form must require scrolling for this regression test to be meaningful',
    );
  });

  testWidgets('invalid phone surfaces validation without overflow', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final controller = CustomerController(MockCustomerRepository());
    addTearDown(controller.dispose);
    await tester.pumpWidget(_host(controller));

    await tester.tap(find.text('open dialog'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Pat');
    await tester.enterText(find.byType(TextFormField).at(1), 'Nguyen');
    await tester.enterText(find.byType(TextFormField).at(2), '555');
    await tester.enterText(find.byType(TextFormField).at(3), 'pat@example.com');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid phone number'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
