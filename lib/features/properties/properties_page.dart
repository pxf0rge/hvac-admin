import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/controllers/customer_controller.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/shared/widgets/mobile_list_tile.dart';
import 'package:hvac_admin/features/shared/widgets/paged_search_list.dart';
import 'package:provider/provider.dart';

class PropertiesPage extends StatefulWidget {
  const PropertiesPage({super.key});

  @override
  State<PropertiesPage> createState() => _PropertiesPageState();
}

class _PropertiesPageState extends State<PropertiesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<CustomerController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final directory = context.watch<CustomerController>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Properties', style: AppTypography.headlineMedium),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: PagedSearchList(
              key: const Key('properties-list'),
              refreshToken: directory.refreshToken,
              searchHint: 'Search address or customer',
              emptyTitle: 'No properties',
              emptyMessage: 'No properties match this search.',
              fetchPage: (offset, query) => directory.fetchPropertiesPage(offset: offset, search: query),
              itemBuilder: (context, property) {
                final customer = directory.customerById(property.customerId);
                return MobileListTile(
                  title: property.address,
                  subtitle: property.fullAddress,
                  meta: customer?.displayName ?? property.type.label,
                  onTap: () => context.go('${AdminModule.properties.path}/${property.id}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
