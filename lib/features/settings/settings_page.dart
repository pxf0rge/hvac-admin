import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/controllers/management_auth_controller.dart';
import 'package:hvac_admin/core/controllers/notification_preferences_controller_admin.dart';
import 'package:hvac_admin/core/controllers/settings_controller.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/models/company_settings.dart';
import 'package:hvac_admin/core/models/integration_credentials.dart';
import 'package:hvac_admin/core/payments/payments_status_service.dart';
import 'package:hvac_admin/core/tracking/tracking_policy.dart';
import 'package:hvac_admin/data/wiring/repository_wiring.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/settings/accounting_connector_card.dart';
import 'package:hvac_admin/features/settings/integration_help_dialog.dart';
import 'package:hvac_admin/features/settings/integration_help_guide.dart';
import 'package:hvac_admin/features/settings/secure_storage_preview.dart';
import 'package:hvac_admin/features/shared/widgets/language_toggle.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _zip;
  late final TextEditingController _logoPath;
  late final TextEditingController _gpsTimezone;
  late final TextEditingController _gpsTimezoneNote;
  late final TextEditingController _reminderLeadHours;

  late final TextEditingController _twilioSid;
  late final TextEditingController _twilioToken;
  late final TextEditingController _twilioFrom;
  late final TextEditingController _resendKey;
  late final TextEditingController _resendFrom;
  late final TextEditingController _translateKey;

  bool _hydrated = false;
  bool _integrationsHydrated = false;
  bool _showSecrets = false;
  TimeOfDay _gpsStart = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _gpsEnd = const TimeOfDay(hour: 18, minute: 0);
  bool _appointmentReminderEnabled = true;
  bool _maintenanceReminderEnabled = true;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _phone = TextEditingController();
    _address = TextEditingController();
    _city = TextEditingController();
    _state = TextEditingController();
    _zip = TextEditingController();
    _logoPath = TextEditingController();
    _gpsTimezone = TextEditingController(text: CompanySettings.defaultGpsTimezone);
    _gpsTimezoneNote = TextEditingController(text: CompanySettings.defaultGpsTimezoneNote);
    _reminderLeadHours = TextEditingController(
      text: '${CompanySettings.defaultAppointmentReminderLeadHours}',
    );
    _twilioSid = TextEditingController();
    _twilioToken = TextEditingController();
    _twilioFrom = TextEditingController();
    _resendKey = TextEditingController();
    _resendFrom = TextEditingController();
    _translateKey = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SettingsController>().load(force: true);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _city.dispose();
    _state.dispose();
    _zip.dispose();
    _logoPath.dispose();
    _gpsTimezone.dispose();
    _gpsTimezoneNote.dispose();
    _reminderLeadHours.dispose();
    _twilioSid.dispose();
    _twilioToken.dispose();
    _twilioFrom.dispose();
    _resendKey.dispose();
    _resendFrom.dispose();
    _translateKey.dispose();
    super.dispose();
  }

  void _hydrate(CompanySettings settings) {
    if (_hydrated &&
        _name.text == settings.companyName &&
        _phone.text == settings.phone &&
        _address.text == settings.addressLine) {
      return;
    }
    _name.text = settings.companyName;
    _phone.text = settings.phone;
    _address.text = settings.addressLine;
    _city.text = settings.city;
    _state.text = settings.state;
    _zip.text = settings.zip;
    _logoPath.text = settings.logoStoragePath;
    final window = settings.normalizedGpsWindow;
    _gpsStart = TimeOfDay(hour: window.$1 ~/ 60, minute: window.$1 % 60);
    _gpsEnd = TimeOfDay(hour: window.$2 ~/ 60, minute: window.$2 % 60);
    _gpsTimezone.text = settings.gpsTimezone;
    _gpsTimezoneNote.text = settings.gpsTimezoneNote;
    _appointmentReminderEnabled = settings.appointmentReminderEnabled;
    _maintenanceReminderEnabled = settings.maintenanceReminderEnabled;
    _reminderLeadHours.text = '${settings.normalizedAppointmentReminderLeadHours}';
    _hydrated = true;
  }

  int _minutesOf(TimeOfDay time) => time.hour * 60 + time.minute;

  String _formatTime(TimeOfDay time) {
    final h = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final m = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  void _hydrateIntegrations(IntegrationCredentials credentials) {
    if (_integrationsHydrated) return;
    _twilioSid.text = credentials.twilioAccountSid;
    _twilioToken.text = credentials.twilioAuthToken;
    _twilioFrom.text = credentials.twilioFromNumber;
    _resendKey.text = credentials.resendApiKey;
    _resendFrom.text = credentials.resendFromEmail;
    _translateKey.text = credentials.translateApiKey;
    _integrationsHydrated = true;
  }

  CompanySettings _draftFromForm() {
    final lead =
        int.tryParse(_reminderLeadHours.text.trim()) ?? CompanySettings.defaultAppointmentReminderLeadHours;
    return CompanySettings(
      companyName: _name.text.trim(),
      phone: _phone.text.trim(),
      addressLine: _address.text.trim(),
      city: _city.text.trim(),
      state: _state.text.trim(),
      zip: _zip.text.trim(),
      logoStoragePath: _logoPath.text.trim(),
      gpsWorkdayStartMinutes: _minutesOf(_gpsStart),
      gpsWorkdayEndMinutes: _minutesOf(_gpsEnd),
      gpsTimezone: _gpsTimezone.text.trim(),
      gpsTimezoneNote: _gpsTimezoneNote.text.trim(),
      appointmentReminderEnabled: _appointmentReminderEnabled,
      appointmentReminderLeadHours: lead,
      maintenanceReminderEnabled: _maintenanceReminderEnabled,
    );
  }

  IntegrationCredentials _integrationsFromForm() {
    return IntegrationCredentials(
      twilioAccountSid: _twilioSid.text.trim(),
      twilioAuthToken: _twilioToken.text.trim(),
      twilioFromNumber: _twilioFrom.text.trim(),
      resendApiKey: _resendKey.text.trim(),
      resendFromEmail: _resendFrom.text.trim(),
      translateApiKey: _translateKey.text.trim(),
    );
  }

  Future<void> _save(bool canEdit) async {
    if (!canEdit) return;
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(adminStringsRead(context).companyNameRequired)),
      );
      return;
    }
    final hoursError = CompanySettings.validateGpsHours(
      startMinutes: _minutesOf(_gpsStart),
      endMinutes: _minutesOf(_gpsEnd),
    );
    if (hoursError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(hoursError)));
      return;
    }
    if (_gpsTimezone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GPS timezone is required (e.g. America/Chicago)')),
      );
      return;
    }
    final lead =
        int.tryParse(_reminderLeadHours.text.trim()) ?? CompanySettings.defaultAppointmentReminderLeadHours;
    final leadError = CompanySettings.validateReminderLeadHours(lead);
    if (leadError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(leadError)));
      return;
    }
    final controller = context.read<SettingsController>();
    final strings = adminStringsRead(context);
    final ok = await controller.saveCompany(_draftFromForm(), canEdit: canEdit);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? strings.companySaved : strings.companySaveFailed)),
    );
  }

  Future<void> _pickGpsTime({required bool isStart}) async {
    final initial = isStart ? _gpsStart : _gpsEnd;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _gpsStart = picked;
      } else {
        _gpsEnd = picked;
      }
    });
  }

  Future<void> _saveIntegrations(bool canEdit) async {
    if (!canEdit) return;
    final draft = _integrationsFromForm();
    if (draft.twilioFromNumber.isNotEmpty && !draft.twilioFromNumber.startsWith('+')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Twilio from number must be E.164 (e.g. +17372583742)')),
      );
      return;
    }
    final controller = context.read<SettingsController>();
    final ok = await controller.saveIntegrations(draft, canEdit: canEdit);
    if (!mounted) return;
    if (ok) {
      _integrationsHydrated = false;
      final saved = controller.integrations;
      if (saved != null) _hydrateIntegrations(saved);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Integration credentials saved to Supabase'
              : 'Could not save integration credentials',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    final canEdit = context.watch<ManagementAuthController>().canViewFinancials;
    final company = settings.company;
    final integrations = settings.integrations;
    final strings = adminStrings(context);
    final policy = TrackingPolicy.fromCompanySettings(
      company?.copyWith(
        gpsWorkdayStartMinutes: _minutesOf(_gpsStart),
        gpsWorkdayEndMinutes: _minutesOf(_gpsEnd),
      ),
    );

    if (settings.isLoading && company == null) {
      return LoadingState(message: strings.loading);
    }
    if (company != null) _hydrate(company);
    if (canEdit && integrations != null) _hydrateIntegrations(integrations);

    return ListView(
      key: const Key('settings'),
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl),
      children: [
        if (settings.error != null) ...[
          SurfaceCard(
            child: Text(settings.error!, style: AppTypography.bodySmall.copyWith(color: AppColors.danger)),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        _sectionTitle(strings.language),
        const SurfaceCard(
          key: Key('settings-language'),
          child: LanguageToggle(),
        ),
        const SizedBox(height: AppSpacing.xl),
        _sectionTitle(strings.companyProfile),
        if (!canEdit)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: SurfaceCard(
              child: Text(
                'Only owners and admins can edit company profile. Values are shown read-only.',
                style: AppTypography.bodySmall,
              ),
            ),
          ),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                key: const Key('settings-company-name'),
                controller: _name,
                label: 'Company name',
                enabled: canEdit,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(controller: _phone, label: 'Phone', enabled: canEdit),
              const SizedBox(height: AppSpacing.md),
              AppTextField(controller: _address, label: 'Street address', enabled: canEdit, maxLines: 2),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: AppTextField(controller: _city, label: 'City', enabled: canEdit),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: AppTextField(controller: _state, label: 'State', enabled: canEdit)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: AppTextField(controller: _zip, label: 'ZIP', enabled: canEdit)),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _logoPath,
                label: 'Logo storage path (optional)',
                enabled: canEdit,
                hint: 'documents/company/logo.png',
              ),
              if (_logoPath.text.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                SecureStoragePreview(
                  key: const Key('settings-logo-preview'),
                  storagePath: _logoPath.text,
                  mediaAccess: context.read<HvacAdminRepositoryBundle>().secureMedia,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Document variables: {{company_name}}, {{company_phone}}, {{company_address}}',
                style: AppTypography.labelMedium,
              ),
              if (canEdit) ...[
                const SizedBox(height: AppSpacing.lg),
                AppPrimaryButton(
                  key: const Key('save-company-settings'),
                  label: settings.isSaving ? 'Saving…' : 'Save company',
                  expanded: true,
                  onPressed: settings.isSaving ? null : () => _save(canEdit),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _sectionTitle(strings.workingHours),
        SurfaceCard(
          key: const Key('settings-working-hours'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('GPS tracking window', style: AppTypography.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Technicians may record locations only during this window. '
                'Server enforces the same hours using the company timezone (never 24/7).',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Preview: ${policy.hoursLabel}', style: AppTypography.bodyMedium),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppSecondaryButton(
                    key: const Key('settings-gps-start'),
                    label: 'Start ${_formatTime(_gpsStart)}',
                    icon: Icons.schedule,
                    onPressed: canEdit ? () => _pickGpsTime(isStart: true) : null,
                  ),
                  AppSecondaryButton(
                    key: const Key('settings-gps-end'),
                    label: 'End ${_formatTime(_gpsEnd)}',
                    icon: Icons.schedule_outlined,
                    onPressed: canEdit ? () => _pickGpsTime(isStart: false) : null,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                key: const Key('settings-gps-timezone'),
                controller: _gpsTimezone,
                label: 'IANA timezone',
                hint: 'America/Chicago',
                enabled: canEdit,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                key: const Key('settings-gps-timezone-note'),
                controller: _gpsTimezoneNote,
                label: 'Timezone note',
                hint: 'Central Time',
                enabled: canEdit,
              ),
              if (canEdit) ...[
                const SizedBox(height: AppSpacing.lg),
                AppPrimaryButton(
                  key: const Key('save-gps-hours'),
                  label: settings.isSaving ? 'Saving…' : 'Save working hours',
                  expanded: true,
                  onPressed: settings.isSaving ? null : () => _save(canEdit),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _sectionTitle(strings.automatedReminders),
        SurfaceCard(
          key: const Key('settings-automated-reminders'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Uses Twilio/Resend credentials and customer preferred language. '
                'Scheduler: Edge Function send-reminders (cron secret).',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                key: const Key('settings-appointment-reminder-enabled'),
                contentPadding: EdgeInsets.zero,
                title: Text(strings.appointmentReminders),
                subtitle: const Text('SMS/email before job start (scheduled date + start time)'),
                value: _appointmentReminderEnabled,
                onChanged: canEdit
                    ? (value) => setState(() => _appointmentReminderEnabled = value)
                    : null,
              ),
              AppTextField(
                key: const Key('settings-appointment-reminder-lead'),
                controller: _reminderLeadHours,
                label: strings.reminderLeadHours,
                hint: '24',
                enabled: canEdit && _appointmentReminderEnabled,
                keyboardType: TextInputType.number,
              ),
              SwitchListTile(
                key: const Key('settings-maintenance-reminder-enabled'),
                contentPadding: EdgeInsets.zero,
                title: Text(strings.maintenanceReminders),
                subtitle: const Text('On/after renewal reminder date for active agreements'),
                value: _maintenanceReminderEnabled,
                onChanged: canEdit
                    ? (value) => setState(() => _maintenanceReminderEnabled = value)
                    : null,
              ),
              if (canEdit) ...[
                const SizedBox(height: AppSpacing.lg),
                AppPrimaryButton(
                  key: const Key('save-reminder-settings'),
                  label: settings.isSaving ? 'Saving…' : strings.saveReminders,
                  expanded: true,
                  onPressed: settings.isSaving ? null : () => _save(canEdit),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _sectionTitle('Online payments (Stripe)'),
        if (canEdit)
          _PaymentsReadinessCard(key: const Key('settings-payments-readiness'))
        else
          SurfaceCard(
            child: Text(
              'Only owners and admins can view payment integration readiness.',
              style: AppTypography.bodySmall,
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
        // Phase 24: QuickBooks/Xero connector (owner/admin only).
        if (canEdit) ...[
          _sectionTitle('Accounting connector'),
          const AccountingConnectorCard(),
          const SizedBox(height: AppSpacing.xl),
        ],
        const SizedBox(height: AppSpacing.xl),
        _sectionTitle(strings.messagingIntegrations),
        if (!canEdit)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: SurfaceCard(
              child: Text(
                'Only owners and admins can view or edit Twilio / Resend API credentials.',
                style: AppTypography.bodySmall,
              ),
            ),
          )
        else
          SurfaceCard(
            key: const Key('settings-integrations'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Stored in Supabase so credentials survive app reinstall.',
                        style: AppTypography.bodySmall,
                      ),
                    ),
                    TextButton.icon(
                      key: const Key('settings-toggle-secrets'),
                      onPressed: () => setState(() => _showSecrets = !_showSecrets),
                      icon: Icon(_showSecrets ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      label: Text(_showSecrets ? 'Hide' : 'Show'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _statusChip(
                  label: 'Twilio SMS',
                  ready: integrations?.hasTwilio ?? false,
                ),
                const SizedBox(height: AppSpacing.sm),
                _credentialField(
                  key: const Key('settings-twilio-sid'),
                  controller: _twilioSid,
                  label: 'Twilio Account SID',
                  obscureText: !_showSecrets,
                  helpTopic: IntegrationHelpTopic.twilioAccountSid,
                ),
                const SizedBox(height: AppSpacing.md),
                _credentialField(
                  key: const Key('settings-twilio-token'),
                  controller: _twilioToken,
                  label: 'Twilio Auth Token',
                  obscureText: !_showSecrets,
                  helpTopic: IntegrationHelpTopic.twilioAuthToken,
                ),
                const SizedBox(height: AppSpacing.md),
                _credentialField(
                  key: const Key('settings-twilio-from'),
                  controller: _twilioFrom,
                  label: 'Twilio from number (E.164)',
                  hint: '+17372583742',
                  helpTopic: IntegrationHelpTopic.twilioFromNumber,
                ),
                const SizedBox(height: AppSpacing.lg),
                _statusChip(
                  label: 'Resend email',
                  ready: integrations?.hasResend ?? false,
                ),
                const SizedBox(height: AppSpacing.sm),
                _credentialField(
                  key: const Key('settings-resend-key'),
                  controller: _resendKey,
                  label: 'Resend API key',
                  obscureText: !_showSecrets,
                  helpTopic: IntegrationHelpTopic.resendApiKey,
                ),
                const SizedBox(height: AppSpacing.md),
                _credentialField(
                  key: const Key('settings-resend-from'),
                  controller: _resendFrom,
                  label: 'Resend from email',
                  hint: 'onboarding@resend.dev',
                  keyboardType: TextInputType.emailAddress,
                  helpTopic: IntegrationHelpTopic.resendFromEmail,
                ),
                const SizedBox(height: AppSpacing.lg),
                _statusChip(
                  label: 'DeepL translate',
                  ready: integrations?.hasTranslate ?? false,
                ),
                const SizedBox(height: AppSpacing.sm),
                _credentialField(
                  key: const Key('settings-translate-key'),
                  controller: _translateKey,
                  label: 'DeepL API key',
                  obscureText: !_showSecrets,
                  helpTopic: IntegrationHelpTopic.translateApiKey,
                ),
                const SizedBox(height: AppSpacing.lg),
                AppPrimaryButton(
                  key: const Key('save-integration-credentials'),
                  label: settings.isSavingIntegrations ? 'Saving…' : 'Save messaging credentials',
                  expanded: true,
                  onPressed: settings.isSavingIntegrations ? null : () => _saveIntegrations(canEdit),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
        _sectionTitle(strings.usersAndRoles),
        SurfaceCard(
          key: const Key('settings-office-users'),
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(AdminModule.officePersonnel.icon, color: AppColors.textSecondary),
              title: Text(AdminModule.officePersonnel.label, style: AppTypography.titleMedium),
              subtitle: const Text(
                'Browse owners, admins, and office staff. Owners/admins can invite and manage accounts.',
                style: AppTypography.bodySmall,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(AdminModule.officePersonnel.path),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const _NotificationPreferencesSection(),
        const SizedBox(height: AppSpacing.xl),
        if (canEdit) ...[
          _sectionTitle('Audit log'),
          SurfaceCard(
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                key: const Key('settings-audit-log'),
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history, color: AppColors.textSecondary),
                title: Text('View audit log', style: AppTypography.titleMedium),
                subtitle: const Text(
                  'Sensitive admin actions — owners and admins only',
                  style: AppTypography.bodySmall,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/settings/audit'),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        _sectionTitle('Document templates'),
        SurfaceCard(
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(AdminModule.documents.icon, color: AppColors.textSecondary),
              title: Text('Manage templates', style: AppTypography.titleMedium),
              subtitle: const Text('Edit service forms and variable placeholders', style: AppTypography.bodySmall),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(AdminModule.documents.path),
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(title, style: AppTypography.titleMedium),
    );
  }

  Widget _statusChip({required String label, required bool ready}) {
    return Row(
      children: [
        Icon(
          ready ? Icons.check_circle_outline : Icons.radio_button_unchecked,
          color: ready ? AppColors.success : AppColors.textSecondary,
          size: 20,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          ready ? '$label configured' : '$label not configured',
          style: AppTypography.labelMedium,
        ),
      ],
    );
  }

  Widget _credentialField({
    Key? key,
    required TextEditingController controller,
    required String label,
    required IntegrationHelpTopic helpTopic,
    String? hint,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AppTextField(
            key: key,
            controller: controller,
            label: label,
            hint: hint,
            obscureText: obscureText,
            autocorrect: false,
            keyboardType: keyboardType,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Tooltip(
            message: 'How to get this',
            child: OutlinedButton.icon(
              key: Key('help-${helpTopic.name}'),
              onPressed: () => showIntegrationHelpDialog(context, topic: helpTopic),
              icon: const Icon(Icons.help_outline, size: 18),
              label: const Text('Help'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationPreferencesSection extends StatefulWidget {
  const _NotificationPreferencesSection();

  @override
  State<_NotificationPreferencesSection> createState() =>
      _NotificationPreferencesSectionState();
}

class _NotificationPreferencesSectionState
    extends State<_NotificationPreferencesSection> {
  AdminNotificationPreferencesController? _controller;
  String? _initError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null && _initError == null) {
      try {
        final client = context.read<SupabaseClient>();
        _controller = AdminNotificationPreferencesController(
          AdminNotificationPreferencesRepository(client),
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _controller?.load();
        });
      } catch (_) {
        // No SupabaseClient in this build (mock/test wiring) — show fallback.
        _initError = 'Sign in to manage your notification preferences.';
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Text('Notifications', style: AppTypography.titleMedium),
        ),
        if (controller == null)
          SurfaceCard(
            child: Text(
              _initError ??
                  'Sign in to manage your notification preferences.',
              style: AppTypography.bodyMedium,
            ),
          )
        else
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final prefs = controller.preferences;
              return SurfaceCard(
                key: const Key('settings-notification-preferences'),
                child: controller.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your notification channels. Critical job-assign '
                            'in-app alerts always arrive.',
                            style: AppTypography.bodySmall,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          _prefTile(
                            key: const Key('settings-pref-in-app'),
                            label: 'In-app',
                            value: prefs.inAppEnabled,
                            onChanged: controller.isSaving
                                ? null
                                : (v) => controller.update(inApp: v),
                          ),
                          _prefTile(
                            key: const Key('settings-pref-email'),
                            label: 'Email',
                            value: prefs.emailEnabled,
                            onChanged: controller.isSaving
                                ? null
                                : (v) => controller.update(email: v),
                          ),
                          _prefTile(
                            key: const Key('settings-pref-sms'),
                            label: 'SMS',
                            value: prefs.smsEnabled,
                            onChanged: controller.isSaving
                                ? null
                                : (v) => controller.update(sms: v),
                          ),
                          _prefTile(
                            key: const Key('settings-pref-job-assign'),
                            label: 'Job assignments',
                            value: prefs.jobAssign,
                            onChanged: controller.isSaving
                                ? null
                                : (v) => controller.update(jobAssign: v),
                          ),
                          _prefTile(
                            key: const Key('settings-pref-messages'),
                            label: 'Messages',
                            value: prefs.messages,
                            onChanged: controller.isSaving
                                ? null
                                : (v) => controller.update(messages: v),
                          ),
                          _prefTile(
                            key: const Key('settings-pref-reminders'),
                            label: 'Reminders',
                            value: prefs.reminders,
                            onChanged: controller.isSaving
                                ? null
                                : (v) => controller.update(reminders: v),
                          ),
                          if (controller.error != null)
                            Text(
                              controller.error!,
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.danger),
                            ),
                        ],
                      ),
              );
            },
          ),
      ],
    );
  }

  Widget _prefTile({
    required Key key,
    required String label,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    // Material wrapper keeps ink splashes visible inside SurfaceCard's DecoratedBox.
    return Material(
      type: MaterialType.transparency,
      child: SwitchListTile(
        key: key,
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text(label, style: AppTypography.bodyMedium),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}


class _PaymentsReadinessCard extends StatefulWidget {
  const _PaymentsReadinessCard({super.key});

  @override
  State<_PaymentsReadinessCard> createState() => _PaymentsReadinessCardState();
}

class _PaymentsReadinessCardState extends State<_PaymentsReadinessCard> {
  PaymentsReadiness? _status;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final status = await context.read<PaymentsStatusService>().fetch();
    if (!mounted) return;
    setState(() {
      _status = status;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = _status ?? PaymentsReadiness.fallback;
    return SurfaceCard(
      key: const Key('settings-payments-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stripe secrets stay in Supabase Edge Function settings. '
            'Flutter never stores STRIPE_SECRET_KEY.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          if (_loading)
            const Text('Checking readiness…', style: AppTypography.labelMedium)
          else ...[
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                StatusChip(
                  label: status.ready ? 'Ready' : 'Not ready',
                  background: status.ready ? AppColors.successMuted : AppColors.warningMuted,
                  foreground: status.ready ? AppColors.success : AppColors.warning,
                ),
                StatusChip(label: status.testMode ? 'Test mode' : 'Live mode'),
                StatusChip(label: status.stripeConfigured ? 'Stripe key set' : 'Stripe key missing'),
                StatusChip(label: status.redirectsConfigured ? 'Redirect URLs set' : 'Redirect URLs missing'),
                StatusChip(label: status.webhookSecretConfigured ? 'Webhook secret set' : 'Webhook secret missing'),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('Invoice button label: ${status.label}', style: AppTypography.labelMedium),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            'Required secrets: STRIPE_SECRET_KEY, STRIPE_WEBHOOK_SECRET, '
            'PAYMENTS_SUCCESS_URL + PAYMENTS_CANCEL_URL (or PORTAL_BASE_URL). '
            'Deploy: create-checkout, payments-webhook, payments-status, portal-pay.',
            style: AppTypography.labelSmall,
          ),
          const SizedBox(height: AppSpacing.md),
          AppSecondaryButton(
            key: const Key('settings-payments-refresh'),
            label: 'Refresh status',
            icon: Icons.refresh,
            onPressed: _loading ? null : _refresh,
          ),
        ],
      ),
    );
  }
}
