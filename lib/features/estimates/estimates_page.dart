import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/controllers/estimate_controller.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_billing.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/estimates/estimate_widgets.dart';
import 'package:hvac_admin/features/shared/widgets/mobile_list_tile.dart';
import 'package:hvac_admin/features/shared/widgets/paged_search_list.dart';
import 'package:provider/provider.dart';

class EstimatesPage extends StatefulWidget {
  const EstimatesPage({super.key});

  @override
  State<EstimatesPage> createState() => _EstimatesPageState();
}

class _EstimatesPageState extends State<EstimatesPage> {
  EstimateStatus? _status;

  @override
  Widget build(BuildContext context) {
    final estimates = context.watch<EstimateController>();
    return Padding(
      key: const Key('estimates-page'),
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estimates', style: AppTypography.headlineMedium),
                    SizedBox(height: AppSpacing.xs),
                    Text('Create, send, and track customer estimates linked to jobs.', style: AppTypography.bodySmall),
                  ],
                ),
              ),
              AppPrimaryButton(
                label: 'New estimate',
                icon: Icons.add,
                onPressed: () => context.go('${AdminModule.estimates.path}/new'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _status == null,
                onSelected: (_) => setState(() => _status = null),
              ),
              for (final status in EstimateStatus.values)
                FilterChip(
                  label: Text(status.label),
                  selected: _status == status,
                  onSelected: (_) => setState(() => _status = status),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: PagedSearchList<OfficeEstimate>(
              refreshToken: estimates.refreshToken,
              listKey: const Key('estimates-list'),
              searchHint: 'Search estimate number or notes',
              emptyTitle: 'No estimates',
              emptyMessage: 'Create an estimate from a job or start a new draft.',
              fetchPage: (offset, query) => estimates.fetchEstimatesPage(
                offset: offset,
                search: query,
                status: _status,
              ),
              itemBuilder: (context, estimate) {
                final totals = estimates.totalsFor(estimate);
                return MobileListTile(
                  key: Key('estimate-row-${estimate.id}'),
                  title: estimate.number,
                  subtitle: estimate.notes.isEmpty ? estimate.status.label : estimate.notes,
                  meta: '${formatCurrency(totals.total)} · ${formatDate(estimate.date)}',
                  trailing: EstimateStatusChip(status: estimate.status),
                  onTap: () => context.go('${AdminModule.estimates.path}/${estimate.id}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
