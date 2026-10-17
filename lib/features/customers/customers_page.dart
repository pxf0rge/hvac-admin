import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/controllers/customer_controller.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/customers/create_crm_dialog.dart';
import 'package:hvac_admin/features/shared/widgets/language_toggle.dart';
import 'package:hvac_admin/features/shared/widgets/mobile_list_tile.dart';
import 'package:hvac_admin/features/shared/widgets/paged_search_list.dart';
import 'package:provider/provider.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
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
    final strings = adminStrings(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(strings.customersTitle, style: AppTypography.headlineMedium)),
              AppPrimaryButton(
                label: strings.addCustomer,
                icon: Icons.person_add_outlined,
                onPressed: () async {
                  final saved = await showCreateCustomerDialog(context);
                  if (saved != null && context.mounted) {
                    context.go('${AdminModule.customers.path}/${saved.id}');
                  }
                },
              ),
            ],
          ),
          if (directory.loadError != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(directory.loadError!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
            TextButton(onPressed: directory.refreshFromRemote, child: const Text('Retry')),
          ],
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: PagedSearchList(
              key: const Key('customers-list'),
              refreshToken: directory.refreshToken,
              searchHint: 'Search name, phone, email, or address',
              emptyTitle: 'No customers',
              emptyMessage: 'No customers match this search.',
              fetchPage: (offset, query) => directory.fetchCustomersPage(offset: offset, search: query),
              itemBuilder: (context, customer) => MobileListTile(
                title: customer.displayName,
                subtitle: '${formatPhone(customer.phone)}  ·  ${customer.email}',
                meta: '${customer.city}, ${customer.state}',
                onTap: () => context.go('${AdminModule.customers.path}/${customer.id}'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
