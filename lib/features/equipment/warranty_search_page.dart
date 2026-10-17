import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/controllers/customer_controller.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/properties/property_history_widgets.dart';
import 'package:hvac_admin/features/shared/widgets/mobile_list_tile.dart';
import 'package:provider/provider.dart';

class WarrantySearchPage extends StatefulWidget {
  const WarrantySearchPage({super.key});

  @override
  State<WarrantySearchPage> createState() => _WarrantySearchPageState();
}

class _WarrantySearchPageState extends State<WarrantySearchPage> {
  final _results = <WarrantyArchiveEntry>[];
  String _query = '';
  bool _loading = false;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CustomerController>().load();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(value));
  }

  Future<void> _search(String value) async {
    final query = value.trim();
    setState(() {
      _query = query;
      _loading = true;
      _error = null;
    });
    if (query.isEmpty) {
      setState(() {
        _results.clear();
        _loading = false;
      });
      return;
    }
    try {
      final page = await context.read<CustomerController>().fetchWarrantyArchivePage(offset: 0, search: query);
      if (!mounted || _query != query) return;
      setState(() {
        _results
          ..clear()
          ..addAll(page.items);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Warranty search failed.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => context.go(AdminModule.equipment.path),
                icon: const Icon(Icons.arrow_back),
              ),
              const Expanded(child: Text('Warranty archive', style: AppTypography.headlineMedium)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSearchField(
            key: const Key('warranty-search-field'),
            hint: 'Search by customer name, address, or serial…',
            autofocus: true,
            onChanged: _onQueryChanged,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
          ],
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: _loading
                ? const LoadingState(message: 'Searching warranties…')
                : _query.isEmpty
                    ? const EmptyState(
                        title: 'Warranty archive',
                        message: 'Search by customer name, property address, or equipment serial.',
                        icon: Icons.verified_outlined,
                      )
                    : _results.isEmpty
                        ? const EmptyState(
                            title: 'No warranties found',
                            message: 'Try a different customer, address, or serial number.',
                            icon: Icons.verified_outlined,
                          )
                        : ListView.separated(
                            itemCount: _results.length,
                            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              final entry = _results[index];
                              return MobileListTile(
                                title: entry.warranty.title,
                                subtitle: '${entry.customerName}  ·  ${entry.propertyAddress}',
                                meta:
                                    '${entry.manufacturer} ${entry.model}  ·  Serial ${entry.serial}  ·  Expires ${formatDate(entry.warranty.expiresOn)}',
                                trailing: WarrantyChip(state: entry.warranty.state),
                                onTap: () => context.go('${AdminModule.equipment.path}/${entry.equipmentId}'),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
