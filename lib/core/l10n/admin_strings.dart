import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/enums/user_role.dart';
import 'package:hvac_admin/core/l10n/app_locale.dart';

/// Central EN/ES catalog for admin chrome and high-traffic screens.
class AdminStrings {
  const AdminStrings(this.locale);

  final AppLocale locale;

  bool get _es => locale == AppLocale.spanish;

  // —— Common ——
  String get admin => _es ? 'Admin' : 'Admin';
  String get search => _es ? 'Buscar' : 'Search';
  String get signOut => _es ? 'Cerrar sesión' : 'Sign out';
  String get signIn => _es ? 'Iniciar sesión' : 'Sign in';
  String get save => _es ? 'Guardar' : 'Save';
  String get cancel => _es ? 'Cancelar' : 'Cancel';
  String get tryAgain => _es ? 'Reintentar' : 'Try again';
  String get loading => _es ? 'Cargando…' : 'Loading…';
  String get accessDenied => _es ? 'Acceso denegado' : 'Access denied';
  String get language => _es ? 'Idioma' : 'Language';
  String get languageSection => _es ? 'Idioma de la interfaz' : 'Interface language';
  String get languageHint => _es
      ? 'Cambia el idioma de la app de oficina. Los documentos del cliente siguen en inglés.'
      : 'Switch the office app language. Customer documents stay in English by default.';
  String get documentsStayEnglish => _es
      ? 'Las plantillas y PDF firmados del cliente permanecen en inglés profesional.'
      : 'Customer document templates and signed PDFs stay in professional English.';
  String get today => _es ? 'Hoy' : 'Today';
  String get tomorrow => _es ? 'Mañana' : 'Tomorrow';
  String get yesterday => _es ? 'Ayer' : 'Yesterday';
  String get open => _es ? 'Abrir' : 'Open';
  String get create => _es ? 'Crear' : 'Create';
  String get edit => _es ? 'Editar' : 'Edit';
  String get delete => _es ? 'Eliminar' : 'Delete';
  String get refresh => _es ? 'Actualizar' : 'Refresh';
  String get directory => _es ? 'Directorio' : 'Directory';
  String get all => _es ? 'Todos' : 'All';
  String get none => _es ? 'Ninguno' : 'None';
  String get unassigned => _es ? 'Sin asignar' : 'Unassigned';

  // —— Roles ——
  String role(UserRole? role) => switch (role) {
        UserRole.owner => _es ? 'Propietario' : 'Owner',
        UserRole.admin => _es ? 'Administrador' : 'Admin',
        UserRole.officeStaff => _es ? 'Personal de oficina' : 'Office Staff',
        UserRole.technician => _es ? 'Técnico' : 'Technician',
        null => '',
      };

  // —— Modules ——
  String module(AdminModule m) => switch (m) {
        AdminModule.dashboard => _es ? 'Panel' : 'Dashboard',
        AdminModule.dispatch => _es ? 'Despacho' : 'Dispatch',
        AdminModule.calendar => _es ? 'Calendario' : 'Calendar',
        AdminModule.customers => _es ? 'Clientes' : 'Customers',
        AdminModule.properties => _es ? 'Propiedades' : 'Properties',
        AdminModule.jobs => _es ? 'Trabajos' : 'Jobs',
        AdminModule.technicians => _es ? 'Técnicos' : 'Technicians',
        AdminModule.officePersonnel => _es ? 'Personal de oficina' : 'Office Personnel',
        AdminModule.fleet => _es ? 'Flota' : 'Fleet',
        AdminModule.equipment => _es ? 'Equipo' : 'Equipment',
        AdminModule.maintenanceAgreements => _es ? 'Mantenimiento' : 'Maintenance',
        AdminModule.documents => _es ? 'Documentos' : 'Documents',
        AdminModule.communication => _es ? 'Comunicación' : 'Communication',
        AdminModule.teamMessages => _es ? 'Equipo' : 'Team messages',
        AdminModule.inventory => _es ? 'Inventario' : 'Inventory',
        AdminModule.estimates => _es ? 'Presupuestos' : 'Estimates',
        AdminModule.invoices => _es ? 'Facturas' : 'Invoices',
        AdminModule.reports => _es ? 'Informes' : 'Reports',
        AdminModule.settings => _es ? 'Ajustes' : 'Settings',
      };

  String detailTitle(AdminModule m) => switch (m) {
        AdminModule.customers => _es ? 'Cliente' : 'Customer',
        AdminModule.properties => _es ? 'Propiedad' : 'Property',
        AdminModule.jobs => _es ? 'Trabajo' : 'Job',
        AdminModule.technicians => _es ? 'Técnico' : 'Technician',
        AdminModule.officePersonnel => _es ? 'Usuario de oficina' : 'Office user',
        AdminModule.equipment => _es ? 'Equipo' : 'Equipment',
        AdminModule.inventory => _es ? 'Pieza' : 'Part',
        AdminModule.maintenanceAgreements => _es ? 'Mantenimiento' : 'Maintenance',
        AdminModule.documents => _es ? 'Plantilla' : 'Template',
        AdminModule.estimates => _es ? 'Presupuesto' : 'Estimate',
        AdminModule.invoices => _es ? 'Factura' : 'Invoice',
        _ => module(m),
      };

  String get appTitle => 'Arctic HVAC Solutions';

  // —— Login ——
  String get officeSignIn => _es ? 'Inicio de sesión oficina' : 'Office sign in';
  String get officeSignInSubtitle => _es
      ? 'Propietario, admin y personal de oficina usan esta app. Los técnicos usan la app de campo.'
      : 'Owner, admin, and office staff use this app. Technicians use the field app.';
  String get email => _es ? 'Correo' : 'Email';
  String get password => _es ? 'Contraseña' : 'Password';
  String get emailRequired => _es ? 'El correo es obligatorio' : 'Email is required';
  String get passwordRequired => _es ? 'La contraseña es obligatoria' : 'Password is required';
  String get invalidCredentials =>
      _es ? 'Correo o contraseña incorrectos.' : 'Email or password is incorrect.';
  String get technicianNotAllowed => _es
      ? 'Las cuentas de técnico deben usar la app de campo. Este acceso es solo para propietario, admin y personal de oficina.'
      : 'Technician accounts must use the field app. This login is for owner, admin, and office staff only.';
  String get profileNotFound => _es
      ? 'Falta el perfil de su cuenta. Contacte a su administrador.'
      : 'Your account profile is missing. Contact your administrator.';
  String get accountDisabled => _es
      ? 'Esta cuenta fue desactivada. Contacte a su administrador.'
      : 'This account has been deactivated. Contact your administrator.';

  // —— Dashboard ——
  String get loadingDashboard => _es ? 'Cargando panel…' : 'Loading dashboard…';
  String welcome(String name) =>
      _es ? 'Bienvenido, $name' : 'Welcome, $name';
  String get overview => _es ? 'Resumen de hoy' : "Today's overview";
  String get openJobs => _es ? 'Trabajos abiertos' : 'Open jobs';
  String get unassignedJobs => _es ? 'Sin asignar' : 'Unassigned';
  String get techniciansOnDuty => _es ? 'Técnicos en turno' : 'Technicians on duty';
  String get revenue => _es ? 'Ingresos' : 'Revenue';
  String get overdueInvoices => _es ? 'Facturas vencidas' : 'Overdue invoices';
  String get expiringAgreements => _es ? 'Acuerdos por vencer' : 'Expiring agreements';
  String get quickActions => _es ? 'Acciones rápidas' : 'Quick actions';
  String get goToDispatch => _es ? 'Ir a despacho' : 'Go to dispatch';
  String get goToCustomers => _es ? 'Ir a clientes' : 'Go to customers';
  String get goToJobs => _es ? 'Ir a trabajos' : 'Go to jobs';

  // —— Dispatch ——
  String get dispatchBoard => _es ? 'Tablero de despacho' : 'Dispatch board';
  String get assign => _es ? 'Asignar' : 'Assign';
  String get schedule => _es ? 'Horario' : 'Schedule';
  String get noJobsToday => _es ? 'No hay trabajos abiertos para hoy.' : 'No open jobs for today.';
  String get loadingDispatch => _es ? 'Cargando despacho…' : 'Loading dispatch…';

  // —— Customers / CRM ——
  String get customersTitle => _es ? 'Clientes' : 'Customers';
  String get loadingCustomers => _es ? 'Cargando clientes…' : 'Loading customers…';
  String get addCustomer => _es ? 'Agregar cliente' : 'Add customer';
  String get noCustomers => _es ? 'No hay clientes aún.' : 'No customers yet.';
  String get properties => _es ? 'Propiedades' : 'Properties';
  String get phone => _es ? 'Teléfono' : 'Phone';
  String get address => _es ? 'Dirección' : 'Address';
  String get serviceHistory => _es ? 'Historial de servicio' : 'Service history';

  // —— Jobs ——
  String get jobsTitle => _es ? 'Trabajos' : 'Jobs';
  String get loadingJobs => _es ? 'Cargando trabajos…' : 'Loading jobs…';
  String get createJob => _es ? 'Crear trabajo' : 'Create job';
  String get noJobs => _es ? 'No hay trabajos.' : 'No jobs found.';
  String get technicianNotes => _es ? 'Notas del técnico' : 'Technician notes';
  String get noNotesYet => _es ? 'Aún no hay notas.' : 'No notes saved yet.';
  String get partsUsed => _es ? 'Piezas usadas' : 'Parts used';
  String get statusHistory => _es ? 'Historial de estado' : 'Status history';
  String get jobPhotos => _es ? 'Fotos del trabajo' : 'Job photos';
  String get documents => _es ? 'Documentos' : 'Documents';
  String get messages => _es ? 'Mensajes' : 'Messages';
  String get newMessageToTechnician =>
      _es ? 'Nuevo mensaje al técnico' : 'New message to technician';
  String get selectTechnician => _es ? 'Seleccionar técnico' : 'Select technician';
  String get startConversation => _es ? 'Iniciar conversación' : 'Start conversation';
  String get noTeamThreads =>
      _es ? 'Aún no hay hilos con técnicos.' : 'No technician threads yet.';
  String get selectThreadHint =>
      _es ? 'Seleccione un hilo o inicie uno nuevo.' : 'Select a thread or start a new one.';
  String get message => _es ? 'Mensaje' : 'Message';
  String get typeMessage => _es ? 'Escriba un mensaje…' : 'Type a message…';
  String get send => _es ? 'Enviar' : 'Send';
  String get moduleLabelTeamMessages =>
      _es ? 'Mensajes del equipo' : 'Team messages';

  // —— Settings ——
  String get companyProfile => _es ? 'Perfil de la empresa' : 'Company profile';
  String get companyName => _es ? 'Nombre de la empresa' : 'Company name';
  String get companyNameRequired =>
      _es ? 'El nombre de la empresa es obligatorio' : 'Company name is required';
  String get saveCompany => _es ? 'Guardar empresa' : 'Save company';
  String get companySaved => _es ? 'Ajustes de empresa guardados' : 'Company settings saved';
  String get companySaveFailed =>
      _es ? 'No se pudieron guardar los ajustes de empresa' : 'Could not save company settings';
  String get workingHours => _es ? 'Horario laboral' : 'Working hours';
  String get gpsTrackingWindow => _es ? 'Ventana de rastreo GPS' : 'GPS tracking window';
  String get saveWorkingHours => _es ? 'Guardar horario' : 'Save working hours';
  String get automatedReminders => _es ? 'Recordatorios automáticos' : 'Automated reminders';
  String get appointmentReminders =>
      _es ? 'Recordatorios de cita' : 'Appointment reminders';
  String get maintenanceReminders =>
      _es ? 'Recordatorios de mantenimiento' : 'Maintenance renewal reminders';
  String get reminderLeadHours =>
      _es ? 'Horas de anticipación' : 'Lead time (hours)';
  String get saveReminders => _es ? 'Guardar recordatorios' : 'Save reminders';
  String get messagingIntegrations =>
      _es ? 'Integraciones de mensajería' : 'Messaging integrations';
  String get usersAndRoles => _es ? 'Usuarios y roles' : 'Users & roles';
  String get auditLog => _es ? 'Registro de auditoría' : 'Audit log';

  // —— GPS / map ——
  String get dispatchMap => _es ? 'Mapa de despacho' : 'Dispatch map';
  String get mapBoth => _es ? 'Ambos' : 'Both';
  String get mapTechs => _es ? 'Técnicos' : 'Techs';
  String get mapJobs => _es ? 'Trabajos' : 'Jobs';
  String get showOffDuty => _es ? 'Mostrar fuera de turno' : 'Show off duty';
  String get allTechnicians => _es ? 'Todos los técnicos' : 'All technicians';
  String get translate => _es ? 'Traducir' : 'Translate';
  String get showOriginal => _es ? 'Ver original' : 'Show original';
  String get translating => _es ? 'Traduciendo…' : 'Translating…';
  String get translationUnavailable => _es
      ? 'La traducción no está configurada todavía.'
      : 'Translation is not configured yet.';

  // —— Reports (Phase 18) ——
  String get reportsTitle => _es ? 'Informes' : 'Reports';
  String get reportsSubtitle => _es
      ? 'Ingresos, volumen de trabajos y desempeño de técnicos para la gerencia.'
      : 'Revenue, job volume, and technician performance for management.';
  String get loadingReports => _es ? 'Cargando informes…' : 'Loading reports…';
  String get financialReportsRestricted => _es
      ? 'Los informes financieros están restringidos a propietario y administrador.'
      : 'Financial reports are restricted to owners and admins.';
  String get kpisNote => _es
      ? 'Los KPI operativos usan trabajos e historial de flujo. Las cifras financieras usan facturas y pagos exitosos.'
      : 'Operational KPIs use jobs and workflow history. Financial figures use invoices and succeeded payments from billing.';
  String get sectionAll => _es ? 'Todos' : 'All';
  String get sectionFinancial => _es ? 'Financiero' : 'Financial';
  String get sectionJobs => _es ? 'Trabajos' : 'Jobs';
  String get exportForAccounting => _es ? 'Exportar para contabilidad' : 'Export for accounting';
  String get exportAccountingNote => _es
      ? 'CSV de facturas por rango de emisión para importar en QuickBooks/Xero. Solo propietario/admin.'
      : 'CSV of invoices in the issued date range for QuickBooks/Xero import. Owner/admin only.';
  String get exportButton => _es ? 'Exportar' : 'Export';
  String get exporting => _es ? 'Exportando…' : 'Exporting…';
  String get exportOnlyOffice => _es
      ? 'Solo propietario y administrador pueden exportar datos contables.'
      : 'Only owners and admins can export accounting data.';
  String downloadedFile(String filename, int count) => _es
      ? 'Descargado $filename ($count facturas).'
      : 'Downloaded $filename ($count invoices).';
  String csvCopied(String filename, int count) => _es
      ? 'CSV copiado al portapapeles ($count facturas): $filename'
      : 'CSV copied to clipboard ($count invoices): $filename';
  String get exportFrom => _es ? 'Desde' : 'From';
  String get exportTo => _es ? 'Hasta' : 'To';
  String get noInvoiceDataYet => _es
      ? 'Aún no hay facturas. Los KPI financieros aparecen cuando haya datos de facturación.'
      : 'No invoice data yet. Financial KPIs appear after billing is populated.';
  String get invoiceTracking => _es ? 'Seguimiento de facturas' : 'Invoice tracking';
  String get noInvoicesOnFile => _es ? 'No hay facturas registradas.' : 'No invoices on file.';
  String get jobStatistics => _es ? 'Estadísticas de trabajos' : 'Job statistics';
  String get noJobsYetCharts => _es
      ? 'Aún no hay trabajos. Los gráficos de volumen aparecen cuando se creen trabajos.'
      : 'No jobs yet. Volume charts appear after jobs are created.';
  String get completed => _es ? 'Completados' : 'Completed';
  String get openKpi => _es ? 'Abiertos' : 'Open';
  String get totalKpi => _es ? 'Total' : 'Total';
  String get jobVolumeByType => _es ? 'Volumen de trabajos por tipo' : 'Job volume by type';
  String get technicianPerformance => _es ? 'Desempeño de técnicos' : 'Technician performance';
  String get noJobsYetPerformance => _es
      ? 'Aún no hay trabajos. El desempeño aparece cuando haya asignaciones.'
      : 'No jobs yet. Performance appears after assignments.';
  String get countsUseCurrentState => _es
      ? 'Los conteos usan el estado actual del trabajo. Las métricas de duración y puntualidad requieren historial de estados.'
      : 'Counts use current job state. Duration and on-time metrics need status history.';
  String get noJobsToChart => _es ? 'No hay trabajos para graficar.' : 'No jobs to chart.';
  String get noAssignmentsYet =>
      _es ? 'Aún no hay asignaciones de técnicos.' : 'No technician assignments yet.';
  String get paidKpi => _es ? 'Pagado' : 'Paid';
  String get outstandingKpi => _es ? 'Pendiente' : 'Outstanding';
  String get overdueKpi => _es ? 'Vencido' : 'Overdue';
  String technicianSummaryMeta(String minutes, String percent) => _es
      ? '$minutes min promedio en sitio  ·  $percent% llegadas a tiempo'
      : '$minutes avg on-site  ·  $percent% on-time arrivals';
  String technicianSummaryTotals(int completed, int total) => _es
      ? '$completed completados  ·  $total trabajos'
      : '$completed completed  ·  $total jobs';

  // —— Internal messaging (Phase 18) ——
  String get office => _es ? 'Oficina' : 'Office';
  String get technicianLabel => _es ? 'Técnico' : 'Technician';

  // —— Office personnel (Phase 18) ——
  String get officePersonnelTitle => _es ? 'Personal de oficina' : 'Office Personnel';
  String get officePersonnelSubtitle => _es
      ? 'Propietarios, administradores y personal de oficina, separado de los técnicos de campo.'
      : 'Owners, admins, and office staff — separate from field technicians.';
  String get inviteUser => _es ? 'Invitar usuario' : 'Invite user';
  String get loadingOfficePersonnel =>
      _es ? 'Cargando personal de oficina…' : 'Loading office personnel…';
  String get noOfficeUsers => _es ? 'No hay usuarios de oficina' : 'No office users';
  String get noOfficeUsersFiltered => _es
      ? 'Ningún propietario, administrador o personal de oficina coincide con este filtro.'
      : 'No owner, admin, or office staff profiles matched this filter.';
  String get deactivatedLabel => _es ? 'Desactivado' : 'Deactivated';
}
