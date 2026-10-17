import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/accounting/accounting_export_service.dart';
import 'package:hvac_admin/core/auth/auth_session_bridge.dart';
import 'package:hvac_admin/core/boot/app_boot_controller.dart';
import 'package:hvac_admin/core/config/app_environment.dart';
import 'package:hvac_admin/core/config/supabase_config.dart';
import 'package:hvac_admin/core/controllers/customer_controller.dart';
import 'package:hvac_admin/core/controllers/dashboard_controller.dart';
import 'package:hvac_admin/core/controllers/job_controller.dart';
import 'package:hvac_admin/core/controllers/gps_map_controller.dart';
import 'package:hvac_admin/core/controllers/communication_controller.dart';
import 'package:hvac_admin/core/controllers/internal_messaging_controller.dart';
import 'package:hvac_admin/core/controllers/invoice_controller.dart';
import 'package:hvac_admin/core/payments/payment_provider.dart';
import 'package:hvac_admin/core/payments/payment_service.dart';
import 'package:hvac_admin/core/payments/payments_status_service.dart';
import 'package:hvac_admin/core/payments/supabase_payment_provider.dart';
import 'package:hvac_admin/core/controllers/inventory_controller.dart';
import 'package:hvac_admin/core/controllers/estimate_controller.dart';
import 'package:hvac_admin/core/controllers/maintenance_agreement_controller.dart';
import 'package:hvac_admin/core/controllers/reports_controller.dart';
import 'package:hvac_admin/core/controllers/audit_controller.dart';
import 'package:hvac_admin/core/controllers/settings_controller.dart';
import 'package:hvac_admin/core/controllers/office_personnel_controller.dart';
import 'package:hvac_admin/core/controllers/document_template_controller.dart';
import 'package:hvac_admin/core/controllers/translate_controller.dart';
import 'package:hvac_admin/core/l10n/locale_controller.dart';
import 'package:hvac_admin/core/messaging/message_dispatch_service.dart';
import 'package:hvac_admin/core/portal/portal_link_service.dart';
import 'package:hvac_admin/core/controllers/fleet_controller.dart';
import 'package:hvac_admin/core/realtime/realtime_bridge.dart';
import 'package:hvac_admin/core/controllers/technician_controller.dart';
import 'package:hvac_admin/core/controllers/management_auth_controller.dart';
import 'package:hvac_admin/core/routing/app_router.dart';
import 'package:hvac_admin/data/datasources/management_auth_service.dart';
import 'package:hvac_admin/data/wiring/repository_wiring.dart';
import 'package:hvac_admin/design_system/app_theme.dart';
import 'package:hvac_admin/design_system/tokens/tokens.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Root widget.
class HvacAdminApp extends StatefulWidget {
  const HvacAdminApp({super.key, this.supabase, this.managementAuthOverride});

  /// When null (widget tests), wiring uses mock repositories.
  final SupabaseClient? supabase;

  /// Test seam: replaces the management auth service (e.g. a fake that holds
  /// `restore()` to exercise the splash boot gate).
  final ManagementAuthService? managementAuthOverride;

  @override
  State<HvacAdminApp> createState() => _HvacAdminAppState();
}

class _HvacAdminAppState extends State<HvacAdminApp> {
  late final HvacAdminRepositoryBundle _repos;
  late final ManagementAuthController _auth;
  late final DashboardController _dashboard;
  late final CustomerController _customers;
  late final JobController _jobs;
  late final TechnicianController _technicians;
  late final FleetController _fleet;
  late final InvoiceController _invoices;
  late final EstimateController _estimates;
  late final InventoryController _inventory;
  late final MaintenanceAgreementController _maintenance;
  late final ReportsController _reports;
  late final SettingsController _settings;
  late final OfficePersonnelController _officePersonnel;
  late final AuditController _audit;
  late final DocumentTemplateController _documents;
  late final CommunicationController _communication;
  late final InternalMessagingController _internalMessaging;
  late final GpsMapController _gpsMap;
  late final TranslateController _translate;
  late final PortalLinkService _portal;
  late final PaymentsStatusService _paymentsStatus;
  late final AccountingExportService _accountingExport;
  late final LocaleController _locale;
  late final RealtimeBridge _realtime;
  late final AppBootController _boot;
  late final GoRouter _router;
  AuthSessionBridge? _sessionBridge;

  @override
  void initState() {
    super.initState();
    _repos = RepositoryWiring.create(client: widget.supabase, managementAuth: widget.managementAuthOverride);
    _locale = LocaleController();
    _auth = AppManagementAuthController(_repos.managementAuth);
    _dashboard = DashboardController(_repos.reports);
    _customers = CustomerController(_repos.customers);
    _jobs = JobController(jobs: _repos.jobs, technicians: _repos.technicians);
    _technicians = TechnicianController(_repos.technicians);
    _fleet = FleetController(_repos.fleet);
    final paymentProvider = widget.supabase != null
        ? SupabasePaymentProvider(widget.supabase!)
        : MockPaymentProvider();
    _invoices = InvoiceController(
      _repos.billing,
      payments: PaymentService(repository: _repos.billing, provider: paymentProvider),
    );
    _estimates = EstimateController(_repos.billing);
    _inventory = InventoryController(_repos.inventory);
    _maintenance = MaintenanceAgreementController(_repos.maintenanceAgreements);
    _reports = ReportsController(_repos.billing, _repos.reports);
    _settings = SettingsController(_repos.settings);
    _officePersonnel = OfficePersonnelController(_repos.officePersonnel);
    _audit = AuditController(_repos.audit);
    _documents = DocumentTemplateController(_repos.documentTemplates);
    _communication = CommunicationController(
      _repos.communication,
      dispatch: MessageDispatchService(
        repository: _repos.communication,
        sender: _repos.messageSender,
      ),
    );
    _internalMessaging = InternalMessagingController(_repos.internalMessaging);
    _gpsMap = GpsMapController(_repos.locations);
    _translate = TranslateController(_repos.translate);
    _portal = PortalLinkService(_repos.portal);
    _paymentsStatus = widget.supabase != null
        ? PaymentsStatusService(widget.supabase!)
        : PaymentsStatusService.offline();
    _accountingExport = AccountingExportService(
      billing: _repos.billing,
      audit: _repos.audit,
    );
    _realtime = RealtimeBridge(
      service: _repos.realtime,
      management: _auth,
      jobs: _jobs,
      technicians: _technicians,
      customers: _customers,
      gps: _gpsMap,
      messaging: _internalMessaging,
    );
    _jobs.bindRealtime(_realtime);
    _technicians.bindRealtime(_realtime);
    _realtime.attach();
    _boot = AppBootController();
    _router = createAppRouter(_auth, _boot);

    if (widget.supabase != null) {
      _sessionBridge = AuthSessionBridge(client: widget.supabase!, management: _auth);
      _sessionBridge!.attach();
    }

    // Boot inside the splash: restore the office session and pre-load the
    // company profile, then release the router so it auto-continues to the
    // dashboard or login.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _boot.run(() async {
        // Locale only affects UI language — must not block the boot gate
        // (SharedPreferences can hang under widget tests).
        unawaited(_locale.load());
        await _auth.restore();
        // Load company profile early so the shell header shows the configured
        // company name/identity (falls back to defaults before this resolves).
        if (_auth.isAuthenticated && widget.supabase != null) {
          await _settings.load(force: true);
        }
      });
    });
  }

  @override
  void dispose() {
    _boot.dispose();
    _sessionBridge?.dispose();
    _realtime.dispose();
    _dashboard.dispose();
    _customers.dispose();
    _jobs.dispose();
    _technicians.dispose();
    _fleet.dispose();
    _invoices.dispose();
    _estimates.dispose();
    _inventory.dispose();
    _maintenance.dispose();
    _reports.dispose();
    _settings.dispose();
    _officePersonnel.dispose();
    _audit.dispose();
    _documents.dispose();
    _communication.dispose();
    _internalMessaging.dispose();
    _gpsMap.dispose();
    _translate.dispose();
    _locale.dispose();
    _auth.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final host = SupabaseConfig.host;
    return MultiProvider(
      providers: [
        Provider<HvacAdminRepositoryBundle>.value(value: _repos),
        ChangeNotifierProvider<LocaleController>.value(value: _locale),
        ChangeNotifierProvider<ManagementAuthController>.value(value: _auth),
        ChangeNotifierProvider<AppBootController>.value(value: _boot),
        ChangeNotifierProvider<DashboardController>.value(value: _dashboard),
        ChangeNotifierProvider<CustomerController>.value(value: _customers),
        ChangeNotifierProvider<JobController>.value(value: _jobs),
        ChangeNotifierProvider<TechnicianController>.value(value: _technicians),
        ChangeNotifierProvider<FleetController>.value(value: _fleet),
        ChangeNotifierProvider<InvoiceController>.value(value: _invoices),
        ChangeNotifierProvider<EstimateController>.value(value: _estimates),
        ChangeNotifierProvider<InventoryController>.value(value: _inventory),
        ChangeNotifierProvider<MaintenanceAgreementController>.value(value: _maintenance),
        ChangeNotifierProvider<ReportsController>.value(value: _reports),
        ChangeNotifierProvider<SettingsController>.value(value: _settings),
        ChangeNotifierProvider<OfficePersonnelController>.value(value: _officePersonnel),
        ChangeNotifierProvider<AuditController>.value(value: _audit),
        ChangeNotifierProvider<DocumentTemplateController>.value(value: _documents),
        ChangeNotifierProvider<CommunicationController>.value(value: _communication),
        ChangeNotifierProvider<InternalMessagingController>.value(value: _internalMessaging),
        ChangeNotifierProvider<GpsMapController>.value(value: _gpsMap),
        ChangeNotifierProvider<TranslateController>.value(value: _translate),
        Provider<PortalLinkService>.value(value: _portal),
        Provider<PaymentsStatusService>.value(value: _paymentsStatus),
        Provider<AccountingExportService>.value(value: _accountingExport),
        if (widget.supabase != null) Provider<SupabaseClient>.value(value: widget.supabase!),
      ],
      child: Consumer<LocaleController>(
        builder: (context, locale, _) {
          return MaterialApp.router(
            title: locale.strings.appTitle,
            theme: AppTheme.dark,
            debugShowCheckedModeBanner: false,
            locale: locale.flutterLocale,
            supportedLocales: const [Locale('en'), Locale('es')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            routerConfig: _router,
            builder: (context, child) {
              return Banner(
                message: AppEnvironment.name,
                location: BannerLocation.topEnd,
                color: AppEnvironment.isProduction
                    ? Colors.red.shade700
                    : AppEnvironment.isStaging
                        ? Colors.orange.shade800
                        : Colors.blueGrey,
                child: Column(
                  children: [
                    if (host != null && widget.supabase != null)
                      Material(
                        color: AppColors.surface,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.cloud_done_outlined, size: 16, color: AppColors.textSecondary),
                              const SizedBox(width: 8),
                              Text('Connected · $host', style: AppTypography.bodySmall),
                            ],
                          ),
                        ),
                      ),
                    Expanded(child: child ?? const SizedBox.shrink()),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
