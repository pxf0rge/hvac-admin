import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/controllers/management_auth_controller.dart';
import 'package:hvac_admin/core/models/global_search_hit.dart';
import 'package:hvac_admin/core/search/global_search_service.dart';
import 'package:hvac_admin/data/wiring/repository_wiring.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/shared/widgets/mobile_list_tile.dart';
import 'package:provider/provider.dart';

class GlobalSearchPage extends StatefulWidget {
  const GlobalSearchPage({super.key});

  @override
  State<GlobalSearchPage> createState() => _GlobalSearchPageState();
}

class _GlobalSearchPageState extends State<GlobalSearchPage> {
  String _query = '';
  List<GlobalSearchHit> _hits = const [];
  bool _loading = false;
  String? _error;
  Timer? _debounce;

  GlobalSearchService get _searchService {
    final bundle = context.read<HvacAdminRepositoryBundle>();
    return GlobalSearchService(
      customers: bundle.customers,
      jobs: bundle.jobs,
      billing: bundle.billing,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _search(String query) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final includeFinancials = context.read<ManagementAuthController>().canViewFinancials;
      final hits = await _searchService.search(query, includeFinancials: includeFinancials);
      if (!mounted || _query != query) return;
      setState(() {
        _hits = hits;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Search failed. Try again.';
      });
    }
  }

  void _onQueryChanged(String value) {
    _query = value;
    _debounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _hits = const [];
        _loading = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(trimmed));
  }

  Iterable<GlobalSearchHit> _hitsFor(GlobalSearchKind kind) =>
      _hits.where((hit) => hit.kind == kind);

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const Key('global-search'),
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSearchField(
            key: const Key('global-search-field'),
            hint: 'Customer, phone, address, job number, equipment serial…',
            autofocus: true,
            onChanged: _onQueryChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          if (_loading) const LinearProgressIndicator(minHeight: 2, key: Key('global-search-loading')),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: _query.trim().isEmpty
                ? const EmptyState(
                    key: Key('global-search-empty'),
                    title: 'Global search',
                    message: 'Search customers, properties, jobs, and equipment without loading full tables.',
                    icon: Icons.search,
                  )
                : _hits.isEmpty && !_loading
                    ? const EmptyState(
                        key: Key('global-search-no-results'),
                        title: 'No matches',
                        message: 'Try another name, address, or job number.',
                        icon: Icons.search_off_outlined,
                      )
                    : ListView(
                        children: [
                          for (final kind in GlobalSearchKind.values)
                            if (_hitsFor(kind).isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: AppSpacing.sm),
                                child: Text(kind.sectionTitle, style: AppTypography.titleMedium),
                              ),
                              for (final hit in _hitsFor(kind)) ...[
                                MobileListTile(
                                  key: Key('global-search-hit-${hit.kind.name}-${hit.id}'),
                                  title: hit.title,
                                  subtitle: hit.subtitle,
                                  meta: hit.kind.tileMeta,
                                  onTap: () => context.go(hit.route),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                              ],
                            ],
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
