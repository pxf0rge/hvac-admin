import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/app/hvac_admin_app.dart';
import 'package:hvac_admin/core/controllers/management_auth_controller.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/data/datasources/mock_management_auth_service.dart';
import 'package:hvac_admin/core/controllers/fleet_controller.dart';
import 'package:hvac_admin/core/controllers/inventory_controller.dart';
import 'package:hvac_admin/core/controllers/job_controller.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/data/datasources/mock_document_templates.dart';
import 'package:hvac_admin/data/datasources/mock_seed_data.dart';
import 'package:hvac_admin/data/repositories/mock_repositories.dart';
import 'package:hvac_admin/data/wiring/repository_wiring.dart';
import 'package:hvac_admin/features/shared/widgets/map_address_picker.dart';
import 'package:provider/provider.dart';

Future<void> _signIn(WidgetTester tester, String email, String password) async {
  await tester.enterText(find.byType(TextFormField).at(0), email);
  await tester.enterText(find.byType(TextFormField).at(1), password);
  await tester.tap(find.text('Sign in'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('unauthenticated users land on login', (WidgetTester tester) async {
    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();

    expect(find.text('Office sign in'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('owner can sign in and reach dashboard', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();

    await _signIn(tester, 'diana@hvacpro.com', 'OfficeLead!');

    expect(find.byKey(const Key('dashboard')), findsOneWidget);
    expect(find.textContaining('Welcome back'), findsOneWidget);
    expect(find.byKey(const Key('dashboard-financial')), findsOneWidget);
    expect(find.byKey(const Key('dashboard-todays-jobs')), findsOneWidget);

    final context = tester.element(find.byKey(const Key('dashboard')));
    final auth = context.read<ManagementAuthController>();
    expect(auth.canOpen(AdminModule.invoices), isTrue);
    expect(auth.canOpen(AdminModule.reports), isTrue);
  });

  testWidgets('office staff sidebar hides financial modules', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();

    await _signIn(tester, 'marcus@hvacpro.com', 'FrontDesk!');

    expect(find.byKey(const Key('admin-nav-customers')), findsOneWidget);
    expect(find.byKey(const Key('admin-nav-invoices')), findsNothing);
    expect(find.byKey(const Key('admin-nav-reports')), findsNothing);
    expect(find.byKey(const Key('dashboard-financial')), findsNothing);
    expect(find.text('Financial metrics are hidden for this role.'), findsOneWidget);
  });

  testWidgets('office staff direct URL to invoices redirects to dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();

    await _signIn(tester, 'marcus@hvacpro.com', 'FrontDesk!');

    final context = tester.element(find.textContaining('Welcome back'));
    GoRouter.of(context).go('/invoices');
    await tester.pumpAndSettle();

    expect(find.textContaining('Welcome back'), findsOneWidget);
    expect(find.text('Invoices module arrives'), findsNothing);
  });

  testWidgets('office staff direct URL to reports redirects to dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();

    await _signIn(tester, 'marcus@hvacpro.com', 'FrontDesk!');

    final context = tester.element(find.textContaining('Welcome back'));
    GoRouter.of(context).go('/reports');
    await tester.pumpAndSettle();

    expect(find.textContaining('Welcome back'), findsOneWidget);
    expect(find.byKey(const Key('reports')), findsNothing);
  });

  testWidgets('owner can navigate to nested customer detail', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();
    await _signIn(tester, 'diana@hvacpro.com', 'OfficeLead!');

    await tester.tap(find.byKey(const Key('admin-nav-customers')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('customers-list')), findsOneWidget);
    expect(find.text('Pat Nguyen'), findsOneWidget);

    await tester.tap(find.text('Pat Nguyen'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('customer-detail')), findsOneWidget);
    expect(find.textContaining('77 Oak Lane'), findsWidgets);
  });

  testWidgets('search route is reachable from app bar', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();
    await _signIn(tester, 'diana@hvacpro.com', 'OfficeLead!');

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    expect(find.text('Global search'), findsOneWidget);
    expect(find.text('Property search'), findsNothing);
  });

  testWidgets('search by address opens property history', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();
    await _signIn(tester, 'diana@hvacpro.com', 'OfficeLead!');

    final context = tester.element(find.byKey(const Key('dashboard')));
    GoRouter.of(context).go('/search');
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('global-search-field')), 'Oak Lane');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: find.byKey(const Key('global-search')), matching: find.text('Properties')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: find.byKey(const Key('global-search')), matching: find.text('Jobs')),
      findsOneWidget,
    );
    expect(find.text('77 Oak Lane'), findsOneWidget);
    await tester.tap(find.text('77 Oak Lane'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('property-history')), findsOneWidget);
    expect(find.text('Financial'), findsOneWidget);
    expect(find.text('Maintenance agreements'), findsOneWidget);
    expect(find.byKey(Key('property-maintenance-${MockSeedIds.maintenanceAgreementId}')), findsOneWidget);
  });

  testWidgets('office staff property history hides financial tab', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();
    await _signIn(tester, 'marcus@hvacpro.com', 'FrontDesk!');

    final context = tester.element(find.textContaining('Welcome back'));
    GoRouter.of(context).go('/properties/${MockSeedIds.propertyId}');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('property-history')), findsOneWidget);
    expect(find.text('Financial'), findsNothing);
    expect(find.text('Timeline'), findsOneWidget);
  });

  testWidgets('technician login shows clear rejection message', (WidgetTester tester) async {
    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'carlos@hvacpro.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'FieldReady!');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Technician accounts must use the field app'), findsOneWidget);
    expect(find.text('Office sign in'), findsOneWidget);
  });

  testWidgets('dashboard quick actions navigate to modules', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();
    await _signIn(tester, 'diana@hvacpro.com', 'OfficeLead!');

    await tester.tap(find.text('Open dispatch'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dispatch-board')), findsOneWidget);
    expect(find.text('Dispatch board'), findsOneWidget);

    final context = tester.element(find.byKey(const Key('dispatch-board')));
    GoRouter.of(context).go('/dashboard');
    await tester.pumpAndSettle();

    await tester.tap(find.text('View calendar'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('calendar-page')), findsOneWidget);
    expect(find.byKey(const Key('calendar-week-view')), findsOneWidget);
    expect(find.textContaining('Same jobs as Dispatch'), findsOneWidget);
  });

  testWidgets('calendar day view and technician filter', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();
    await _signIn(tester, 'diana@hvacpro.com', 'OfficeLead!');

    GoRouter.of(tester.element(find.byKey(const Key('dashboard')))).go('/calendar');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('calendar-page')), findsOneWidget);
    await tester.tap(find.text('Day'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('calendar-day-view')), findsOneWidget);

    await tester.tap(find.byKey(const Key('calendar-technician-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Unassigned').last);
    await tester.pumpAndSettle();

    expect(find.byKey(Key('calendar-job-${MockSeedIds.unassignedJobId}')), findsOneWidget);
  });

  testWidgets('dispatch drag assigns unassigned job to technician', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();
    await _signIn(tester, 'diana@hvacpro.com', 'OfficeLead!');

    GoRouter.of(tester.element(find.byKey(const Key('dashboard')))).go('/dispatch');
    await tester.pumpAndSettle();

    final unassignedColumn = find.byKey(const Key('dispatch-column-unassigned'));
    final carlosColumn = find.byKey(const Key('dispatch-column-${MockSeedIds.technicianId}'));
    expect(unassignedColumn, findsOneWidget);
    expect(carlosColumn, findsOneWidget);

    final unassignedJob = find.byKey(const Key('dispatch-job-${MockSeedIds.unassignedJobId}'));
    expect(unassignedJob, findsOneWidget);
    await tester.drag(
      unassignedJob,
      tester.getCenter(carlosColumn) - tester.getCenter(unassignedJob),
    );
    await tester.pumpAndSettle();

    final jobController = tester.element(carlosColumn).read<JobController>();
    expect(
      jobController.jobsForTechnician(MockSeedIds.technicianId).any((job) => job.id == MockSeedIds.unassignedJobId),
      isTrue,
    );
  });

  testWidgets('owner can open equipment list and detail', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();
    await _signIn(tester, 'diana@hvacpro.com', 'OfficeLead!');

    await tester.tap(find.byKey(const Key('admin-nav-equipment')));
    await tester.pumpAndSettle();

    expect(find.text('Equipment'), findsWidgets);
    expect(find.textContaining('Carrier'), findsOneWidget);

    await tester.tap(find.textContaining('Carrier'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('equipment-detail')), findsOneWidget);
    expect(find.text('Warranty'), findsOneWidget);
  });

  testWidgets('warranty search finds Pat Nguyen compressor warranty', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();
    await _signIn(tester, 'diana@hvacpro.com', 'OfficeLead!');

    final context = tester.element(find.byKey(const Key('dashboard')));
    GoRouter.of(context).go('/equipment/warranty-search');
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('warranty-search-field')), 'Pat Nguyen');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Compressor'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
  });

  testWidgets('owner can open jobs list and seeded job detail', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();
    await _signIn(tester, 'diana@hvacpro.com', 'OfficeLead!');

    await tester.tap(find.byKey(const Key('admin-nav-jobs')));
    await tester.pumpAndSettle();

    expect(find.textContaining('JOB-'), findsWidgets);

    await tester.tap(find.textContaining('JOB-RLS-21'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('job-detail')), findsOneWidget);
    expect(find.text('Status history'), findsOneWidget);
    expect(find.text('Pat Nguyen'), findsOneWidget);
  });

  testWidgets('owner can open technicians list and detail', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();
    await _signIn(tester, 'diana@hvacpro.com', 'OfficeLead!');

    GoRouter.of(tester.element(find.byKey(const Key('dashboard')))).go('/technicians');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('technicians-page')), findsOneWidget);
    expect(find.byKey(Key('technician-row-${MockSeedIds.technicianId}')), findsOneWidget);
    await tester.tap(find.byKey(Key('technician-row-${MockSeedIds.technicianId}')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('technician-detail')), findsOneWidget);
    expect(find.text('Fleet assets'), findsOneWidget);
    expect(find.text('Truck 12'), findsOneWidget);
  });

  testWidgets('owner can open fleet page and reassign truck', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();
    await _signIn(tester, 'diana@hvacpro.com', 'OfficeLead!');

    GoRouter.of(tester.element(find.byKey(const Key('dashboard')))).go('/fleet');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('fleet-page')), findsOneWidget);
    expect(find.byKey(Key('fleet-row-${MockSeedIds.fleetTruckId}')), findsOneWidget);
    expect(find.text('Truck 12'), findsOneWidget);

    await tester.tap(find.byKey(Key('fleet-row-${MockSeedIds.fleetTruckId}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('fleet-assign-${MockSeedIds.fleetTruckId}')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fleet-assign-confirm')));
    await tester.pumpAndSettle();

    final fleet = tester.element(find.byKey(const Key('fleet-page'))).read<FleetController>();
    final truck = fleet.assetById(MockSeedIds.fleetTruckId);
    expect(truck?.currentTechnicianId, isNotNull);
  });

  testWidgets('owner can open technician GPS map', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();
    await _signIn(tester, 'diana@hvacpro.com', 'OfficeLead!');

    GoRouter.of(tester.element(find.byKey(const Key('dashboard')))).go('/technicians/map');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('gps-map-page')), findsOneWidget);
    expect(find.byKey(const Key('technician-map')), findsOneWidget);
    expect(find.byKey(Key('map-marker-${MockSeedIds.technicianId}')), findsOneWidget);
    expect(find.text('Carlos Rodriguez'), findsWidgets);
    expect(find.text('On Job'), findsWidgets);

    await tester.tap(find.text('List'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('gps-list-view')), findsOneWidget);
    expect(find.byKey(Key('gps-list-${MockSeedIds.technicianId}')), findsOneWidget);
  });

  testWidgets('owner can open document template library and editor', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();
    await _signIn(tester, 'diana@hvacpro.com', 'OfficeLead!');

    GoRouter.of(tester.element(find.byKey(const Key('dashboard')))).go('/documents');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('documents-page')), findsOneWidget);
    expect(find.byKey(Key('template-row-${MockDocumentTemplates.serviceAuthorizationId}')), findsOneWidget);
    expect(find.text('Service Authorization'), findsOneWidget);

    await tester.tap(find.text('Service Authorization'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('template-editor')), findsOneWidget);
    expect(find.byKey(const Key('template-preview')), findsOneWidget);
    expect(find.textContaining('Pat Nguyen'), findsOneWidget);
    expect(find.byKey(const Key('template-version-2')), findsOneWidget);
  });

  testWidgets('customer detail shows inbound SMS history', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();
    await _signIn(tester, 'diana@hvacpro.com', 'OfficeLead!');

    GoRouter.of(tester.element(find.byKey(const Key('dashboard')))).go(
      '/customers/${MockSeedIds.customerId}',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('customer-detail')), findsOneWidget);
    expect(find.byKey(Key('customer-messages-${MockSeedIds.customerId}')), findsOneWidget);
    expect(find.textContaining('Thanks! We will be home.'), findsOneWidget);
    expect(find.text('Inbound'), findsWidgets);
  });

  testWidgets('owner can open estimates list and detail', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();
    await _signIn(tester, 'diana@hvacpro.com', 'OfficeLead!');

    GoRouter.of(tester.element(find.byKey(const Key('dashboard')))).go('/estimates');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('estimates-page')), findsOneWidget);
    expect(find.byKey(Key('estimate-row-${MockSeedIds.estimateId}')), findsOneWidget);
    expect(find.text('EST-RLS-21'), findsOneWidget);

    await tester.tap(find.text('EST-RLS-21'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('estimate-detail')), findsOneWidget);
    expect(find.byKey(const Key('estimate-preview')), findsOneWidget);
    expect(find.textContaining('Capacitor'), findsOneWidget);
  });

  testWidgets('office staff cannot open estimates module', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();
    await _signIn(tester, 'marcus@hvacpro.com', 'FrontDesk!');

    expect(find.byKey(const Key('admin-nav-estimates')), findsNothing);

    GoRouter.of(tester.element(find.byKey(const Key('dashboard')))).go('/estimates');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('estimates-page')), findsNothing);
    expect(find.textContaining('Welcome back'), findsOneWidget);
  });

  testWidgets('owner can open invoices list and detail', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();
    await _signIn(tester, 'diana@hvacpro.com', 'OfficeLead!');

    GoRouter.of(tester.element(find.byKey(const Key('dashboard')))).go('/invoices');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('invoices-page')), findsOneWidget);
    expect(find.byKey(Key('invoice-row-${MockSeedIds.invoiceId}')), findsOneWidget);
    expect(find.text('INV-RLS-21'), findsOneWidget);

    await tester.tap(find.text('INV-RLS-21'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('invoice-detail')), findsOneWidget);
    expect(find.byKey(const Key('invoice-preview')), findsOneWidget);
    expect(find.textContaining('INV-RLS-21'), findsOneWidget);
  });

  testWidgets('office staff cannot open invoices module', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();
    await _signIn(tester, 'marcus@hvacpro.com', 'FrontDesk!');

    expect(find.byKey(const Key('admin-nav-invoices')), findsNothing);

    GoRouter.of(tester.element(find.byKey(const Key('dashboard')))).go('/invoices');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('invoices-page')), findsNothing);
    expect(find.textContaining('Welcome back'), findsOneWidget);
  });

  testWidgets('owner can record payment and start online checkout', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();
    await _signIn(tester, 'diana@hvacpro.com', 'OfficeLead!');

    GoRouter.of(tester.element(find.byKey(const Key('dashboard')))).go(
      '/invoices/${MockSeedIds.invoiceId}',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pay-online')), findsOneWidget);
    expect(find.byKey(const Key('record-payment')), findsOneWidget);

    await tester.tap(find.byKey(const Key('pay-online')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('checkout-url-hint')), findsOneWidget);
    expect(find.textContaining('Awaiting payment'), findsOneWidget);

    await tester.tap(find.byKey(const Key('record-payment')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Succeeded'), findsOneWidget);
  });

  testWidgets('overdue invoice shows seeded payment history', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();
    await _signIn(tester, 'diana@hvacpro.com', 'OfficeLead!');

    GoRouter.of(tester.element(find.byKey(const Key('dashboard')))).go(
      '/invoices/${MockSeedIds.overdueInvoiceId}',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(Key('payment-row-${MockSeedIds.paymentId}')), findsOneWidget);
    expect(find.textContaining('Awaiting payment'), findsOneWidget);
  });

  testWidgets('owner can open inventory list and part detail', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();
    await _signIn(tester, 'diana@hvacpro.com', 'OfficeLead!');

    GoRouter.of(tester.element(find.byKey(const Key('dashboard')))).go('/inventory');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('inventory-page')), findsOneWidget);
    expect(find.byKey(Key('inventory-row-${MockSeedIds.inventoryItemId}')), findsOneWidget);
    expect(find.text('45/5 Capacitor'), findsOneWidget);
    expect(find.textContaining('LOW'), findsOneWidget);

    await tester.tap(find.text('45/5 Capacitor'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('inventory-item')), findsOneWidget);
    expect(find.byKey(const Key('warehouse-qty')), findsOneWidget);
    expect(find.textContaining('Below minimum'), findsOneWidget);
  });

  testWidgets('receive stock requires confirmation before moving inventory', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();
    await _signIn(tester, 'diana@hvacpro.com', 'OfficeLead!');

    GoRouter.of(tester.element(find.byKey(const Key('dashboard')))).go(
      '/inventory/${MockSeedIds.inventoryItemId}',
    );
    await tester.pumpAndSettle();

    final inventory = tester
        .element(find.byKey(const Key('inventory-item')))
        .read<InventoryController>();
    int warehouseQty() => inventory.warehouseQty(MockSeedIds.inventoryItemId);

    final before = warehouseQty();
    final receiveButton = find.byKey(const Key('receive-stock'));

    await tester.ensureVisible(receiveButton);
    await tester.tap(receiveButton);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Cancel'),
    ));
    await tester.pumpAndSettle();

    expect(warehouseQty(), before, reason: 'Cancelling the dialog must not move stock');

    await tester.ensureVisible(receiveButton);
    await tester.tap(receiveButton);
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Receive'),
    ));
    await tester.pumpAndSettle();

    expect(warehouseQty(), before + 5);
  });

  testWidgets('office staff can open inventory module', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();
    await _signIn(tester, 'marcus@hvacpro.com', 'FrontDesk!');

    GoRouter.of(tester.element(find.byKey(const Key('dashboard')))).go('/inventory');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('inventory-page')), findsOneWidget);
    expect(find.text('45/5 Capacitor'), findsOneWidget);
  });

  testWidgets('owner can assign and consume inventory stock', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();
    await _signIn(tester, 'diana@hvacpro.com', 'OfficeLead!');

    GoRouter.of(tester.element(find.byKey(const Key('dashboard')))).go(
      '/inventory/${MockSeedIds.inventoryItemId}',
    );
    await tester.pumpAndSettle();

    final assignQty = find.byKey(const Key('assign-qty'));
    await tester.ensureVisible(assignQty);
    await tester.enterText(assignQty, '1');

    await tester.ensureVisible(find.byKey(const Key('assign-job')));
    await tester.tap(find.byKey(const Key('assign-job')));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('JOB-RLS-21').first);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('assign-submit')));
    await tester.tap(find.byKey(const Key('assign-submit')));
    await tester.pumpAndSettle();

    // Assigning stock must be confirmed before the move is recorded.
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Assign'),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Assign'), findsWidgets);

    await tester.ensureVisible(find.byKey(const Key('consume-submit')));
    await tester.tap(find.byKey(const Key('consume-submit')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Issue'), findsWidgets);
  });

  testWidgets('owner can send SMS from communication page', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();
    await _signIn(tester, 'diana@hvacpro.com', 'OfficeLead!');

    GoRouter.of(tester.element(find.byKey(const Key('dashboard')))).go(
      '/communication?entity=job&id=${MockSeedIds.jobId}&template=appointment_reminder',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('communication-page')), findsOneWidget);
    expect(find.byKey(const Key('compose-body')), findsOneWidget);
    expect(find.byKey(const Key('recent-message-threads')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('send-message')));
    await tester.tap(find.byKey(const Key('send-message')));
    await tester.pumpAndSettle();

    expect(find.text('Message sent.'), findsOneWidget);
    expect(find.byKey(const Key('communication-timeline')), findsOneWidget);
  });

  testWidgets('owner can open maintenance list and agreement detail', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();

    await _signIn(tester, 'diana@hvacpro.com', 'OfficeLead!');

    expect(find.byKey(const Key('dashboard-expiring-maintenance')), findsOneWidget);

    GoRouter.of(tester.element(find.byKey(const Key('dashboard')))).go('/maintenance');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('maintenance-page')), findsOneWidget);
    expect(find.byKey(Key('maintenance-row-${MockSeedIds.maintenanceAgreementId}')), findsOneWidget);

    await tester.tap(find.byKey(Key('maintenance-row-${MockSeedIds.maintenanceAgreementId}')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('maintenance-agreement-detail')), findsOneWidget);
    expect(find.text('Annual HVAC tune-up'), findsOneWidget);
  });

  testWidgets('office staff can open maintenance module without pricing', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();

    await _signIn(tester, 'marcus@hvacpro.com', 'FrontDesk!');

    GoRouter.of(tester.element(find.byKey(const Key('dashboard')))).go('/maintenance');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('maintenance-page')), findsOneWidget);
    expect(find.textContaining('\$389'), findsNothing);

    GoRouter.of(tester.element(find.byKey(const Key('maintenance-page')))).go(
      '/maintenance/${MockSeedIds.maintenanceAgreementId}',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('maintenance-agreement-detail')), findsOneWidget);
    expect(find.textContaining('Annual amount'), findsNothing);
  });

  testWidgets('property detail shows maintenance agreements', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();

    await _signIn(tester, 'diana@hvacpro.com', 'OfficeLead!');

    GoRouter.of(tester.element(find.byKey(const Key('dashboard')))).go(
      '/properties/${MockSeedIds.propertyId}',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(Key('property-maintenance-${MockSeedIds.maintenanceAgreementId}')), findsOneWidget);
  });

  testWidgets('owner can open reports with financial and job sections', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();

    await _signIn(tester, 'diana@hvacpro.com', 'OfficeLead!');

    GoRouter.of(tester.element(find.byKey(const Key('dashboard')))).go('/reports');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reports')), findsOneWidget);
    expect(find.byKey(const Key('reports-invoices')), findsOneWidget);
    expect(find.byKey(const Key('reports-volume')), findsOneWidget);
    expect(find.byKey(Key('reports-invoice-${MockSeedIds.invoiceId}')), findsOneWidget);
    expect(find.text('Carlos Rodriguez'), findsWidgets);
  });

  testWidgets('mock wiring is exposed via Provider', (WidgetTester tester) async {
    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();

    final context = tester.element(find.text('Office sign in'));
    final bundle = context.read<HvacAdminRepositoryBundle>();
    expect(bundle.managementAuth, isA<MockManagementAuthService>());
    expect(bundle.customers, isA<MockCustomerRepository>());
  });

  testWidgets('owner can open settings and save company profile', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();

    await _signIn(tester, 'diana@hvacpro.com', 'OfficeLead!');

    GoRouter.of(tester.element(find.byKey(const Key('dashboard')))).go('/settings');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings')), findsOneWidget);

    // Company profile sits at the top — edit and save before scrolling.
    await tester.enterText(find.byKey(const Key('settings-company-name')), 'Arctic HVAC Services');
    await tester.tap(find.byKey(const Key('save-company-settings')));
    await tester.pumpAndSettle();

    expect(find.text('Company settings saved'), findsOneWidget);
    expect(find.text('Arctic HVAC Services'), findsWidgets);

    // Phase 21/24 additions grew the page; scroll to the lower sections.
    final settingsScrollable = find.descendant(
      of: find.byKey(const Key('settings')),
      matching: find.byType(Scrollable),
    ).first;

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-working-hours')),
      500,
      scrollable: settingsScrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('Start 7:00 AM'), findsOneWidget);
    expect(find.text('End 6:00 PM'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-office-users')),
      500,
      scrollable: settingsScrollable,
    );
    await tester.pumpAndSettle();

    // The office-users card is a navigation tile to the personnel module.
    expect(find.byKey(const Key('settings-office-users')), findsOneWidget);
  });

  testWidgets('office staff sees settings read-only without save button', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();

    await _signIn(tester, 'marcus@hvacpro.com', 'FrontDesk!');

    GoRouter.of(tester.element(find.textContaining('Welcome back'))).go('/settings');
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings')), findsOneWidget);
    expect(find.text('Only owners and admins can edit company profile. Values are shown read-only.'), findsOneWidget);
    expect(find.byKey(const Key('save-company-settings')), findsNothing);
    expect(find.byKey(const Key('settings-audit-log')), findsNothing);
    expect(find.text('Marcus Bennett'), findsOneWidget);
  });

  testWidgets('owner can open audit log viewer', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();

    await _signIn(tester, 'diana@hvacpro.com', 'OfficeLead!');

    GoRouter.of(tester.element(find.byKey(const Key('dashboard')))).go('/settings');
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-audit-log')),
      600,
      scrollable: find.descendant(
        of: find.byKey(const Key('settings')),
        matching: find.byType(Scrollable),
      ).first,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings-audit-log')), findsOneWidget);
    await tester.tap(find.byKey(const Key('settings-audit-log')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('audit-log-page')), findsOneWidget);
  });

  testWidgets('owner E2E mock: create customer, property, job, and dispatch assign', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();
    await _signIn(tester, 'diana@hvacpro.com', 'OfficeLead!');

    final router = GoRouter.of(tester.element(find.byKey(const Key('dashboard'))));
    router.go('/customers');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add customer'));
    await tester.pumpAndSettle();

    final customerFields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(customerFields.at(0), 'Phase35');
    await tester.enterText(customerFields.at(1), 'E2E');
    await tester.enterText(customerFields.at(2), '5551234567');
    await tester.enterText(customerFields.at(3), 'phase35.e2e@hvacpro.com');
    await tester.enterText(customerFields.at(4), 'Springfield');
    await tester.enterText(customerFields.at(5), 'IL');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('customer-detail')), findsOneWidget);
    expect(find.text('Phase35 E2E'), findsWidgets);

    await tester.tap(find.text('Add property'));
    await tester.pumpAndSettle();

    final propertyFields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(propertyFields.at(0), '99 E2E Test Lane');
    await tester.enterText(propertyFields.at(2), 'Springfield');
    await tester.enterText(propertyFields.at(3), 'IL');
    await tester.enterText(propertyFields.at(4), '62704');
    // Property location is required: set the pin through the map picker's public
    // callback (map tiles are unreachable in widget tests).
    final picker = tester.widget<MapAddressPicker>(find.byType(MapAddressPicker));
    picker.onChanged?.call(point: const LatLng(39.7817, -89.6501), address: null);
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    router.go('/jobs');
    await tester.pumpAndSettle();
    // The jobs page button label is "Create job" (dialog title is "New job").
    await tester.tap(find.widgetWithText(AppPrimaryButton, 'Create job'));
    await tester.pumpAndSettle();

    final jobFields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextFormField),
    );
    await tester.enterText(jobFields.at(0), 'Phase 35 widget E2E job');
    await tester.tap(find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Create job'),
    ));
    await tester.pumpAndSettle();

    final jobController = tester.element(find.text('Create job')).read<JobController>();
    final createdJob = jobController.jobs.firstWhere(
      (job) => job.description.contains('Phase 35 widget E2E job'),
    );

    router.go('/dispatch');
    await tester.pumpAndSettle();

    final unassignedJob = find.byKey(Key('dispatch-job-${createdJob.id}'));
    final carlosColumn = find.byKey(const Key('dispatch-column-${MockSeedIds.technicianId}'));
    expect(unassignedJob, findsOneWidget);
    await tester.drag(
      unassignedJob,
      tester.getCenter(carlosColumn) - tester.getCenter(unassignedJob),
    );
    await tester.pumpAndSettle();

    expect(
      jobController.jobsForTechnician(MockSeedIds.technicianId).any((job) => job.id == createdJob.id),
      isTrue,
    );
  });

  testWidgets('office staff global search hides invoice hits', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const HvacAdminApp());
    await tester.pumpAndSettle();

    await _signIn(tester, 'marcus@hvacpro.com', 'FrontDesk!');

    GoRouter.of(tester.element(find.textContaining('Welcome back'))).go('/search');
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('global-search-field')), 'INV');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Invoices'), findsNothing);
    expect(find.text('INV-RLS-21'), findsNothing);
  });
}
