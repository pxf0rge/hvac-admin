import 'package:flutter/material.dart';

/// Navigation modules for the admin app. Routes are root-relative (no `/management` prefix).
enum AdminModule {
  dashboard,
  dispatch,
  calendar,
  customers,
  properties,
  jobs,
  technicians,
  officePersonnel,
  fleet,
  equipment,
  maintenanceAgreements,
  documents,
  communication,
  teamMessages,
  inventory,
  estimates,
  invoices,
  reports,
  settings,
}

extension AdminModuleX on AdminModule {
  String get path => switch (this) {
        AdminModule.dashboard => '/dashboard',
        AdminModule.dispatch => '/dispatch',
        AdminModule.calendar => '/calendar',
        AdminModule.customers => '/customers',
        AdminModule.properties => '/properties',
        AdminModule.jobs => '/jobs',
        AdminModule.technicians => '/technicians',
        AdminModule.officePersonnel => '/office-personnel',
        AdminModule.fleet => '/fleet',
        AdminModule.equipment => '/equipment',
        AdminModule.maintenanceAgreements => '/maintenance',
        AdminModule.documents => '/documents',
        AdminModule.communication => '/communication',
        AdminModule.teamMessages => '/team-messages',
        AdminModule.inventory => '/inventory',
        AdminModule.estimates => '/estimates',
        AdminModule.invoices => '/invoices',
        AdminModule.reports => '/reports',
        AdminModule.settings => '/settings',
      };

  String get label => switch (this) {
        AdminModule.dashboard => 'Dashboard',
        AdminModule.dispatch => 'Dispatch',
        AdminModule.calendar => 'Calendar',
        AdminModule.customers => 'Customers',
        AdminModule.properties => 'Properties',
        AdminModule.jobs => 'Jobs',
        AdminModule.technicians => 'Technicians',
        AdminModule.officePersonnel => 'Office Personnel',
        AdminModule.fleet => 'Fleet',
        AdminModule.equipment => 'Equipment',
        AdminModule.maintenanceAgreements => 'Maintenance',
        AdminModule.documents => 'Documents',
        AdminModule.communication => 'Communication',
        AdminModule.teamMessages => 'Team messages',
        AdminModule.inventory => 'Inventory',
        AdminModule.estimates => 'Estimates',
        AdminModule.invoices => 'Invoices',
        AdminModule.reports => 'Reports',
        AdminModule.settings => 'Settings',
      };

  IconData get icon => switch (this) {
        AdminModule.dashboard => Icons.dashboard_outlined,
        AdminModule.dispatch => Icons.map_outlined,
        AdminModule.calendar => Icons.calendar_month_outlined,
        AdminModule.customers => Icons.people_outline,
        AdminModule.properties => Icons.home_work_outlined,
        AdminModule.jobs => Icons.work_outline,
        AdminModule.technicians => Icons.engineering_outlined,
        AdminModule.officePersonnel => Icons.badge_outlined,
        AdminModule.fleet => Icons.local_shipping_outlined,
        AdminModule.equipment => Icons.thermostat_outlined,
        AdminModule.maintenanceAgreements => Icons.assignment_outlined,
        AdminModule.documents => Icons.description_outlined,
        AdminModule.communication => Icons.chat_outlined,
        AdminModule.teamMessages => Icons.forum_outlined,
        AdminModule.inventory => Icons.inventory_2_outlined,
        AdminModule.estimates => Icons.request_quote_outlined,
        AdminModule.invoices => Icons.receipt_long_outlined,
        AdminModule.reports => Icons.bar_chart_outlined,
        AdminModule.settings => Icons.settings_outlined,
      };

  bool get isFinancial =>
      this == AdminModule.invoices || this == AdminModule.reports || this == AdminModule.estimates;

  bool get supportsDetailRoute => switch (this) {
        AdminModule.customers => true,
        AdminModule.properties => true,
        AdminModule.jobs => true,
        AdminModule.technicians => true,
        AdminModule.officePersonnel => true,
        AdminModule.equipment => true,
        AdminModule.inventory => true,
        AdminModule.maintenanceAgreements => true,
        AdminModule.documents => true,
        AdminModule.estimates => true,
        AdminModule.invoices => true,
        _ => false,
      };

  String detailTitle(String entityId) => switch (this) {
        AdminModule.customers => 'Customer',
        AdminModule.properties => 'Property',
        AdminModule.jobs => 'Job',
        AdminModule.technicians => 'Technician',
        AdminModule.officePersonnel => 'Office user',
        AdminModule.equipment => 'Equipment',
        AdminModule.inventory => 'Part',
        AdminModule.maintenanceAgreements => 'Maintenance',
        AdminModule.documents => 'Template',
        AdminModule.estimates => 'Estimate',
        AdminModule.invoices => 'Invoice',
        _ => label,
      };
}
