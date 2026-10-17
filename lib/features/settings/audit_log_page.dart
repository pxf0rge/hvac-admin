import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/audit/audit_labels.dart';
import 'package:hvac_admin/core/controllers/audit_controller.dart';
import 'package:hvac_admin/core/controllers/management_auth_controller.dart';
import 'package:hvac_admin/core/models/audit_log_record.dart';
import 'package:hvac_admin/core/utils/formatters.dart' show formatDateTime;
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:provider/provider.dart';

class AuditLogPage extends StatefulWidget {
  const AuditLogPage({super.key});

  @override
  State<AuditLogPage> createState() => _AuditLogPageState();
}

class _AuditLogPageState extends State<AuditLogPage> {
  late final TextEditingController _actorQuery;
  String? _selectedAction;

  @override
  void initState() {
    super.initState();
    _actorQuery = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final canView = context.read<ManagementAuthController>().canViewFinancials;
      if (!canView) {
        context.go('/settings');
        return;
      }
      context.read<AuditController>().load(force: true);
    });
  }

  @override
  void dispose() {
    _actorQuery.dispose();
    super.dispose();
  }

  Future<void> _applyFilters() async {
    await context.read<AuditController>().applyFilters(
          action: _selectedAction,
          actorQuery: _actorQuery.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final audit = context.watch<AuditController>();
    final canView = context.watch<ManagementAuthController>().canViewFinancials;
    if (!canView) {
      return const Center(child: Text('Access denied'));
    }

    return ListView(
      key: const Key('audit-log-page'),
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl),
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/settings'),
            ),
            Text('Audit log', style: AppTypography.titleLarge),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String?>(
                key: const Key('audit-action-filter'),
                value: _selectedAction,
                decoration: const InputDecoration(labelText: 'Action type'),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('All actions')),
                  for (final action in AuditController.actionOptions)
                    DropdownMenuItem(value: action, child: Text(auditActionLabel(action))),
                ],
                onChanged: (value) => setState(() => _selectedAction = value),
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                key: const Key('audit-actor-filter'),
                controller: _actorQuery,
                label: 'User (name or role)',
                hint: 'e.g. Diana',
              ),
              const SizedBox(height: AppSpacing.md),
              AppPrimaryButton(
                key: const Key('audit-apply-filters'),
                label: audit.isLoading ? 'Loading…' : 'Apply filters',
                expanded: true,
                onPressed: audit.isLoading ? null : _applyFilters,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (audit.error != null)
          SurfaceCard(
            child: Text(audit.error!, style: AppTypography.bodySmall.copyWith(color: AppColors.danger)),
          ),
        if (audit.isLoading && audit.entries.isEmpty)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (audit.entries.isEmpty)
          const SurfaceCard(
            child: Text('No audit entries match your filters.', style: AppTypography.bodyMedium),
          )
        else
          SurfaceCard(
            key: const Key('audit-log-list'),
            child: Column(
              children: [
                for (final entry in audit.entries) ...[
                  _AuditEntryTile(entry: entry),
                  if (entry != audit.entries.last) const Divider(height: 1),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _AuditEntryTile extends StatelessWidget {
  const _AuditEntryTile({required this.entry});

  final AuditLogRecord entry;

  @override
  Widget build(BuildContext context) {
    final metadata = entry.displayMetadata;
    final metadataText = metadata.entries
        .map((item) => '${item.key}: ${item.value}')
        .join(' · ');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(auditActionLabel(entry.action), style: AppTypography.titleMedium),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${entry.actorName ?? 'System'} · ${formatDateTime(entry.at.toIso8601String())}',
            style: AppTypography.bodySmall,
          ),
          Text(
            '${entry.entityType} · ${entry.entityId}',
            style: AppTypography.labelMedium,
          ),
          if (metadataText.isNotEmpty)
            Text(metadataText, style: AppTypography.bodySmall),
        ],
      ),
    );
  }
}
