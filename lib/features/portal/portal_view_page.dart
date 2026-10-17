import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hvac_admin/core/portal/portal_link_service.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PortalViewPage extends StatefulWidget {
  const PortalViewPage({super.key, required this.token, required this.expectedType});

  final String token;
  final String expectedType; // estimate | invoice | document

  @override
  State<PortalViewPage> createState() => _PortalViewPageState();
}

class _PortalViewPageState extends State<PortalViewPage> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _payload;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await context.read<PortalLinkService>().resolve(widget.token);
      if (!mounted) return;
      if (result['ok'] != true) {
        setState(() {
          _loading = false;
          _error = _friendlyError(result['error']?.toString());
          _payload = null;
        });
        return;
      }
      final payload = Map<String, dynamic>.from(result['payload'] as Map? ?? {});
      final type = payload['resource_type']?.toString();
      if (type != null && type != widget.expectedType) {
        setState(() {
          _loading = false;
          _error = 'This link is invalid or has expired. Contact the office.';
        });
        return;
      }
      setState(() {
        _loading = false;
        _payload = payload;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'This link is invalid or has expired. Contact the office.';
      });
    }
  }

  String _friendlyError(String? code) {
    return switch (code) {
      'expired_token' => 'This link has expired. Contact the office for a new one.',
      'used_token' => 'This document link was already used. Contact the office if you need another copy.',
      _ => 'This link is invalid or has expired. Contact the office.',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_title),
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const LoadingState(message: 'Loading…')
          : _error != null
              ? EmptyState(title: 'Unavailable', message: _error!, icon: Icons.link_off_outlined)
              : _PortalPayloadView(token: widget.token, payload: _payload!),
    );
  }

  String get _title => switch (widget.expectedType) {
        'estimate' => 'Your estimate',
        'invoice' => 'Your invoice',
        'document' => 'Your document',
        _ => 'Customer portal',
      };
}

class _PortalPayloadView extends StatefulWidget {
  const _PortalPayloadView({required this.token, required this.payload});

  final String token;
  final Map<String, dynamic> payload;

  @override
  State<_PortalPayloadView> createState() => _PortalPayloadViewState();
}

class _PortalPayloadViewState extends State<_PortalPayloadView> {
  bool _paying = false;
  String? _payError;
  String? _checkoutUrl;
  bool _downloading = false;
  String? _downloadUrl;
  String? _downloadError;

  bool get _documentDownloadable =>
      (widget.payload['resource_type']?.toString() ?? '') == 'document' &&
      (widget.payload['downloadable'] == true) &&
      (widget.payload['storage_path']?.toString() ?? '').isNotEmpty;

  /// Phase 20: fetch a short-lived signed download URL via the token-gated
  /// Edge function (no office login, no public bucket exposure).
  Future<void> _download() async {
    setState(() {
      _downloading = true;
      _downloadError = null;
      _downloadUrl = null;
    });
    try {
      final client = () {
        try {
          return context.read<SupabaseClient>();
        } catch (_) {
          return null;
        }
      }();
      if (client == null) {
        setState(() {
          _downloading = false;
          _downloadError = 'Download is unavailable in this build. Contact the office.';
        });
        return;
      }
      final response = await client.functions.invoke(
        'portal-download',
        body: {'token': widget.token},
      );
      final data = response.data;
      if (response.status >= 400 || data is! Map) {
        final message = data is Map
            ? (data['message'] ?? data['error'] ?? 'Download unavailable').toString()
            : 'Download unavailable';
        setState(() {
          _downloading = false;
          _downloadError = message;
        });
        return;
      }
      final url = (data['download_url'] ?? '').toString().trim();
      if (url.isEmpty) {
        setState(() {
          _downloading = false;
          _downloadError = 'Download URL missing. Contact the office.';
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _downloadUrl = url;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _downloading = false;
        _downloadError = e.toString();
      });
    }
  }

  Future<void> _payNow() async {
    setState(() {
      _paying = true;
      _payError = null;
    });
    try {
      final client = () {
        try {
          return context.read<SupabaseClient>();
        } catch (_) {
          return null;
        }
      }();
      if (client == null) {
        setState(() {
          _paying = false;
          _payError = 'Online pay is unavailable in this build. Contact the office.';
        });
        return;
      }
      final response = await client.functions.invoke(
        'portal-pay',
        body: {'token': widget.token},
      );
      final data = response.data;
      if (response.status >= 400 || data is! Map) {
        final message = data is Map
            ? (data['message'] ?? data['error'] ?? 'Payment unavailable').toString()
            : 'Payment unavailable';
        setState(() {
          _paying = false;
          _payError = message;
        });
        return;
      }
      final url = (data['checkout_url'] ?? '').toString().trim();
      if (url.isEmpty) {
        setState(() {
          _paying = false;
          _payError = 'Checkout URL missing. Contact the office.';
        });
        return;
      }
      await Clipboard.setData(ClipboardData(text: url));
      if (!mounted) return;
      setState(() {
        _paying = false;
        _checkoutUrl = url;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _paying = false;
        _payError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final payload = widget.payload;
    final company = Map<String, dynamic>.from(payload['company'] as Map? ?? {});
    final type = payload['resource_type']?.toString() ?? '';
    final lines = (payload['line_items'] as List?) ?? const [];
    final invoiceStatus = payload['status']?.toString() ?? '';
    final canPay = type == 'invoice' && invoiceStatus != 'paid' && invoiceStatus != 'cancelled';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        Text(company['company_name']?.toString() ?? 'Arctic HVAC Solutions', style: AppTypography.headlineMedium),
        if ((company['phone']?.toString() ?? '').isNotEmpty)
          Text(company['phone'].toString(), style: AppTypography.bodyMedium),
        if ((company['address']?.toString() ?? '').isNotEmpty)
          Text(company['address'].toString(), style: AppTypography.bodySmall),
        const SizedBox(height: AppSpacing.xl),
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type == 'document'
                    ? (payload['title']?.toString() ?? 'Document')
                    : (payload['number']?.toString() ?? type.toUpperCase()),
                style: AppTypography.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(payload['customer_name']?.toString() ?? '', style: AppTypography.bodyMedium),
              Text(payload['property_address']?.toString() ?? '', style: AppTypography.bodySmall),
              if (payload['issued_on'] != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text('Issued ${formatDate(payload['issued_on'].toString())}', style: AppTypography.labelMedium),
              ],
              if (payload['due_on'] != null)
                Text('Due ${formatDate(payload['due_on'].toString())}', style: AppTypography.labelMedium),
              if ((payload['notes']?.toString() ?? '').isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(payload['notes'].toString(), style: AppTypography.bodySmall),
              ],
              if (type == 'document') ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Signed by ${payload['signer_name'] ?? 'customer'}'
                  '${payload['signed_at'] == null ? '' : ' on ${formatDate(payload['signed_at'].toString().split('T').first)}'}',
                  style: AppTypography.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                // Phase 20: secure download through the magic-link token.
                if (_documentDownloadable) ...[
                  AppPrimaryButton(
                    key: const Key('portal-download'),
                    label: _downloading ? 'Preparing download…' : 'Download document',
                    icon: Icons.download_outlined,
                    onPressed: _downloading ? null : _download,
                  ),
                  if (_downloadError != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(_downloadError!, style: AppTypography.bodySmall.copyWith(color: AppColors.danger)),
                  ],
                  if (_downloadUrl != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Download link (expires in 5 minutes):',
                      style: AppTypography.labelSmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    SelectableText(
                      _downloadUrl!,
                      key: const Key('portal-download-url'),
                      style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
                    ),
                  ],
                ] else
                  Text(
                    'A downloadable copy is not available yet. Contact us with this link reference.',
                    style: AppTypography.bodySmall,
                  ),
              ],
              if (lines.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                const Text('Line items', style: AppTypography.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                for (final raw in lines)
                  Builder(
                    builder: (context) {
                      final item = Map<String, dynamic>.from(raw as Map);
                      final qty = (item['quantity'] as num?)?.toDouble() ?? 0;
                      final price = (item['unit_price'] as num?)?.toDouble() ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item['description'] ?? ''} × ${qty.toStringAsFixed(qty % 1 == 0 ? 0 : 2)}',
                                style: AppTypography.bodyMedium,
                              ),
                            ),
                            Text(formatCurrency(qty * price), style: AppTypography.titleMedium),
                          ],
                        ),
                      );
                    },
                  ),
                const Divider(),
                if ((payload['tax_rate_pct'] as num?) != null &&
                    (payload['tax_rate_pct'] as num) > 0) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Subtotal ${formatCurrency(_total(lines))}',
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Tax (${(payload['tax_rate_pct'] as num).toStringAsFixed(2)}%) '
                      '${formatCurrency(_total(lines) * (payload['tax_rate_pct'] as num) / 100)}',
                      style: AppTypography.bodyMedium,
                    ),
                  ),
                ],
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    // Phase 22: grand total is tax-inclusive when provided.
                    'Total ${formatCurrency(_grandTotal(payload, lines))}',
                    key: const Key('portal-total'),
                    style: AppTypography.titleLarge,
                  ),
                ),
              ],
              if (type == 'invoice') ...[
                const SizedBox(height: AppSpacing.lg),
                if (canPay) ...[
                  AppPrimaryButton(
                    key: const Key('portal-pay-now'),
                    label: _paying ? 'Starting checkout…' : 'Pay now',
                    icon: Icons.credit_card_outlined,
                    onPressed: _paying ? null : _payNow,
                  ),
                  if (_payError != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(_payError!, style: AppTypography.bodySmall.copyWith(color: AppColors.danger)),
                  ],
                  if (_checkoutUrl != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Checkout link (copied): $_checkoutUrl',
                      key: const Key('portal-checkout-url'),
                      style: AppTypography.labelSmall,
                    ),
                  ],
                ] else
                  Text(
                    payload['pay_hint']?.toString() ??
                        (invoiceStatus == 'paid'
                            ? 'This invoice is paid. Thank you.'
                            : 'Contact the office to pay this invoice.'),
                    style: AppTypography.bodyMedium,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  double _total(List<dynamic> lines) {
    var sum = 0.0;
    for (final raw in lines) {
      final item = Map<String, dynamic>.from(raw as Map);
      final qty = (item['quantity'] as num?)?.toDouble() ?? 0;
      final price = (item['unit_price'] as num?)?.toDouble() ?? 0;
      sum += qty * price;
    }
    return sum;
  }

  /// Phase 22: prefer the server-computed tax-inclusive grand total.
  double _grandTotal(Map<String, dynamic> payload, List<dynamic> lines) {
    final grand = (payload['grand_total'] as num?)?.toDouble();
    return grand ?? _total(lines);
  }
}
