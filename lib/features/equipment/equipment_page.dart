import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hvac_admin/core/controllers/customer_controller.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/data/mappers/enum_db.dart';
import 'package:hvac_admin/design_system/design_system.dart';
import 'package:hvac_admin/features/properties/property_history_widgets.dart';
import 'package:hvac_admin/features/shared/widgets/mobile_list_tile.dart';
import 'package:hvac_admin/features/shared/widgets/paged_search_list.dart';
import 'package:provider/provider.dart';

class EquipmentPage extends StatefulWidget {
  const EquipmentPage({super.key});

  @override
  State<EquipmentPage> createState() => _EquipmentPageState();
}

class _EquipmentPageState extends State<EquipmentPage> {
  String? _propertyId;
  String? _typeKey;
  WarrantyFilter _warrantyFilter = WarrantyFilter.any;

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
          Row(
            children: [
              const Expanded(child: Text('Equipment', style: AppTypography.headlineMedium)),
              AppSecondaryButton(
                label: 'Warranty search',
                icon: Icons.verified_outlined,
                onPressed: () => context.go('${AdminModule.equipment.path}/warranty-search'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 220,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Property'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _propertyId,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All properties')),
                        for (final property in directory.properties)
                          DropdownMenuItem(
                            value: property.id,
                            child: Text(property.address, overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      onChanged: (value) => setState(() => _propertyId = value),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 180,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Type'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _typeKey,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All types')),
                        for (final type in EquipmentType.values)
                          DropdownMenuItem(value: EnumDb.equipmentType(type), child: Text(type.label)),
                      ],
                      onChanged: (value) => setState(() => _typeKey = value),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 180,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Warranty'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<WarrantyFilter>(
                      value: _warrantyFilter,
                      isExpanded: true,
                      items: [
                        for (final filter in WarrantyFilter.values)
                          DropdownMenuItem(value: filter, child: Text(filter.label)),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _warrantyFilter = value);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: PagedSearchList(
              key: ValueKey('equipment-${_propertyId ?? 'all'}-${_typeKey ?? 'all'}-${_warrantyFilter.name}'),
              searchHint: 'Search manufacturer, model, serial, or address',
              emptyTitle: 'No equipment',
              emptyMessage: 'No equipment matches this search.',
              fetchPage: (offset, query) => directory.fetchEquipmentPage(
                offset: offset,
                search: query,
                propertyId: _propertyId,
                typeKey: _typeKey,
                warrantyFilter: _warrantyFilter,
              ),
              itemBuilder: (context, unit) {
                final property = directory.propertyById(unit.propertyId);
                return MobileListTile(
                  title: unit.catalogLine,
                  subtitle: '${unit.typeLabel}  ·  Serial ${unit.serial}',
                  meta: property?.fullAddress ?? unit.name,
                  trailing: unit.warrantyState == null ? null : WarrantyChip(state: unit.warrantyState!),
                  onTap: () => context.go('${AdminModule.equipment.path}/${unit.id}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
