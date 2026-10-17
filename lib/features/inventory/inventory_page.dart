import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/controllers/inventory_controller.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/data/pagination/paged_result.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/shared/widgets/mobile_list_tile.dart';
import 'package:hvac_admin/features/shared/widgets/paged_search_list.dart';
import 'package:provider/provider.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  bool _lowOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<InventoryController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryController>();

    if (inventory.isLoading && inventory.items.isEmpty) {
      return const LoadingState(message: 'Loading inventory…');
    }

    return Padding(
      key: const Key('inventory-page'),
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
                    Text('Inventory', style: AppTypography.headlineMedium),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      'Stock lives on warehouse, trucks, and devices — not on technicians.',
                      style: AppTypography.bodySmall,
                    ),
                  ],
                ),
              ),
              AppPrimaryButton(
                label: 'New part',
                icon: Icons.add,
                onPressed: () => context.go('${AdminModule.inventory.path}/new'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              FilterChip(
                key: const Key('inventory-low-only'),
                label: Text('Low warehouse (${inventory.lowStockItems.length})'),
                selected: _lowOnly,
                onSelected: (value) => setState(() => _lowOnly = value),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: PagedSearchList(
              key: ValueKey('inventory-list-$_lowOnly'),
              listKey: const Key('inventory-list'),
              refreshToken: inventory.refreshToken,
              searchHint: 'Search SKU, name, or category',
              emptyTitle: 'No parts',
              emptyMessage: 'Add catalog items to track warehouse and truck stock.',
              fetchPage: (offset, query) async {
                final page = await inventory.fetchItemsPage(offset: offset, search: query);
                if (!_lowOnly) return page;
                final filtered = page.items.where(inventory.isLow).toList();
                return PagedResult(
                  items: filtered,
                  hasMore: page.hasMore,
                  nextOffset: page.nextOffset,
                );
              },
              itemBuilder: (context, item) {
                final warehouse = inventory.warehouseQty(item.id);
                final assigned = inventory.assignedQty(item.id);
                final low = inventory.isLow(item);
                return MobileListTile(
                  key: Key('inventory-row-${item.id}'),
                  title: item.name,
                  subtitle: '${item.sku} · ${item.category}',
                  meta:
                      'Total ${inventory.totalQty(item.id)} ${item.unit} · WH $warehouse · Assigned $assigned${low ? ' · LOW' : ''} · Reorder ${item.minQty}',
                  onTap: () => context.go('${AdminModule.inventory.path}/${item.id}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
