import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:hvac_admin/design_system/design_system.dart';

/// Phase 24: QuickBooks/Xero connector card for Settings.
///
/// Connect → server-issued authorize URL (OAuth secrets stay on the Edge).
/// Sync → one-way invoice push with server-side idempotency.
/// Disconnect → revokes local tokens via RPC. Tokens are never displayed.
class AccountingConnectorCard extends StatefulWidget {
  const AccountingConnectorCard({super.key});

  @override
  State<AccountingConnectorCard> createState() => _AccountingConnectorCardState();
}

class _AccountingConnectorCardState extends State<AccountingConnectorCard> {
  bool _loading = true;
  bool _busy = false;
  bool _connected = false;
  String? _tenantName;
  DateTime? _lastSyncAt;
  String? _message;
  String? _error;

  SupabaseClient? get _client {
    try {
      return context.read<SupabaseClient>();
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStatus());
  }

  Future<void> _loadStatus() async {
    final client = _client;
    if (client == null) {
      setState(() {
        _loading = false;
        _message = 'Connect the accounting API from a signed-in production build.';
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final rows = await client
          .from('accounting_connections')
          .select('provider, tenant_name, status, last_sync_at')
          .eq('provider', 'xero')
          .maybeSingle();
      if (!mounted) return;
      setState(() {
        _connected = rows != null && rows['status'] == 'connected';
        _tenantName = rows?['tenant_name']?.toString();
        final raw = rows?['last_sync_at']?.toString();
        _lastSyncAt = raw == null || raw.isEmpty ? null : DateTime.tryParse(raw);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        // Migration not applied yet — connector simply reads as unavailable.
        _message = 'Accounting connector table not available yet.';
      });
    }
  }

  Future<void> _connect() async {
    final client = _client;
    if (client == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final response = await client.functions.invoke('accounting-oauth-start');
      final data = response.data;
      final url = data is Map ? (data['authorize_url'] ?? '').toString() : '';
      if (response.status >= 400 || url.isEmpty) {
        setState(() {
          _busy = false;
          _error = data is Map
              ? (data['message'] ?? 'Could not start OAuth').toString()
              : 'Could not start OAuth';
        });
        return;
      }
      setState(() => _busy = false);
      _showNotice('Open this URL to authorize Xero, then complete the flow in the browser:',
          detail: url, selectable: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _sync() async {
    final client = _client;
    if (client == null) return;
    setState(() {
      _busy = true;
      _error = null;
      _message = null;
    });
    try {
      final response = await client.functions.invoke('accounting-sync-invoices');
      final data = response.data;
      if (response.status >= 400 || data is! Map) {
        setState(() {
          _busy = false;
          _error = data is Map
              ? (data['message'] ?? 'Sync failed').toString()
              : 'Sync failed';
        });
        return;
      }
      await _loadStatus();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = 'Pushed ${data['pushed'] ?? 0} invoice(s) to Xero'
            '${(data['failures'] as List?)?.isNotEmpty == true ? ' — some failed, see audit log' : ''}.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _disconnect() async {
    final client = _client;
    if (client == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await client.rpc('disconnect_accounting_connection', params: {'p_provider': 'xero'});
      await _loadStatus();
      if (!mounted) return;
      setState(() {
        _busy = false;
        _message = 'Disconnected. Local tokens revoked.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  void _showNotice(String message, {String? detail, bool selectable = false}) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accounting connector'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (detail != null) ...[
              const SizedBox(height: AppSpacing.sm),
              SelectableText(detail, style: AppTypography.labelSmall),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      key: const Key('settings-accounting-connector'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Accounting sync (Xero)', style: AppTypography.titleMedium),
              ),
              if (_loading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                StatusChip(
                  label: _connected ? 'Connected' : 'Not connected',
                  background: _connected ? AppColors.successMuted : AppColors.surfaceHover,
                  foreground: _connected ? AppColors.success : AppColors.textSecondary,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'One-way invoice sync to Xero. CSV export stays available as the offline fallback. '
            'Owner/admin only; OAuth secrets and tokens stay on the server.',
            style: AppTypography.bodySmall,
          ),
          if (_tenantName != null && _tenantName!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Organisation: $_tenantName', style: AppTypography.bodyMedium),
          ],
          if (_lastSyncAt != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Last sync: ${_lastSyncAt!.toIso8601String().split('.').first}',
              style: AppTypography.labelSmall,
            ),
          ],
          if (_message != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_message!, style: AppTypography.bodySmall.copyWith(color: AppColors.success)),
          ],
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_error!, style: AppTypography.bodySmall.copyWith(color: AppColors.danger)),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              if (!_connected)
                AppSecondaryButton(
                  key: const Key('accounting-connect'),
                  label: _busy ? 'Working…' : 'Connect Xero',
                  icon: Icons.link_outlined,
                  onPressed: _busy ? null : _connect,
                )
              else ...[
                AppPrimaryButton(
                  key: const Key('accounting-sync'),
                  label: _busy ? 'Syncing…' : 'Sync invoices',
                  icon: Icons.sync_outlined,
                  onPressed: _busy ? null : _sync,
                ),
                AppSecondaryButton(
                  key: const Key('accounting-disconnect'),
                  label: 'Disconnect',
                  icon: Icons.link_off_outlined,
                  onPressed: _busy ? null : _disconnect,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
