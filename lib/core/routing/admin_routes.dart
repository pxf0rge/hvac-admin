import 'package:go_router/go_router.dart';

import 'package:hvac_admin/core/enums/admin_module.dart';

import 'package:hvac_admin/features/customers/customer_detail_page.dart';

import 'package:hvac_admin/features/customers/customers_page.dart';

import 'package:hvac_admin/features/dashboard/dashboard_page.dart';

import 'package:hvac_admin/features/properties/properties_page.dart';

import 'package:hvac_admin/features/properties/property_detail_page.dart';

import 'package:hvac_admin/features/equipment/equipment_page.dart';

import 'package:hvac_admin/features/equipment/equipment_detail_page.dart';

import 'package:hvac_admin/features/equipment/warranty_search_page.dart';

import 'package:hvac_admin/features/jobs/jobs_page.dart';

import 'package:hvac_admin/features/jobs/job_detail_page.dart';

import 'package:hvac_admin/features/dispatch/dispatch_page.dart';

import 'package:hvac_admin/features/calendar/calendar_page.dart';

import 'package:hvac_admin/features/technicians/technicians_page.dart';

import 'package:hvac_admin/features/technicians/technician_detail_page.dart';

import 'package:hvac_admin/features/office_personnel/office_personnel_page.dart';

import 'package:hvac_admin/features/office_personnel/office_personnel_detail_page.dart';

import 'package:hvac_admin/features/gps/gps_map_page.dart';

import 'package:hvac_admin/features/fleet/fleet_page.dart';

import 'package:hvac_admin/features/communication/communication_page.dart';

import 'package:hvac_admin/features/internal_messaging/internal_messaging_page.dart';

import 'package:hvac_admin/features/invoices/invoice_detail_page.dart';
import 'package:hvac_admin/features/invoices/invoice_editor_page.dart';
import 'package:hvac_admin/features/invoices/invoices_page.dart';

import 'package:hvac_admin/features/estimates/estimate_detail_page.dart';
import 'package:hvac_admin/features/estimates/estimate_editor_page.dart';
import 'package:hvac_admin/features/estimates/estimates_page.dart';

import 'package:hvac_admin/features/inventory/inventory_item_editor_page.dart';
import 'package:hvac_admin/features/inventory/inventory_item_page.dart';
import 'package:hvac_admin/features/inventory/inventory_page.dart';

import 'package:hvac_admin/features/maintenance/maintenance_agreement_detail_page.dart';
import 'package:hvac_admin/features/maintenance/maintenance_agreements_page.dart';

import 'package:hvac_admin/features/reports/reports_page.dart';

import 'package:hvac_admin/features/settings/audit_log_page.dart';
import 'package:hvac_admin/features/settings/settings_page.dart';

import 'package:hvac_admin/features/documents/documents_page.dart';

import 'package:hvac_admin/features/documents/template_editor_page.dart';

import 'package:hvac_admin/features/search/global_search_page.dart';

import 'package:hvac_admin/features/shared/access_denied_page.dart';

import 'package:hvac_admin/features/shared/entity_detail_placeholder_page.dart';

import 'package:hvac_admin/features/shared/module_placeholder_page.dart';



const _detailModules = <AdminModule>{

  AdminModule.inventory,

  AdminModule.estimates,

  AdminModule.invoices,

  AdminModule.documents,

};



String _detailTitle(AdminModule module) => switch (module) {

      AdminModule.jobs => 'Job',

      AdminModule.technicians => 'Technician',

      AdminModule.officePersonnel => 'Office user',

      AdminModule.equipment => 'Equipment',

      AdminModule.inventory => 'Part',

      AdminModule.estimates => 'Estimate',

      AdminModule.invoices => 'Invoice',

      AdminModule.maintenanceAgreements => 'Maintenance',

      AdminModule.documents => 'Template',

      _ => module.label,

    };



List<RouteBase> buildAdminShellRoutes() {

  return [

    GoRoute(path: AdminModule.dashboard.path, builder: (_, _) => const DashboardPage()),

    GoRoute(path: AdminModule.dispatch.path, builder: (_, _) => const DispatchPage()),

    GoRoute(path: AdminModule.calendar.path, builder: (_, _) => const CalendarPage()),

    GoRoute(path: '/search', builder: (_, _) => const GlobalSearchPage()),

    GoRoute(

      path: AdminModule.customers.path,

      builder: (_, _) => const CustomersPage(),

      routes: [

        GoRoute(

          path: ':id',

          builder: (_, state) => CustomerDetailPage(customerId: state.pathParameters['id']!),

        ),

      ],

    ),

    GoRoute(

      path: AdminModule.properties.path,

      builder: (_, _) => const PropertiesPage(),

      routes: [

        GoRoute(

          path: ':id',

          builder: (_, state) => PropertyDetailPage(propertyId: state.pathParameters['id']!),

        ),

      ],

    ),

    GoRoute(
      path: AdminModule.equipment.path,
      builder: (_, _) => const EquipmentPage(),
      routes: [
        GoRoute(path: 'warranty-search', builder: (_, _) => const WarrantySearchPage()),
        GoRoute(
          path: ':id',
          builder: (_, state) => EquipmentDetailPage(equipmentId: state.pathParameters['id']!),
        ),
      ],
    ),

    GoRoute(
      path: AdminModule.jobs.path,
      builder: (_, _) => const JobsPage(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (_, state) => JobDetailPage(jobId: state.pathParameters['id']!),
        ),
      ],
    ),

    GoRoute(
      path: AdminModule.technicians.path,
      builder: (_, _) => const TechniciansPage(),
      routes: [
        GoRoute(path: 'map', builder: (_, _) => const GpsMapPage()),
        GoRoute(
          path: ':id',
          builder: (_, state) => TechnicianDetailPage(technicianId: state.pathParameters['id']!),
        ),
      ],
    ),

    GoRoute(
      path: AdminModule.officePersonnel.path,
      builder: (_, _) => const OfficePersonnelPage(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (_, state) => OfficePersonnelDetailPage(userId: state.pathParameters['id']!),
        ),
      ],
    ),

    GoRoute(path: AdminModule.fleet.path, builder: (_, _) => const FleetPage()),

    GoRoute(
      path: AdminModule.documents.path,
      builder: (_, _) => const DocumentsPage(),
      routes: [
        GoRoute(path: 'new', builder: (_, _) => const TemplateEditorPage()),
        GoRoute(
          path: ':id',
          builder: (_, state) => TemplateEditorPage(templateId: state.pathParameters['id']!),
        ),
      ],
    ),

    GoRoute(
      path: AdminModule.communication.path,
      builder: (_, state) => CommunicationPage(
        entityType: state.uri.queryParameters['entity'],
        entityId: state.uri.queryParameters['id'],
        template: state.uri.queryParameters['template'],
        variableOverrides: {
          for (final key in const [
            'estimate_url',
            'estimate_number',
            'invoice_url',
            'invoice_number',
            'amount_due',
            'due_date',
            'document_url',
            'document_title',
          ])
            if ((state.uri.queryParameters[key] ?? '').isNotEmpty) key: state.uri.queryParameters[key]!,
        },
      ),
    ),

    GoRoute(
      path: AdminModule.teamMessages.path,
      builder: (_, _) => const InternalMessagingPage(),
    ),

    GoRoute(
      path: AdminModule.estimates.path,
      builder: (_, _) => const EstimatesPage(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (_, state) => EstimateEditorPage(
            jobId: state.uri.queryParameters['jobId'],
            propertyId: state.uri.queryParameters['propertyId'],
          ),
        ),
        GoRoute(
          path: ':id',
          builder: (_, state) => EstimateDetailPage(estimateId: state.pathParameters['id']!),
        ),
      ],
    ),

    GoRoute(
      path: AdminModule.invoices.path,
      builder: (_, _) => const InvoicesPage(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (_, state) => InvoiceEditorPage(
            jobId: state.uri.queryParameters['jobId'],
            propertyId: state.uri.queryParameters['propertyId'],
            estimateId: state.uri.queryParameters['estimateId'],
          ),
        ),
        GoRoute(
          path: ':id',
          builder: (_, state) => InvoiceDetailPage(invoiceId: state.pathParameters['id']!),
        ),
      ],
    ),

    GoRoute(
      path: AdminModule.inventory.path,
      builder: (_, _) => const InventoryPage(),
      routes: [
        GoRoute(
          path: 'new',
          builder: (_, _) => const InventoryItemEditorPage(),
        ),
        GoRoute(
          path: ':id',
          builder: (_, state) => InventoryItemPage(itemId: state.pathParameters['id']!),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (_, state) => InventoryItemEditorPage(itemId: state.pathParameters['id']!),
            ),
          ],
        ),
      ],
    ),

    GoRoute(
      path: AdminModule.maintenanceAgreements.path,
      builder: (_, _) => const MaintenanceAgreementsPage(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (_, state) => MaintenanceAgreementDetailPage(agreementId: state.pathParameters['id']!),
        ),
      ],
    ),

    GoRoute(path: AdminModule.reports.path, builder: (_, _) => const ReportsPage()),

    GoRoute(
      path: AdminModule.settings.path,
      builder: (_, _) => const SettingsPage(),
      routes: [
        GoRoute(path: 'audit', builder: (_, _) => const AuditLogPage()),
      ],
    ),

    for (final module in AdminModule.values)

      if (module != AdminModule.dashboard &&

          module != AdminModule.dispatch &&

          module != AdminModule.calendar &&

          module != AdminModule.customers &&

          module != AdminModule.properties &&

          module != AdminModule.equipment &&

          module != AdminModule.jobs &&

          module != AdminModule.technicians &&

          module != AdminModule.officePersonnel &&

          module != AdminModule.fleet &&

          module != AdminModule.documents &&

          module != AdminModule.communication &&

          module != AdminModule.teamMessages &&

          module != AdminModule.estimates &&

          module != AdminModule.invoices &&

          module != AdminModule.inventory &&

          module != AdminModule.maintenanceAgreements &&

          module != AdminModule.reports &&

          module != AdminModule.settings)

        if (_detailModules.contains(module))

          GoRoute(

            path: module.path,

            builder: (_, _) => ModulePlaceholderPage(module: module),

            routes: [

              GoRoute(

                path: ':id',

                builder: (_, state) => EntityDetailPlaceholderPage(

                  title: _detailTitle(module),

                  entityId: state.pathParameters['id']!,

                  module: module,

                ),

              ),

            ],

          )

        else

          GoRoute(

            path: module.path,

            builder: (_, _) => ModulePlaceholderPage(module: module),

          ),

    GoRoute(path: '/access-denied', builder: (_, _) => const AccessDeniedPage()),

  ];

}


