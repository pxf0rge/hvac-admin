import 'package:hvac_admin/core/models/catalog_option.dart';
import 'package:hvac_admin/core/models/company_settings.dart';
import 'package:hvac_admin/core/models/integration_credentials.dart';
import 'package:hvac_admin/core/audit/audit_actions.dart';
import 'package:hvac_admin/core/audit/audit_metadata.dart';
import 'package:hvac_admin/data/datasources/supabase_audit_log.dart';
import 'package:hvac_admin/core/models/office_user.dart';
import 'package:hvac_admin/core/enums/user_role.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/billing/invoice_policy.dart';
import 'package:hvac_admin/core/models/dashboard_snapshot.dart';
import 'package:hvac_admin/core/tracking/technician_location_fix.dart';
import 'package:hvac_admin/core/models/fleet_asset.dart';
import 'package:hvac_admin/core/models/maintenance_agreement.dart';
import 'package:hvac_admin/core/reports/operational_metrics_calculator.dart';
import 'package:hvac_admin/core/models/office_billing.dart';
import 'package:hvac_admin/core/models/office_payment.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/core/models/office_job.dart';
import 'package:hvac_admin/core/models/office_inventory.dart';
import 'package:hvac_admin/core/models/message_history_filter.dart';
import 'package:hvac_admin/core/models/message_webhook_failure.dart';
import 'package:hvac_admin/core/models/office_message.dart';
import 'package:hvac_admin/data/mappers/billing_mapper.dart';
import 'package:hvac_admin/data/mappers/customer_mapper.dart';
import 'package:hvac_admin/core/models/document_template.dart';
import 'package:hvac_admin/data/mappers/document_template_mapper.dart';
import 'package:hvac_admin/data/mappers/enum_db.dart';
import 'package:hvac_admin/data/mappers/equipment_mapper.dart';
import 'package:hvac_admin/data/mappers/fleet_mapper.dart';
import 'package:hvac_admin/data/mappers/inventory_mapper.dart';
import 'package:hvac_admin/data/mappers/job_mapper.dart';
import 'package:hvac_admin/data/mappers/message_mapper.dart';
import 'package:hvac_admin/data/mappers/company_settings_mapper.dart';
import 'package:hvac_admin/data/mappers/integration_credentials_mapper.dart';
import 'package:hvac_admin/data/mappers/maintenance_agreement_mapper.dart';
import 'package:hvac_admin/data/mappers/mapper_helpers.dart';
import 'package:hvac_admin/data/mappers/office_user_mapper.dart';
import 'package:hvac_admin/data/mappers/payment_mapper.dart';
import 'package:hvac_admin/data/mappers/property_mapper.dart';
import 'package:hvac_admin/data/pagination/list_paging.dart';
import 'package:hvac_admin/data/pagination/paged_result.dart';
import 'package:hvac_admin/data/repositories/billing_repository.dart';
import 'package:hvac_admin/data/repositories/communication_repository.dart';
import 'package:hvac_admin/data/repositories/customer_repository.dart';
import 'package:hvac_admin/data/repositories/document_template_repository.dart';
import 'package:hvac_admin/data/repositories/fleet_repository.dart';
import 'package:hvac_admin/data/repositories/inventory_repository.dart';
import 'package:hvac_admin/data/repositories/job_repository.dart';
import 'package:hvac_admin/data/repositories/maintenance_agreement_repository.dart';
import 'package:hvac_admin/data/repositories/reports_repository.dart';
import 'package:hvac_admin/data/repositories/settings_repository.dart';
import 'package:hvac_admin/data/repositories/technician_location_repository.dart';
import 'package:hvac_admin/data/repositories/technician_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseCustomerRepository implements CustomerRepository {
  SupabaseCustomerRepository(this.client);

  final SupabaseClient client;

  static const _customerColumns =
      'id, first_name, last_name, phone, email, city, state, preferred_language';
  static const _propertyColumns =
      'id, customer_id, address, city, state, zip, type, label, latitude, longitude';
  static const _equipmentColumns =
      'id, property_id, name, manufacturer, model, serial, type, capacity, installed_on, installer';

  @override
  Future<List<OfficeCustomer>> getCustomers() async {
    final rows = await client.from('customers').select(_customerColumns).order('last_name');
    return [for (final row in rows) CustomerMapper.fromRow(MapperHelpers.row(row))];
  }

  @override
  Future<OfficeCustomer?> getCustomer(String id) async {
    final row = await client.from('customers').select(_customerColumns).eq('id', id).maybeSingle();
    return row == null ? null : CustomerMapper.fromRow(MapperHelpers.row(row));
  }

  @override
  Future<List<OfficeProperty>> getPropertiesForCustomer(String customerId) async {
    final rows = await client
        .from('properties')
        .select(_propertyColumns)
        .eq('customer_id', customerId)
        .order('address');
    return [for (final row in rows) PropertyMapper.fromRow(MapperHelpers.row(row))];
  }

  @override
  Future<OfficeProperty?> getProperty(String id) async {
    final row = await client.from('properties').select(_propertyColumns).eq('id', id).maybeSingle();
    return row == null ? null : PropertyMapper.fromRow(MapperHelpers.row(row));
  }

  @override
  Future<List<PropertyEquipment>> getEquipmentForProperty(String propertyId) async {
    final rows = await client
        .from('equipment')
        .select(_equipmentColumns)
        .eq('property_id', propertyId)
        .order('name');
    return _hydrateEquipmentRows(rows);
  }

  @override
  Future<PropertyEquipment?> getEquipmentById(String id) async {
    final row = await client.from('equipment').select(_equipmentColumns).eq('id', id).maybeSingle();
    if (row == null) return null;
    final hydrated = await _hydrateEquipmentRows([row]);
    return hydrated.first;
  }

  @override
  Future<PagedResult<PropertyEquipment>> getEquipmentPage({
    int offset = 0,
    int limit = ListQuery.defaultLimit,
    String? search,
    String? propertyId,
    String? typeKey,
    WarrantyFilter warrantyFilter = WarrantyFilter.any,
  }) async {
    var query = _equipmentQuery(search);
    if (propertyId != null && propertyId.isNotEmpty) {
      query = query.eq('property_id', propertyId);
    }
    if (typeKey != null && typeKey.isNotEmpty) {
      query = query.eq('type', typeKey);
    }
    final rows = await query.order('name').range(offset, offset + limit);
    final hasMore = rows.length > limit;
    final slice = hasMore ? rows.sublist(0, limit) : rows;
    var items = await _hydrateEquipmentRows(slice);
    if (warrantyFilter != WarrantyFilter.any) {
      items = [
        for (final unit in items)
          if (_matchesWarrantyFilter(unit, warrantyFilter)) unit,
      ];
    }
    return PagedResult(
      items: items,
      nextOffset: hasMore ? offset + limit : null,
      hasMore: hasMore,
    );
  }

  bool _matchesWarrantyFilter(PropertyEquipment unit, WarrantyFilter filter) {
    return switch (filter) {
      WarrantyFilter.any => true,
      WarrantyFilter.none => unit.warranties.isEmpty,
      WarrantyFilter.active => unit.warrantyState == WarrantyState.active,
      WarrantyFilter.expiringSoon => unit.warrantyState == WarrantyState.expiringSoon,
      WarrantyFilter.expired => unit.warrantyState == WarrantyState.expired,
    };
  }

  @override
  Future<List<CatalogOption>> getEquipmentTypeCatalog() async {
    final rows = await client
        .from('equipment_type_catalog')
        .select('key, label, is_system')
        .order('label');
    return [
      for (final row in rows)
        CatalogOption(
          key: MapperHelpers.str(row['key']),
          label: MapperHelpers.str(row['label']),
          isSystem: row['is_system'] == true,
        ),
    ];
  }

  @override
  Future<CatalogOption> addEquipmentTypeOption(String label) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(label, 'label', 'must not be empty');
    final key = 'custom_${MapperHelpers.newUuid().replaceAll('-', '')}';
    final row = await client
        .from('equipment_type_catalog')
        .insert({'key': key, 'label': trimmed, 'is_system': false})
        .select('key, label, is_system')
        .single();
    return CatalogOption(
      key: MapperHelpers.str(row['key']),
      label: MapperHelpers.str(row['label']),
      isSystem: row['is_system'] == true,
    );
  }

  @override
  Future<PropertyEquipment> saveEquipment(PropertyEquipment equipment) async {
    final isNew = equipment.id.isEmpty || !MapperHelpers.isUuid(equipment.id);
    final payload = Map<String, dynamic>.from(EquipmentMapper.toRow(equipment));
    if (isNew) {
      payload.remove('id');
      final row = await client.from('equipment').insert(payload).select(_equipmentColumns).single();
      final hydrated = await _hydrateEquipmentRows([row]);
      return hydrated.first;
    }
    final row = await client
        .from('equipment')
        .update(payload)
        .eq('id', equipment.id)
        .select(_equipmentColumns)
        .single();
    final hydrated = await _hydrateEquipmentRows([row]);
    return hydrated.first;
  }

  @override
  Future<PropertyWarranty> saveWarranty({
    required String equipmentId,
    required PropertyWarranty warranty,
  }) async {
    await client.from('equipment_warranties').insert(
          EquipmentMapper.warrantyToRow(equipmentId: equipmentId, warranty: warranty),
        );
    return warranty;
  }

  @override
  Future<PagedResult<WarrantyArchiveEntry>> searchWarranties({
    int offset = 0,
    int limit = ListQuery.defaultLimit,
    String? search,
  }) async {
    final equipmentPage = await getEquipmentPage(offset: 0, limit: 500, search: search);
    final propertyIds = equipmentPage.items.map((unit) => unit.propertyId).toSet();
    final properties = <String, OfficeProperty>{};
    for (final id in propertyIds) {
      final property = await getProperty(id);
      if (property != null) properties[id] = property;
    }
    final customers = <String, OfficeCustomer>{};
    for (final property in properties.values) {
      if (customers.containsKey(property.customerId)) continue;
      final customer = await getCustomer(property.customerId);
      if (customer != null) customers[property.customerId] = customer;
    }

    final entries = <WarrantyArchiveEntry>[];
    for (final unit in equipmentPage.items) {
      final property = properties[unit.propertyId];
      if (property == null) continue;
      final customer = customers[property.customerId];
      final customerName = customer?.displayName ?? '';
      final blob = '${unit.serial} ${property.fullAddress} $customerName';
      if (!matchesSearch(blob, search)) continue;
      for (final warranty in unit.warranties) {
        entries.add(
          WarrantyArchiveEntry(
            equipmentId: unit.id,
            equipmentName: unit.name,
            manufacturer: unit.manufacturer,
            model: unit.model,
            serial: unit.serial,
            warranty: warranty,
            propertyId: property.id,
            propertyAddress: property.fullAddress,
            customerName: customerName,
          ),
        );
      }
    }
    entries.sort((a, b) => a.warranty.expiresOn.compareTo(b.warranty.expiresOn));
    final hasMore = entries.length > offset + limit;
    final slice = entries.skip(offset).take(limit).toList();
    return PagedResult(
      items: slice,
      nextOffset: hasMore ? offset + limit : null,
      hasMore: hasMore,
    );
  }

  PostgrestFilterBuilder<PostgrestList> _equipmentQuery(String? search) {
    final base = client.from('equipment').select(_equipmentColumns);
    final needle = search?.trim();
    if (needle == null || needle.isEmpty) return base;
    final pattern = '%$needle%';
    return base.or('name.ilike.$pattern,serial.ilike.$pattern,manufacturer.ilike.$pattern,model.ilike.$pattern');
  }

  Future<Map<String, List<PropertyWarranty>>> _warrantiesForMany(List<String> equipmentIds) async {
    if (equipmentIds.isEmpty) return {};
    final rows = await client
        .from('equipment_warranties')
        .select('equipment_id, title, serial, expires_on')
        .inFilter('equipment_id', equipmentIds);
    final map = <String, List<PropertyWarranty>>{};
    for (final row in rows) {
      final id = MapperHelpers.uuid(row['equipment_id']);
      map.putIfAbsent(id, () => []).add(EquipmentMapper.warrantyFromRow(MapperHelpers.row(row)));
    }
    return map;
  }

  Future<Map<String, ({List<NamedRecord> photos, List<NamedRecord> manuals})>> _mediaForMany(
    List<String> equipmentIds,
  ) async {
    if (equipmentIds.isEmpty) return {};
    final rows = await client
        .from('equipment_media')
        .select('equipment_id, kind, title, recorded_on, meta')
        .inFilter('equipment_id', equipmentIds);
    final photos = <String, List<NamedRecord>>{};
    final manuals = <String, List<NamedRecord>>{};
    for (final row in rows) {
      final id = MapperHelpers.uuid(row['equipment_id']);
      final media = EquipmentMapper.mediaFromRow(MapperHelpers.row(row));
      if (MapperHelpers.str(row['kind']) == 'manual') {
        manuals.putIfAbsent(id, () => []).add(media);
      } else {
        photos.putIfAbsent(id, () => []).add(media);
      }
    }
    return {
      for (final id in equipmentIds)
        id: (
          photos: photos[id] ?? const [],
          manuals: manuals[id] ?? const [],
        ),
    };
  }

  Future<Map<String, List<String>>> _jobLinksForMany(List<String> equipmentIds) async {
    if (equipmentIds.isEmpty) return {};
    final rows = await client
        .from('equipment_jobs')
        .select('equipment_id, job_id')
        .inFilter('equipment_id', equipmentIds);
    final map = <String, List<String>>{};
    for (final row in rows) {
      final id = MapperHelpers.uuid(row['equipment_id']);
      map.putIfAbsent(id, () => []).add(MapperHelpers.uuid(row['job_id']));
    }
    return map;
  }

  /// Type labels are resolved from the catalog table instead of a PostgREST
  /// embed so a missing foreign-key relationship (or unreachable catalog)
  /// cannot break equipment loads. Falls back to built-in labels on failure.
  Future<Map<String, String>> _typeLabels() async {
    try {
      final rows = await client.from('equipment_type_catalog').select('key, label');
      return {
        for (final row in rows)
          MapperHelpers.str(row['key']): MapperHelpers.str(row['label']),
      };
    } catch (_) {
      return const {};
    }
  }

  Future<List<PropertyEquipment>> _hydrateEquipmentRows(List<dynamic> rows) async {
    if (rows.isEmpty) return const [];
    final parsed = [for (final row in rows) MapperHelpers.row(row)];
    final ids = [for (final row in parsed) MapperHelpers.uuid(row['id'])];
    final typeLabels = await _typeLabels();
    final warranties = await _warrantiesForMany(ids);
    final media = await _mediaForMany(ids);
    final jobLinks = await _jobLinksForMany(ids);
    return [
      for (final row in parsed)
        EquipmentMapper.fromRow(
          row,
          typeLabels: typeLabels,
          warranties: warranties[MapperHelpers.uuid(row['id'])] ?? const [],
          photos: media[MapperHelpers.uuid(row['id'])]?.photos ?? const [],
          manuals: media[MapperHelpers.uuid(row['id'])]?.manuals ?? const [],
          serviceJobIds: jobLinks[MapperHelpers.uuid(row['id'])] ?? const [],
        ),
    ];
  }

  static const _jobColumns =
      'id, property_id, job_number, type, status, priority, scheduled_date, start_time, end_time, technician_id, truck_asset_id, description, notes, parts_used';
  static const _jobSelect = '$_jobColumns, technicians(first_name, last_name)';
  static const _estimateSelect =
      'id, number, status, issued_on, property_id, job_id, notes, estimate_line_items(description, quantity, unit_price, sort_order)';
  static const _invoiceSelect =
      'id, number, status, issued_on, due_on, property_id, job_id, estimate_id, notes, tax_rate_pct, invoice_line_items(description, quantity, unit_price, sort_order)';

  @override
  Future<PropertyHistory> getPropertyHistory(String propertyId) async {
    final jobRows = await client
        .from('jobs')
        .select(_jobSelect)
        .eq('property_id', propertyId)
        .order('scheduled_date', ascending: false);

    final jobs = <HistoryJob>[
      for (final row in jobRows) _historyJobFromRow(MapperHelpers.row(row)),
    ];

    final timelineRows = await client
        .from('property_timeline_events')
        .select('occurred_on, title, detail')
        .eq('property_id', propertyId)
        .order('occurred_on', ascending: false);

    final equipmentRows = await client
        .from('equipment')
        .select(_equipmentColumns)
        .eq('property_id', propertyId)
        .order('name');

    final equipment = await _hydrateEquipmentRows(equipmentRows);

    final estimateRows = await client
        .from('estimates')
        .select(_estimateSelect)
        .eq('property_id', propertyId)
        .order('issued_on', ascending: false);

    final invoiceRows = await client
        .from('invoices')
        .select(_invoiceSelect)
        .eq('property_id', propertyId)
        .order('issued_on', ascending: false);

    final estimates = [
      for (final row in estimateRows)
        MoneyRecord(
          id: MapperHelpers.uuid(row['id']),
          number: MapperHelpers.str(row['number']),
          status: EnumDb.estimateStatusFromDb(MapperHelpers.str(row['status'])).label,
          amount: BillingMapper.estimateFromRow(
            MapperHelpers.row(row),
            items: BillingMapper.lineItemsFromNested(row['estimate_line_items']),
          ).amount,
          date: MapperHelpers.dateOnly(row['issued_on']),
        ),
    ];

    final invoices = [
      for (final row in invoiceRows)
        MoneyRecord(
          id: MapperHelpers.uuid(row['id']),
          number: MapperHelpers.str(row['number']),
          status: EnumDb.invoiceStatusFromDb(MapperHelpers.str(row['status'])).label,
          amount: BillingMapper.invoiceFromRow(
            MapperHelpers.row(row),
            items: BillingMapper.lineItemsFromNested(row['invoice_line_items']),
          ).amount,
          date: MapperHelpers.dateOnly(row['issued_on']),
        ),
    ];

    final technicians = <String>{
      for (final job in jobs)
        if (job.technicianName.isNotEmpty && job.technicianName != 'Unassigned') job.technicianName,
    }.toList();

    final timeline = <TimelineEvent>[
      for (final row in timelineRows)
        TimelineEvent(
          at: MapperHelpers.dateOnly(row['occurred_on']),
          title: MapperHelpers.str(row['title']),
          detail: MapperHelpers.str(row['detail']),
        ),
      for (final job in jobs)
        TimelineEvent(
          at: job.date,
          title: '${job.jobNumber} · ${job.status.label}',
          detail: job.description.isEmpty ? job.type.label : job.description,
        ),
    ]..sort((a, b) => b.at.compareTo(a.at));

    return PropertyHistory(
      jobs: jobs,
      equipment: equipment,
      warranties: [for (final unit in equipment) ...unit.warranties],
      photos: [for (final unit in equipment) ...unit.photos],
      documents: [for (final unit in equipment) ...unit.manuals],
      estimates: estimates,
      invoices: invoices,
      technicians: technicians,
      timeline: timeline,
    );
  }

  HistoryJob _historyJobFromRow(Map<String, dynamic> row) {
    final tech = row['technicians'];
    var technicianName = 'Unassigned';
    if (tech is Map) {
      final name = '${MapperHelpers.str(tech['first_name'])} ${MapperHelpers.str(tech['last_name'])}'.trim();
      if (name.isNotEmpty) technicianName = name;
    }
    return JobMapper.historyFromRow(row, technicianName: technicianName);
  }

  @override
  Future<OfficeCustomer> saveCustomer(OfficeCustomer customer) async {
    final isNew = customer.id.isEmpty || !MapperHelpers.isUuid(customer.id);
    final payload = Map<String, dynamic>.from(CustomerMapper.toRow(customer));
    if (isNew) {
      payload.remove('id');
      final row = await client.from('customers').insert(payload).select(_customerColumns).single();
      return CustomerMapper.fromRow(MapperHelpers.row(row));
    }
    final row = await client
        .from('customers')
        .update(payload)
        .eq('id', customer.id)
        .select(_customerColumns)
        .single();
    return CustomerMapper.fromRow(MapperHelpers.row(row));
  }

  @override
  Future<List<OfficeProperty>> getProperties() async {
    final rows = await client.from('properties').select(_propertyColumns).order('address');
    return [for (final row in rows) PropertyMapper.fromRow(MapperHelpers.row(row))];
  }

  @override
  Future<PagedResult<OfficeProperty>> getPropertiesPage({
    int offset = 0,
    int limit = ListQuery.defaultLimit,
    String? search,
  }) async {
    final rows = await _propertyQuery(search).order('address').range(offset, offset + limit);
    final hasMore = rows.length > limit;
    final slice = hasMore ? rows.sublist(0, limit) : rows;
    return PagedResult(
      items: [for (final row in slice) PropertyMapper.fromRow(MapperHelpers.row(row))],
      nextOffset: hasMore ? offset + limit : null,
      hasMore: hasMore,
    );
  }

  @override
  Future<OfficeProperty> saveProperty(OfficeProperty property) async {
    final isNew = property.id.isEmpty || !MapperHelpers.isUuid(property.id);
    final payload = Map<String, dynamic>.from(PropertyMapper.toRow(property));
    if (isNew) {
      payload.remove('id');
      final row = await client.from('properties').insert(payload).select(_propertyColumns).single();
      return PropertyMapper.fromRow(MapperHelpers.row(row));
    }
    final row = await client
        .from('properties')
        .update(payload)
        .eq('id', property.id)
        .select(_propertyColumns)
        .single();
    return PropertyMapper.fromRow(MapperHelpers.row(row));
  }

  PostgrestFilterBuilder<PostgrestList> _customerQuery(String? search) {
    final base = client.from('customers').select(_customerColumns);
    final needle = search?.trim();
    if (needle == null || needle.isEmpty) return base;
    final pattern = '%$needle%';
    return base.or(
      'first_name.ilike.$pattern,last_name.ilike.$pattern,email.ilike.$pattern,phone.ilike.$pattern,city.ilike.$pattern',
    );
  }

  PostgrestFilterBuilder<PostgrestList> _propertyQuery(String? search) {
    final base = client.from('properties').select(_propertyColumns);
    final needle = search?.trim();
    if (needle == null || needle.isEmpty) return base;
    final pattern = '%$needle%';
    return base.or('address.ilike.$pattern,city.ilike.$pattern,zip.ilike.$pattern,label.ilike.$pattern');
  }

  @override
  Future<PagedResult<OfficeCustomer>> getCustomersPage({
    int offset = 0,
    int limit = ListQuery.defaultLimit,
    String? search,
  }) async {
    final needle = search?.trim();
    if (needle != null && needle.isNotEmpty) {
      final propertyRows = await _propertyQuery(search).limit(100);
      final customerIds = {
        for (final row in propertyRows) MapperHelpers.uuid(row['customer_id']),
      };
      final directRows = await _customerQuery(search).order('last_name').limit(100);
      final byId = <String, Map<String, dynamic>>{};
      for (final row in directRows) {
        byId[MapperHelpers.uuid(row['id'])] = MapperHelpers.row(row);
      }
      if (customerIds.isNotEmpty) {
        final extraRows = await client
            .from('customers')
            .select(_customerColumns)
            .inFilter('id', customerIds.toList())
            .order('last_name');
        for (final row in extraRows) {
          byId[MapperHelpers.uuid(row['id'])] = MapperHelpers.row(row);
        }
      }
      final merged = byId.values.toList()
        ..sort((a, b) => MapperHelpers.str(a['last_name']).compareTo(MapperHelpers.str(b['last_name'])));
      final hasMore = merged.length > offset + limit;
      final slice = merged.skip(offset).take(limit).toList();
      return PagedResult(
        items: [for (final row in slice) CustomerMapper.fromRow(row)],
        nextOffset: hasMore ? offset + limit : null,
        hasMore: hasMore,
      );
    }

    final rows = await _customerQuery(search).order('last_name').range(offset, offset + limit);
    final hasMore = rows.length > limit;
    final slice = hasMore ? rows.sublist(0, limit) : rows;
    return PagedResult(
      items: [for (final row in slice) CustomerMapper.fromRow(MapperHelpers.row(row))],
      nextOffset: hasMore ? offset + limit : null,
      hasMore: hasMore,
    );
  }
}

class SupabaseJobRepository implements JobRepository {
  SupabaseJobRepository(this.client, {SupabaseAuditLog? audit}) : _audit = audit;

  final SupabaseClient client;
  final SupabaseAuditLog? _audit;

  static const _jobColumns =
      'id, property_id, job_number, type, status, priority, scheduled_date, start_time, end_time, technician_id, truck_asset_id, description, notes, parts_used';
  static const _jobSelect =
      '$_jobColumns, technicians(first_name, last_name)';
  static const _equipmentColumns =
      'id, property_id, name, manufacturer, model, serial, type, capacity, installed_on, installer';

  @override
  Future<List<HistoryJob>> getJobs() async {
    final rows = await client.from('jobs').select(_jobSelect).order('scheduled_date', ascending: false);
    return [for (final row in rows) _historyFromRow(MapperHelpers.row(row))];
  }

  @override
  Future<PagedResult<HistoryJob>> getJobsPage({
    int offset = 0,
    int limit = ListQuery.defaultLimit,
    String? search,
    JobStatus? status,
    String? technicianId,
    String? customerId,
    String? dateFrom,
    String? dateTo,
  }) async {
    var query = _jobQuery(search);
    if (status != null) query = query.eq('status', EnumDb.jobStatus(status));
    if (technicianId != null && technicianId.isNotEmpty) {
      query = query.eq('technician_id', technicianId);
    }
    if (dateFrom != null && dateFrom.isNotEmpty) query = query.gte('scheduled_date', dateFrom);
    if (dateTo != null && dateTo.isNotEmpty) query = query.lte('scheduled_date', dateTo);
    if (customerId != null && customerId.isNotEmpty) {
      final propertyRows = await client.from('properties').select('id').eq('customer_id', customerId);
      final propertyIds = [for (final row in propertyRows) MapperHelpers.uuid(row['id'])];
      if (propertyIds.isEmpty) {
        return const PagedResult(items: [], hasMore: false);
      }
      query = query.inFilter('property_id', propertyIds);
    }
    final rows = await query.order('scheduled_date', ascending: false).range(offset, offset + limit);
    final hasMore = rows.length > limit;
    final slice = hasMore ? rows.sublist(0, limit) : rows;
    return PagedResult(
      items: [for (final row in slice) _historyFromRow(MapperHelpers.row(row))],
      nextOffset: hasMore ? offset + limit : null,
      hasMore: hasMore,
    );
  }

  @override
  Future<HistoryJob?> getJob(String id) async {
    final row = await client.from('jobs').select(_jobSelect).eq('id', id).maybeSingle();
    return row == null ? null : _historyFromRow(MapperHelpers.row(row));
  }

  @override
  Future<JobDetail> getJobDetail(String id) async {
    final job = await getJob(id);
    if (job == null) throw StateError('Job not found: $id');

    final historyRows = await client
        .from('job_status_history')
        .select('kind, at')
        .eq('job_id', id)
        .order('at', ascending: false);

    final linkRows = await client.from('equipment_jobs').select('equipment_id').eq('job_id', id);
    final equipmentIds = [for (final row in linkRows) MapperHelpers.uuid(row['equipment_id'])];
    final equipment = <PropertyEquipment>[];
    if (equipmentIds.isNotEmpty) {
      final equipmentRows = await client.from('equipment').select(_equipmentColumns).inFilter('id', equipmentIds);
      equipment.addAll([for (final row in equipmentRows) EquipmentMapper.fromRow(MapperHelpers.row(row))]);
    }

    final photoRows = await client
        .from('job_photos')
        .select('id, caption, created_at')
        .eq('job_id', id)
        .order('created_at', ascending: false);
    final documentRows = await client
        .from('job_documents')
        .select('id, title, signed_at, signer_name')
        .eq('job_id', id)
        .order('created_at');

    return JobDetail(
      job: job,
      statusHistory: [
        for (final row in historyRows)
          JobStatusEvent(
            at: MapperHelpers.isoTimestamp(row['at']),
            kind: EnumDb.jobActivityKindFromDb(MapperHelpers.str(row['kind'])),
          ),
      ],
      equipment: equipment,
      photos: [
        for (final row in photoRows)
          JobPhotoSummary(
            id: MapperHelpers.uuid(row['id']),
            caption: MapperHelpers.str(row['caption']),
            createdAt: MapperHelpers.isoTimestamp(row['created_at']),
          ),
      ],
      documents: [
        for (final row in documentRows)
          JobDocumentSummary(
            id: MapperHelpers.uuid(row['id']),
            title: MapperHelpers.str(row['title']),
            signed: MapperHelpers.strOrNull(row['signed_at']) != null,
            signerName: MapperHelpers.strOrNull(row['signer_name']),
          ),
      ],
    );
  }

  @override
  Future<HistoryJob> createJob({
    required String propertyId,
    required JobType type,
    required String date,
    required String startTime,
    required String endTime,
    String description = '',
    String? truckAssetId,
  }) async {
    final payload = {
      'property_id': propertyId,
      'job_number': await _nextJobNumber(),
      'type': EnumDb.jobType(type),
      'status': EnumDb.jobStatus(JobStatus.unassigned),
      'priority': EnumDb.jobPriority(JobPriority.normal),
      'scheduled_date': date,
      'start_time': startTime,
      'end_time': endTime,
      'description': description,
      if (truckAssetId != null && truckAssetId.isNotEmpty) 'truck_asset_id': truckAssetId,
    };
    final row = await client.from('jobs').insert(payload).select(_jobSelect).single();
    final job = _historyFromRow(MapperHelpers.row(row));
    await client.from('job_status_history').insert({
      'job_id': job.id,
      'kind': EnumDb.jobActivityKind(JobActivityKind.scheduled),
    });
    return job;
  }

  @override
  Future<HistoryJob> rescheduleJob({
    required String jobId,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    final row = await client
        .from('jobs')
        .update({
          'scheduled_date': date,
          'start_time': startTime,
          'end_time': endTime,
        })
        .eq('id', jobId)
        .select(_jobSelect)
        .single();
    await client.from('job_status_history').insert({
      'job_id': jobId,
      'kind': EnumDb.jobActivityKind(JobActivityKind.scheduled),
    });
    return _historyFromRow(MapperHelpers.row(row));
  }

  @override
  Future<HistoryJob> cancelJob(String jobId) async {
    final row = await client
        .from('jobs')
        .update({'status': EnumDb.jobStatus(JobStatus.cancelled)})
        .eq('id', jobId)
        .select(_jobSelect)
        .single();
    return _historyFromRow(MapperHelpers.row(row));
  }

  @override
  Future<HistoryJob> assignJob({required String jobId, String? technicianId}) async {
    final current = await client.from('jobs').select(_jobColumns).eq('id', jobId).single();
    final currentTechId = MapperHelpers.strOrNull(current['technician_id']);
    var nextStatus = EnumDb.jobStatusFromDb(MapperHelpers.str(current['status']));

    if (technicianId == null) {
      if (nextStatus != JobStatus.completed && nextStatus != JobStatus.cancelled) {
        nextStatus = JobStatus.unassigned;
      }
      await _closeActiveAssignments(jobId);
    } else {
      if (nextStatus == JobStatus.unassigned || nextStatus == JobStatus.scheduled) {
        nextStatus = JobStatus.assigned;
      }
      if (currentTechId != null && currentTechId != technicianId) {
        await _closeActiveAssignments(jobId);
      }
      final active = await client
          .from('job_assignments')
          .select('id')
          .eq('job_id', jobId)
          .eq('technician_id', technicianId)
          .isFilter('unassigned_at', null)
          .maybeSingle();
      if (active == null) {
        await client.from('job_assignments').insert({
          'job_id': jobId,
          'technician_id': technicianId,
        });
        await client.from('job_status_history').insert({
          'job_id': jobId,
          'kind': EnumDb.jobActivityKind(JobActivityKind.assigned),
        });
      }
    }

    final row = await client
        .from('jobs')
        .update({
          'technician_id': technicianId,
          'status': EnumDb.jobStatus(nextStatus),
        })
        .eq('id', jobId)
        .select(_jobSelect)
        .single();
    if (currentTechId != technicianId) {
      final reassigned = currentTechId != null && technicianId != null;
      await _audit?.record(
        action: technicianId == null
            ? AuditActions.jobUnassign
            : (reassigned ? AuditActions.jobReassign : AuditActions.jobAssign),
        entityType: 'job',
        entityId: jobId,
        metadata: AuditMetadata.jobAssignment(
          beforeTechnicianId: currentTechId,
          afterTechnicianId: technicianId,
          reassigned: reassigned,
        ),
      );
    }
    return _historyFromRow(MapperHelpers.row(row));
  }

  @override
  Future<HistoryJob> setJobTruck({required String jobId, String? truckAssetId}) async {
    final row = await client
        .from('jobs')
        .update({'truck_asset_id': truckAssetId})
        .eq('id', jobId)
        .select(_jobSelect)
        .single();
    return _historyFromRow(MapperHelpers.row(row));
  }

  Future<void> _closeActiveAssignments(String jobId) async {
    await client
        .from('job_assignments')
        .update({'unassigned_at': DateTime.now().toUtc().toIso8601String()})
        .eq('job_id', jobId)
        .isFilter('unassigned_at', null);
  }

  Future<String> _nextJobNumber() async {
    final rows = await client.from('jobs').select('job_number').order('created_at', ascending: false).limit(100);
    var max = 10000;
    for (final row in rows) {
      final parsed = int.tryParse(MapperHelpers.str(row['job_number']).replaceAll(RegExp(r'\D'), '')) ?? 0;
      if (parsed > max) max = parsed;
    }
    return 'JOB-${max + 1}';
  }

  HistoryJob _historyFromRow(Map<String, dynamic> row) {
    final tech = row['technicians'];
    var technicianName = 'Unassigned';
    if (tech is Map) {
      final name = '${MapperHelpers.str(tech['first_name'])} ${MapperHelpers.str(tech['last_name'])}'.trim();
      if (name.isNotEmpty) technicianName = name;
    }
    return JobMapper.historyFromRow(row, technicianName: technicianName);
  }

  PostgrestFilterBuilder<PostgrestList> _jobQuery(String? search) {
    final base = client.from('jobs').select(_jobSelect);
    final needle = search?.trim();
    if (needle == null || needle.isEmpty) return base;
    final pattern = '%$needle%';
    return base.or('job_number.ilike.$pattern,description.ilike.$pattern');
  }
}

class SupabaseTechnicianRepository implements TechnicianRepository {
  SupabaseTechnicianRepository(this.client);

  final SupabaseClient client;

  static const _columns =
      'id, profile_id, first_name, last_name, status, latitude, longitude, last_address, last_updated, phone, account_enabled, profiles(email)';

  @override
  Future<List<OfficeTechnician>> getTechnicians() async {
    final rows = await client.from('technicians').select(_columns).order('last_name');
    return [for (final row in rows) _fromRow(MapperHelpers.row(row))];
  }

  @override
  Future<OfficeTechnician?> getTechnician(String id) async {
    final row = await client.from('technicians').select(_columns).eq('id', id).maybeSingle();
    return row == null ? null : _fromRow(MapperHelpers.row(row));
  }

  @override
  Future<List<TechnicianActivity>> getTechnicianActivity(String technicianId) async {
    final rows = await client
        .from('technician_activities')
        .select('at, title, detail')
        .eq('technician_id', technicianId)
        .order('at', ascending: false)
        .limit(40);
    return [
      for (final row in rows)
        TechnicianActivity(
          at: MapperHelpers.isoTimestamp(row['at']),
          title: MapperHelpers.str(row['title']),
          detail: MapperHelpers.str(row['detail']),
        ),
    ];
  }

  @override
  Future<TechnicianDetail> getTechnicianDetail(String id) async {
    final technician = await getTechnician(id);
    if (technician == null) throw StateError('Technician not found: $id');
    final activity = await getTechnicianActivity(id);
    const jobSelect =
        'id, property_id, job_number, type, status, priority, scheduled_date, start_time, end_time, technician_id, description, notes, parts_used, technicians(first_name, last_name)';
    final jobRows = await client
        .from('jobs')
        .select(jobSelect)
        .eq('technician_id', id)
        .order('scheduled_date', ascending: false)
        .limit(12);
    final recentJobs = [for (final row in jobRows) _jobFromRow(MapperHelpers.row(row))];

    String? assignedAssetLabel;
    final assetRow = await client
        .from('fleet_assets')
        .select('label, identifier')
        .eq('current_technician_id', id)
        .eq('is_active', true)
        .maybeSingle();
    if (assetRow != null) {
      final label = MapperHelpers.str(assetRow['label']);
      final identifier = MapperHelpers.str(assetRow['identifier']);
      assignedAssetLabel = identifier.isEmpty ? label : '$label · $identifier';
    }

    return TechnicianDetail(
      technician: technician,
      activity: activity,
      recentJobs: recentJobs,
      assignedAssetLabel: assignedAssetLabel,
    );
  }

  @override
  Future<OfficeTechnician> saveTechnician({
    String? id,
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    String? profileId,
    TechnicianStatus status = TechnicianStatus.available,
  }) async {
    final payload = {
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'status': EnumDb.technicianStatus(status),
      if (profileId != null && profileId.isNotEmpty) 'profile_id': profileId,
    };

    if (id == null || id.isEmpty) {
      final row = await client.from('technicians').insert(payload).select(_columns).single();
      final saved = _fromRow(MapperHelpers.row(row));
      if (email.isNotEmpty && saved.profileId != null) {
        await client.from('profiles').update({'email': email}).eq('id', saved.profileId!);
      }
      return saved.copyWith(email: email);
    }

    final row = await client.from('technicians').update(payload).eq('id', id).select(_columns).single();
    final saved = _fromRow(MapperHelpers.row(row));
    if (email.isNotEmpty && saved.profileId != null) {
      await client.from('profiles').update({'email': email}).eq('id', saved.profileId!);
    }
    return saved.copyWith(email: email);
  }

  @override
  Future<OfficeTechnician> setAccountEnabled({required String id, required bool enabled}) async {
    final row = await client
        .from('technicians')
        .update({'account_enabled': enabled})
        .eq('id', id)
        .select(_columns)
        .single();
    return _fromRow(MapperHelpers.row(row));
  }

  OfficeTechnician _fromRow(Map<String, dynamic> row) {
    final profile = row['profiles'];
    if (profile is Map<String, dynamic>) {
      row = {...row, 'profile_email': profile['email']};
    }
    return TechnicianMapper.fromRow(row);
  }

  HistoryJob _jobFromRow(Map<String, dynamic> row) {
    final tech = row['technicians'];
    var technicianName = 'Unassigned';
    if (tech is Map) {
      final name = '${MapperHelpers.str(tech['first_name'])} ${MapperHelpers.str(tech['last_name'])}'.trim();
      if (name.isNotEmpty) technicianName = name;
    }
    return JobMapper.historyFromRow(row, technicianName: technicianName);
  }
}

class SupabaseBillingRepository implements BillingRepository {
  SupabaseBillingRepository(this.client, {SupabaseAuditLog? audit}) : _audit = audit;

  final SupabaseClient client;
  final SupabaseAuditLog? _audit;

  static const _estimateSelect =
      'id, number, status, issued_on, property_id, job_id, notes, estimate_line_items(description, quantity, unit_price, sort_order)';
  static const _invoiceSelect =
      'id, number, status, issued_on, due_on, property_id, job_id, estimate_id, notes, tax_rate_pct, invoice_line_items(description, quantity, unit_price, sort_order)';

  @override
  Future<List<OfficeEstimate>> getEstimates({EstimateStatus? status}) async {
    var query = client.from('estimates').select(_estimateSelect);
    if (status != null) {
      query = query.eq('status', EnumDb.estimateStatus(status));
    }
    final rows = await query.order('issued_on', ascending: false);
    return [for (final row in rows) _estimateFromRow(MapperHelpers.row(row))];
  }

  @override
  Future<PagedResult<OfficeEstimate>> getEstimatesPage({
    int offset = 0,
    int limit = ListQuery.defaultLimit,
    String? search,
    EstimateStatus? status,
  }) async {
    var query = _estimateQuery(search);
    if (status != null) {
      query = query.eq('status', EnumDb.estimateStatus(status));
    }
    final rows = await query.order('issued_on', ascending: false).range(offset, offset + limit);
    final hasMore = rows.length > limit;
    final slice = hasMore ? rows.sublist(0, limit) : rows;
    return PagedResult(
      items: [for (final row in slice) _estimateFromRow(MapperHelpers.row(row))],
      nextOffset: hasMore ? offset + limit : null,
      hasMore: hasMore,
    );
  }

  @override
  Future<OfficeEstimate?> getEstimate(String id) async {
    if (!MapperHelpers.isUuid(id)) return null;
    final row = await client.from('estimates').select(_estimateSelect).eq('id', id).maybeSingle();
    return row == null ? null : _estimateFromRow(MapperHelpers.row(row));
  }

  @override
  Future<OfficeEstimate> saveEstimate(OfficeEstimate estimate) async {
    final existing = MapperHelpers.isUuid(estimate.id) ? await getEstimate(estimate.id) : null;
    final payload = BillingMapper.estimateToRow(estimate);
    late final String estimateId;
    if (existing != null) {
      final row = await client.from('estimates').update(payload).eq('id', estimate.id).select(_estimateSelect).single();
      estimateId = estimate.id;
      await client.from('estimate_line_items').delete().eq('estimate_id', estimate.id);
      if (estimate.items.isEmpty) {
        final saved = await getEstimate(estimateId);
        return saved ?? _estimateFromRow(MapperHelpers.row(row));
      }
    } else {
      payload.remove('id');
      final row = await client.from('estimates').insert(payload).select(_estimateSelect).single();
      estimateId = MapperHelpers.uuid(row['id']);
    }
    if (estimate.items.isNotEmpty) {
      await client.from('estimate_line_items').insert([
        for (var i = 0; i < estimate.items.length; i++)
          {
            'estimate_id': estimateId,
            ...BillingMapper.lineItemToRow(estimate.items[i], sortOrder: i),
          },
      ]);
    }
    final saved = await getEstimate(estimateId);
    if (saved == null) throw StateError('Failed to save estimate');
    return saved;
  }

  @override
  Future<OfficeEstimate> updateEstimateStatus(String id, EstimateStatus status) async {
    final row = await client
        .from('estimates')
        .update({'status': EnumDb.estimateStatus(status)})
        .eq('id', id)
        .select(_estimateSelect)
        .single();
    return _estimateFromRow(MapperHelpers.row(row));
  }

  @override
  Future<OfficeInvoice?> getInvoiceForEstimate(String estimateId) async {
    if (!MapperHelpers.isUuid(estimateId)) return null;
    final row = await client.from('invoices').select(_invoiceSelect).eq('estimate_id', estimateId).maybeSingle();
    return row == null ? null : _invoiceFromRow(MapperHelpers.row(row));
  }

  @override
  Future<OfficeInvoice> convertEstimateToInvoice(String estimateId) async {
    final existing = await getInvoiceForEstimate(estimateId);
    if (existing != null) return existing;
    final estimate = await getEstimate(estimateId);
    if (estimate == null) throw StateError('Estimate not found: $estimateId');
    final due = DateTime.parse('${estimate.date}T00:00:00').add(const Duration(days: 14));
    final invoicePayload = {
      'number': 'INV-${estimate.number.replaceFirst('EST-', '')}',
      'status': EnumDb.invoiceStatus(InvoiceStatus.draft),
      'issued_on': estimate.date,
      'due_on': due.toIso8601String().split('T').first,
      'property_id': estimate.propertyId,
      'job_id': estimate.jobId,
      'estimate_id': estimate.id,
      'notes': estimate.notes,
    };
    final row = MapperHelpers.row(
      await client.from('invoices').insert(invoicePayload).select(_invoiceSelect).single(),
    );
    final invoiceId = MapperHelpers.uuid(row['id']);
    if (estimate.items.isNotEmpty) {
      await client.from('invoice_line_items').insert([
        for (var i = 0; i < estimate.items.length; i++)
          {
            'invoice_id': invoiceId,
            ...BillingMapper.lineItemToRow(estimate.items[i], sortOrder: i),
          },
      ]);
    }
    final saved = await getInvoice(invoiceId);
    return saved ?? _invoiceFromRow(row);
  }

  @override
  Future<List<OfficeInvoice>> getInvoices({InvoiceStatus? status}) async {
    final rows = await _invoiceQuery(null, status: status)
        .order('issued_on', ascending: false);
    return [for (final row in rows) InvoicePolicy.withEffectiveStatus(_invoiceFromRow(MapperHelpers.row(row)))];
  }

  @override
  Future<PagedResult<OfficeInvoice>> getInvoicesPage({
    int offset = 0,
    int limit = ListQuery.defaultLimit,
    String? search,
    InvoiceStatus? status,
    bool overdueOnly = false,
    double? minAmount,
  }) async {
    final rows = await _invoiceQuery(search, status: status)
        .order('issued_on', ascending: false)
        .range(offset, offset + limit);
    final hasMore = rows.length > limit;
    final slice = hasMore ? rows.sublist(0, limit) : rows;
    var items = [for (final row in slice) InvoicePolicy.withEffectiveStatus(_invoiceFromRow(MapperHelpers.row(row)))];
    if (overdueOnly) {
      items = items.where((invoice) => invoice.status == InvoiceStatus.overdue).toList();
    }
    if (minAmount != null) {
      items = items.where((invoice) => invoice.amount >= minAmount).toList();
    }
    return PagedResult(
      items: items,
      nextOffset: hasMore ? offset + limit : null,
      hasMore: hasMore,
    );
  }

  @override
  Future<OfficeInvoice?> getInvoice(String id) async {
    if (!MapperHelpers.isUuid(id)) return null;
    final row = await client.from('invoices').select(_invoiceSelect).eq('id', id).maybeSingle();
    if (row == null) return null;
    return InvoicePolicy.withEffectiveStatus(_invoiceFromRow(MapperHelpers.row(row)));
  }

  @override
  Future<OfficeInvoice> saveInvoice(OfficeInvoice invoice) async {
    final existing = MapperHelpers.isUuid(invoice.id) ? await getInvoice(invoice.id) : null;
    final payload = BillingMapper.invoiceToRow(invoice);
    late final String invoiceId;
    if (existing != null) {
      await client.from('invoices').update(payload).eq('id', invoice.id);
      invoiceId = invoice.id;
      await client.from('invoice_line_items').delete().eq('invoice_id', invoice.id);
    } else {
      payload.remove('id');
      final row = await client.from('invoices').insert(payload).select(_invoiceSelect).single();
      invoiceId = MapperHelpers.uuid(row['id']);
    }
    if (invoice.items.isNotEmpty) {
      await client.from('invoice_line_items').insert([
        for (var i = 0; i < invoice.items.length; i++)
          {
            'invoice_id': invoiceId,
            ...BillingMapper.lineItemToRow(invoice.items[i], sortOrder: i),
          },
      ]);
    }
    final saved = await getInvoice(invoiceId);
    if (saved == null) throw StateError('Failed to save invoice');
    return saved;
  }

  @override
  Future<OfficeInvoice> updateInvoiceStatus(String id, InvoiceStatus status) async {
    final current = await getInvoice(id);
    if (current == null) throw StateError('Invoice not found: $id');
    final before = current.status;
    final row = await client
        .from('invoices')
        .update({'status': EnumDb.invoiceStatus(status)})
        .eq('id', id)
        .select(_invoiceSelect)
        .single();
    final saved = InvoicePolicy.withEffectiveStatus(_invoiceFromRow(MapperHelpers.row(row)));
    if (before != status) {
      await _audit?.record(
        action: status == InvoiceStatus.cancelled ? AuditActions.invoiceVoid : AuditActions.invoiceStatus,
        entityType: 'invoice',
        entityId: id,
        metadata: AuditMetadata.invoiceStatusChange(
          invoiceId: id,
          number: saved.number,
          beforeStatus: before.name,
          afterStatus: status.name,
          amount: saved.amount,
        ),
      );
    }
    return saved;
  }

  OfficeEstimate _estimateFromRow(Map<String, dynamic> row) {
    return BillingMapper.estimateFromRow(
      row,
      items: BillingMapper.lineItemsFromNested(row['estimate_line_items']),
    );
  }

  OfficeInvoice _invoiceFromRow(Map<String, dynamic> row) {
    return BillingMapper.invoiceFromRow(
      row,
      items: BillingMapper.lineItemsFromNested(row['invoice_line_items']),
    );
  }

  PostgrestFilterBuilder<PostgrestList> _estimateQuery(String? search) {
    final base = client.from('estimates').select(_estimateSelect);
    final needle = search?.trim();
    if (needle == null || needle.isEmpty) return base;
    final pattern = '%$needle%';
    return base.or('number.ilike.$pattern,notes.ilike.$pattern');
  }

  PostgrestFilterBuilder<PostgrestList> _invoiceQuery(String? search, {InvoiceStatus? status}) {
    var base = client.from('invoices').select(_invoiceSelect);
    if (status != null) {
      base = base.eq('status', EnumDb.invoiceStatus(status));
    }
    final needle = search?.trim();
    if (needle == null || needle.isEmpty) return base;
    final pattern = '%$needle%';
    return base.or('number.ilike.$pattern,notes.ilike.$pattern');
  }

  static const _paymentColumns =
      'id, invoice_id, job_id, property_id, amount, currency, status, provider, '
      'provider_payment_id, provider_checkout_url, paid_at, failure_reason, created_at';

  @override
  Future<List<OfficePayment>> getPayments({String? invoiceId}) async {
    var query = client.from('payments').select(_paymentColumns);
    if (invoiceId != null && MapperHelpers.isUuid(invoiceId)) {
      query = query.eq('invoice_id', invoiceId);
    }
    final rows = await query.order('created_at', ascending: false);
    return [for (final row in rows) PaymentMapper.fromRow(MapperHelpers.row(row))];
  }

  @override
  Future<OfficePayment?> paymentByProviderId(String provider, String providerPaymentId) async {
    final row = await client
        .from('payments')
        .select(_paymentColumns)
        .eq('provider', provider)
        .eq('provider_payment_id', providerPaymentId)
        .maybeSingle();
    return row == null ? null : PaymentMapper.fromRow(MapperHelpers.row(row));
  }

  @override
  Future<OfficePayment> savePayment(OfficePayment payment) async {
    final payload = PaymentMapper.toRow(payment);
    final isNew = !MapperHelpers.isUuid(payment.id);
    if (isNew) {
      payload.remove('id');
      final row = await client.from('payments').insert(payload).select(_paymentColumns).single();
      return PaymentMapper.fromRow(MapperHelpers.row(row));
    }
    final row = await client
        .from('payments')
        .update(payload)
        .eq('id', payment.id)
        .select(_paymentColumns)
        .single();
    return PaymentMapper.fromRow(MapperHelpers.row(row));
  }
}

class SupabaseCommunicationRepository implements CommunicationRepository {
  SupabaseCommunicationRepository(this.client);

  final SupabaseClient client;

  static const _columns =
      'id, at, channel, direction, entity_type, entity_id, entity_label, subject, body, provider, provider_message_id, template_kind, delivery_status, to_address, metadata';

  @override
  Future<List<OfficeMessage>> getMessages({
    CommunicationEntityType? entityType,
    String? entityId,
    List<MessageEntityRef>? entities,
    MessageHistoryFilter? filter,
    int limit = 200,
  }) async {
    var query = client.from('messages').select(_columns);
    query = _applyScope(query, entityType: entityType, entityId: entityId, entities: entities);
    query = _applyFilter(query, filter);
    final rows = await query.order('at', ascending: false).limit(limit);
    return [for (final row in rows) MessageMapper.fromRow(MapperHelpers.row(row))];
  }

  @override
  Future<PagedResult<OfficeMessage>> getMessagesPage({
    int offset = 0,
    int limit = ListQuery.defaultLimit,
    String? search,
    CommunicationEntityType? entityType,
    String? entityId,
    List<MessageEntityRef>? entities,
    MessageHistoryFilter? filter,
  }) async {
    var query = client.from('messages').select(_columns);
    query = _applyScope(query, entityType: entityType, entityId: entityId, entities: entities);
    query = _applyFilter(query, filter);
    final needle = search?.trim();
    if (needle != null && needle.isNotEmpty) {
      final pattern = '%$needle%';
      query = query.or('entity_label.ilike.$pattern,body.ilike.$pattern,subject.ilike.$pattern,to_address.ilike.$pattern');
    }
    final rows = await query.order('at', ascending: false).range(offset, offset + limit);
    final hasMore = rows.length > limit;
    final slice = hasMore ? rows.sublist(0, limit) : rows;
    return PagedResult(
      items: [for (final row in slice) MessageMapper.fromRow(MapperHelpers.row(row))],
      nextOffset: hasMore ? offset + limit : null,
      hasMore: hasMore,
    );
  }

  dynamic _applyScope(
    dynamic query, {
    CommunicationEntityType? entityType,
    String? entityId,
    List<MessageEntityRef>? entities,
  }) {
    if (entities != null && entities.isNotEmpty) {
      final parts = <String>[
        for (final ref in entities)
          'and(entity_type.eq.${EnumDb.communicationEntityType(ref.entityType)},entity_id.eq.${ref.entityId})',
      ];
      return query.or(parts.join(','));
    }
    if (entityType != null) {
      query = query.eq('entity_type', EnumDb.communicationEntityType(entityType));
    }
    if (entityId != null && MapperHelpers.isUuid(entityId)) {
      query = query.eq('entity_id', entityId);
    }
    return query;
  }

  dynamic _applyFilter(dynamic query, MessageHistoryFilter? filter) {
    if (filter == null) return query;
    if (filter.channel != null) {
      query = query.eq('channel', EnumDb.communicationChannel(filter.channel!));
    }
    if (filter.from != null) {
      query = query.gte('at', filter.from!.toUtc().toIso8601String());
    }
    if (filter.to != null) {
      query = query.lte('at', filter.to!.toUtc().toIso8601String());
    }
    return query;
  }

  @override
  Future<OfficeMessage> save(OfficeMessage message) async {
    final payload = MessageMapper.toInsertRow(message);
    if (MapperHelpers.isUuid(message.id)) {
      final row = await client
          .from('messages')
          .update(payload)
          .eq('id', message.id)
          .select(_columns)
          .single();
      return MessageMapper.fromRow(MapperHelpers.row(row));
    }
    final row = await client.from('messages').insert(payload).select(_columns).single();
    return MessageMapper.fromRow(MapperHelpers.row(row));
  }

  @override
  Future<List<MessageWebhookFailure>> getWebhookFailures({int limit = 10}) async {
    final rows = await client
        .from('message_webhook_events')
        .select('id, received_at, provider, event_type, external_message_id, error, signature_valid')
        .order('received_at', ascending: false)
        .limit(limit * 5);

    final failures = <MessageWebhookFailure>[];
    for (final row in rows) {
      final signatureValid = row['signature_valid'] == true;
      final error = MapperHelpers.str(row['error']);
      if (signatureValid && (error.isEmpty || error == 'duplicate_skipped')) continue;
      failures.add(
        MessageWebhookFailure(
          id: MapperHelpers.uuid(row['id']),
          receivedAt: DateTime.parse(MapperHelpers.isoTimestamp(row['received_at'])),
          provider: MapperHelpers.str(row['provider']),
          eventType: MapperHelpers.str(row['event_type']),
          error: error.isEmpty ? 'invalid signature' : error,
          externalMessageId: MapperHelpers.strOrNull(row['external_message_id']),
        ),
      );
      if (failures.length >= limit) break;
    }
    return failures;
  }
}

class SupabaseInventoryRepository implements InventoryRepository {
  SupabaseInventoryRepository(this.client);

  final SupabaseClient client;

  @override
  Future<List<InventoryItem>> getItems() async {
    final rows = await client.from('inventory_items').select('id, sku, name, category, unit, min_qty').order('name');
    return [for (final row in rows) InventoryMapper.itemFromRow(MapperHelpers.row(row))];
  }

  @override
  Future<PagedResult<InventoryItem>> getItemsPage({
    int offset = 0,
    int limit = ListQuery.defaultLimit,
    String? search,
  }) async {
    final rows = await _itemQuery(search).order('name').range(offset, offset + limit);
    final hasMore = rows.length > limit;
    final slice = hasMore ? rows.sublist(0, limit) : rows;
    return PagedResult(
      items: [for (final row in slice) InventoryMapper.itemFromRow(MapperHelpers.row(row))],
      nextOffset: hasMore ? offset + limit : null,
      hasMore: hasMore,
    );
  }

  @override
  Future<List<InventoryLocation>> getLocations() async {
    final rows = await client.from('inventory_locations').select('id, kind, name').order('name');
    return [for (final row in rows) InventoryMapper.locationFromRow(MapperHelpers.row(row))];
  }

  static const _stockColumns = 'location_id, item_id, quantity';
  static const _movementColumns =
      'id, at, item_id, kind, quantity, from_location_id, to_location_id, reason, job_id';

  @override
  Future<List<LocationStock>> getStocks() async {
    final rows = await client.from('location_stock').select(_stockColumns);
    return [for (final row in rows) InventoryMapper.stockFromRow(MapperHelpers.row(row))];
  }

  @override
  Future<List<StockMovement>> getMovements({String? itemId}) async {
    var query = client.from('stock_movements').select(_movementColumns);
    if (itemId != null && MapperHelpers.isUuid(itemId)) {
      query = query.eq('item_id', itemId);
    }
    final rows = await query.order('at', ascending: false).limit(500);
    return [for (final row in rows) InventoryMapper.movementFromRow(MapperHelpers.row(row))];
  }

  @override
  Future<InventoryItem> saveItem(InventoryItem item) async {
    final payload = InventoryMapper.itemToRow(item);
    final isNew = !MapperHelpers.isUuid(item.id);
    if (isNew) {
      payload.remove('id');
      final row = await client.from('inventory_items').insert(payload).select('id, sku, name, category, unit, min_qty').single();
      return InventoryMapper.itemFromRow(MapperHelpers.row(row));
    }
    final row = await client
        .from('inventory_items')
        .update(payload)
        .eq('id', item.id)
        .select('id, sku, name, category, unit, min_qty')
        .single();
    return InventoryMapper.itemFromRow(MapperHelpers.row(row));
  }

  @override
  Future<InventoryLocation> saveLocation(InventoryLocation location) async {
    final payload = InventoryMapper.locationToRow(location);
    final isNew = !MapperHelpers.isUuid(location.id);
    if (isNew) {
      payload.remove('id');
      final row = await client.from('inventory_locations').insert(payload).select('id, kind, name').single();
      return InventoryMapper.locationFromRow(MapperHelpers.row(row));
    }
    final row = await client
        .from('inventory_locations')
        .update(payload)
        .eq('id', location.id)
        .select('id, kind, name')
        .single();
    return InventoryMapper.locationFromRow(MapperHelpers.row(row));
  }

  @override
  Future<void> saveStock(LocationStock stock) async {}

  @override
  Future<void> saveMovement(StockMovement movement) async {
    if (!MapperHelpers.isUuid(movement.itemId) ||
        !MapperHelpers.isUuid(movement.fromLocationId) ||
        !MapperHelpers.isUuid(movement.toLocationId)) {
      throw StateError('Supabase inventory movements require UUID item and location ids');
    }

    if (movement.kind == StockMovementKind.issue) {
      final row = await client
          .from('location_stock')
          .select('quantity')
          .eq('location_id', movement.fromLocationId)
          .eq('item_id', movement.itemId)
          .maybeSingle();
      final current = MapperHelpers.intOrNull(row?['quantity']) ?? 0;
      if (current < movement.quantity) {
        throw StateError('insufficient stock at source location');
      }
      await client
          .from('location_stock')
          .update({'quantity': current - movement.quantity})
          .eq('location_id', movement.fromLocationId)
          .eq('item_id', movement.itemId);
      await client.from('stock_movements').insert(InventoryMapper.movementToRow(movement));
      return;
    }

    await client.rpc('apply_stock_movement', params: InventoryMapper.movementToRpc(movement));
  }

  PostgrestFilterBuilder<PostgrestList> _itemQuery(String? search) {
    final base = client.from('inventory_items').select('id, sku, name, category, unit, min_qty');
    final needle = search?.trim();
    if (needle == null || needle.isEmpty) return base;
    final pattern = '%$needle%';
    return base.or('sku.ilike.$pattern,name.ilike.$pattern,category.ilike.$pattern');
  }
}

class SupabaseReportsRepository implements ReportsRepository {
  SupabaseReportsRepository(this.client);

  final SupabaseClient client;

  static const _invoiceSelect =
      'id, number, status, issued_on, due_on, property_id, job_id, estimate_id, notes, tax_rate_pct, invoice_line_items(description, quantity, unit_price, sort_order)';

  @override
  Future<DashboardSnapshot> loadDashboardMetrics({bool includeFinancial = true}) async {
    final today = isoDate(DateTime.now());

    final todayRows = await client.from('jobs').select('id').eq('scheduled_date', today);
    final unassignedRows = await client.from('jobs').select('id').eq('status', 'unassigned');
    final activeTechRows =
        await client.from('technicians').select('id').neq('status', 'off_duty');

    final statusRows = await client.from('jobs').select('status');
    var jobsCompleted = 0;
    var jobsOpen = 0;
    for (final row in statusRows) {
      final status = MapperHelpers.str(row['status']);
      if (status == 'completed') {
        jobsCompleted += 1;
      } else if (status != 'cancelled') {
        jobsOpen += 1;
      }
    }

    var openEstimates = 0;
    var overdueInvoiceCount = 0;
    var overdueInvoiceTotal = 0.0;
    var hasFinancialData = false;

    if (includeFinancial) {
      final estimateRows = await client
          .from('estimates')
          .select('id, status')
          .inFilter('status', ['draft', 'sent']);
      openEstimates = estimateRows.length;

      final invoiceRows = await client.from('invoices').select(_invoiceSelect).eq('status', 'overdue');
      overdueInvoiceCount = invoiceRows.length;
      for (final row in invoiceRows) {
        final invoice = BillingMapper.invoiceFromRow(
          MapperHelpers.row(row),
          items: BillingMapper.lineItemsFromNested(row['invoice_line_items']),
        );
        overdueInvoiceTotal += invoice.amount;
      }

      if (openEstimates > 0 || overdueInvoiceCount > 0) {
        hasFinancialData = true;
      } else {
        final anyFinancial = await client.from('invoices').select('id').limit(1);
        final anyEstimates = await client.from('estimates').select('id').limit(1);
        hasFinancialData = anyFinancial.isNotEmpty || anyEstimates.isNotEmpty;
      }
    }

    final recentActivity = await _loadRecentActivity();

    return DashboardSnapshot(
      todaysJobs: todayRows.length,
      unassignedJobs: unassignedRows.length,
      activeTechnicians: activeTechRows.length,
      openEstimates: openEstimates,
      overdueInvoiceCount: overdueInvoiceCount,
      overdueInvoiceTotal: overdueInvoiceTotal,
      jobsCompleted: jobsCompleted,
      jobsOpen: jobsOpen,
      jobsTotal: statusRows.length,
      recentActivity: recentActivity,
      hasOperationalData: statusRows.isNotEmpty || activeTechRows.isNotEmpty,
      hasFinancialData: hasFinancialData,
    );
  }

  Future<List<DashboardActivityItem>> _loadRecentActivity() async {
    final auditRows = await client
        .from('audit_log')
        .select('at, action, entity_type, entity_id, metadata')
        .order('at', ascending: false)
        .limit(8);

    if (auditRows.isNotEmpty) {
      return [
        for (final row in auditRows)
          DashboardActivityItem(
            at: MapperHelpers.isoTimestamp(row['at']),
            title: _auditTitle(MapperHelpers.str(row['action'])),
            detail: '${MapperHelpers.str(row['entity_type'])} · ${MapperHelpers.str(row['entity_id'])}',
            entityType: MapperHelpers.strOrNull(row['entity_type']),
            entityId: MapperHelpers.strOrNull(row['entity_id']),
          ),
      ];
    }

    final timelineRows = await client
        .from('property_timeline_events')
        .select('occurred_on, title, detail, property_id')
        .order('occurred_on', ascending: false)
        .limit(8);

    return [
      for (final row in timelineRows)
        DashboardActivityItem(
          at: MapperHelpers.dateOnly(row['occurred_on']),
          title: MapperHelpers.str(row['title']),
          detail: MapperHelpers.str(row['detail']),
          entityType: 'property',
          entityId: MapperHelpers.strOrNull(row['property_id']),
        ),
    ];
  }

  @override
  Future<OperationalReportMetrics> loadOperationalMetrics() async {
    final jobRows = await client
        .from('jobs')
        .select(
          'id, type, status, scheduled_date, start_time, technician_id, technicians(id, first_name, last_name)',
        )
        .order('scheduled_date', ascending: false);

    if (jobRows.isEmpty) {
      final technicians = await _loadReportTechnicians();
      return OperationalMetricsCalculator.compute(jobs: const [], technicians: technicians);
    }

    final jobIds = [for (final row in jobRows) MapperHelpers.uuid(row['id'])];
    final historyByJob = await _historyForReportJobs(jobIds);
    final technicians = await _loadReportTechnicians();

    final inputs = [
      for (final row in jobRows)
        JobReportInput(
          id: MapperHelpers.uuid(row['id']),
          type: EnumDb.jobTypeFromDb(MapperHelpers.str(row['type'])),
          status: EnumDb.jobStatusFromDb(MapperHelpers.str(row['status'])),
          technicianId: MapperHelpers.strOrNull(row['technician_id']),
          technicianName: _reportTechnicianName(row['technicians']),
          scheduledDate: MapperHelpers.dateOnly(row['scheduled_date']),
          startTime: MapperHelpers.timeHm(row['start_time']),
          history: historyByJob[MapperHelpers.uuid(row['id'])] ?? const [],
        ),
    ];

    return OperationalMetricsCalculator.compute(jobs: inputs, technicians: technicians);
  }

  Future<List<OfficeTechnician>> _loadReportTechnicians() async {
    final rows = await client
        .from('technicians')
        .select('id, first_name, last_name, status, latitude, longitude, last_address, last_updated')
        .order('last_name');
    return [
      for (final row in rows)
        OfficeTechnician(
          id: MapperHelpers.uuid(row['id']),
          firstName: MapperHelpers.str(row['first_name']),
          lastName: MapperHelpers.str(row['last_name']),
          status: EnumDb.technicianStatusFromDb(MapperHelpers.str(row['status'])),
          latitude: MapperHelpers.dbl(row['latitude']),
          longitude: MapperHelpers.dbl(row['longitude']),
          lastAddress: MapperHelpers.str(row['last_address']),
          lastUpdated: MapperHelpers.isoTimestamp(row['last_updated']),
        ),
    ];
  }

  Future<Map<String, List<JobStatusEvent>>> _historyForReportJobs(List<String> jobIds) async {
    if (jobIds.isEmpty) return {};
    final rows = await client
        .from('job_status_history')
        .select('job_id, kind, at')
        .inFilter('job_id', jobIds)
        .order('at', ascending: true);
    final map = <String, List<JobStatusEvent>>{};
    for (final row in rows) {
      final jobId = MapperHelpers.uuid(row['job_id']);
      map.putIfAbsent(jobId, () => []).add(
            JobStatusEvent(
              at: MapperHelpers.isoTimestamp(row['at']),
              kind: EnumDb.jobActivityKindFromDb(MapperHelpers.str(row['kind'])),
            ),
          );
    }
    return map;
  }

  String _reportTechnicianName(dynamic technician) {
    if (technician is! Map) return 'Unassigned';
    final first = MapperHelpers.str(technician['first_name']);
    final last = MapperHelpers.str(technician['last_name']);
    final name = '$first $last'.trim();
    return name.isEmpty ? 'Unassigned' : name;
  }

  String _auditTitle(String action) {
    return action
        .replaceAll('_', ' ')
        .split(' ')
        .map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class SupabaseFleetRepository implements FleetRepository {
  SupabaseFleetRepository(this.client);

  final SupabaseClient client;

  static const _assetColumns =
      'id, kind, label, identifier, inventory_location_id, current_technician_id, is_active';
  static const _assignmentColumns =
      'id, fleet_asset_id, technician_id, assigned_at, unassigned_at, notes';

  @override
  Future<List<FleetAsset>> getAssets() async {
    final rows = await client.from('fleet_assets').select(_assetColumns).order('label');
    return [for (final row in rows) FleetMapper.assetFromRow(MapperHelpers.row(row))];
  }

  @override
  Future<List<FleetAssignment>> getAssignmentHistory(String fleetAssetId) async {
    if (!MapperHelpers.isUuid(fleetAssetId)) return const [];
    final rows = await client
        .from('fleet_assignments')
        .select(_assignmentColumns)
        .eq('fleet_asset_id', fleetAssetId)
        .order('assigned_at', ascending: false);
    return [for (final row in rows) FleetMapper.assignmentFromRow(MapperHelpers.row(row))];
  }

  @override
  Future<FleetAsset> saveAsset(FleetAsset asset) async {
    final payload = Map<String, dynamic>.from(FleetMapper.assetToRow(asset));
    final isNew = !MapperHelpers.isUuid(asset.id);
    if (isNew) payload.remove('id');

    final Map<String, dynamic> row;
    if (isNew) {
      row = await client.from('fleet_assets').insert(payload).select(_assetColumns).single();
    } else {
      row = await client
          .from('fleet_assets')
          .update(payload)
          .eq('id', asset.id)
          .select(_assetColumns)
          .single();
    }
    return FleetMapper.assetFromRow(MapperHelpers.row(row));
  }

  @override
  Future<FleetAsset> assignAsset({
    required String fleetAssetId,
    required String technicianId,
    String notes = '',
  }) async {
    if (!MapperHelpers.isUuid(fleetAssetId) || !MapperHelpers.isUuid(technicianId)) {
      throw StateError('Fleet assignment requires UUID fleet asset and technician ids');
    }
    await client.rpc('assign_fleet_asset', params: {
      'p_fleet_asset_id': fleetAssetId,
      'p_technician_id': technicianId,
      'p_notes': notes,
    });
    final row = await client.from('fleet_assets').select(_assetColumns).eq('id', fleetAssetId).single();
    return FleetMapper.assetFromRow(MapperHelpers.row(row));
  }

  @override
  Future<FleetAsset> unassignAsset({required String fleetAssetId, String notes = ''}) async {
    if (!MapperHelpers.isUuid(fleetAssetId)) {
      throw StateError('Fleet unassign requires UUID fleet asset id');
    }
    await client.rpc('unassign_fleet_asset', params: {
      'p_fleet_asset_id': fleetAssetId,
      'p_notes': notes,
    });
    final row = await client.from('fleet_assets').select(_assetColumns).eq('id', fleetAssetId).single();
    return FleetMapper.assetFromRow(MapperHelpers.row(row));
  }
}

class SupabaseMaintenanceAgreementRepository implements MaintenanceAgreementRepository {
  SupabaseMaintenanceAgreementRepository(this.client);

  final SupabaseClient client;

  static const _columns =
      'id, customer_id, property_id, title, status, frequency, start_on, end_on, next_service_on, renewal_reminder_on, notes';

  @override
  Future<List<MaintenanceAgreement>> getAgreements() async {
    final rows = await client.from('maintenance_agreements').select(_columns).order('renewal_reminder_on');
    final pricing = await _loadPricingMap();
    return [
      for (final row in rows)
        MaintenanceAgreementMapper.fromRow(
          MapperHelpers.row(row),
          annualAmount: pricing[MapperHelpers.uuid(row['id'])],
        ),
    ];
  }

  @override
  Future<MaintenanceAgreement?> getAgreement(String id) async {
    if (!MapperHelpers.isUuid(id)) return null;
    final row = await client.from('maintenance_agreements').select(_columns).eq('id', id).maybeSingle();
    if (row == null) return null;
    final pricing = await _loadPricingMap(agreementId: id);
    return MaintenanceAgreementMapper.fromRow(MapperHelpers.row(row), annualAmount: pricing[id]);
  }

  @override
  Future<MaintenanceAgreement> saveAgreement(
    MaintenanceAgreement agreement, {
    double? annualAmount,
  }) async {
    final payload = Map<String, dynamic>.from(MaintenanceAgreementMapper.toRow(agreement));
    final isNew = agreement.id.isEmpty || !MapperHelpers.isUuid(agreement.id);
    if (isNew) {
      payload.remove('id');
    }

    final Map<String, dynamic> row;
    if (isNew) {
      row = await client.from('maintenance_agreements').insert(payload).select(_columns).single();
    } else {
      row = await client
          .from('maintenance_agreements')
          .update(payload)
          .eq('id', agreement.id)
          .select(_columns)
          .single();
    }

    final agreementId = MapperHelpers.uuid(row['id']);
    if (annualAmount != null) {
      await client.from('maintenance_agreement_pricing').upsert({
        'agreement_id': agreementId,
        'annual_amount': annualAmount,
      });
    }

    final pricing = await _loadPricingMap(agreementId: agreementId);
    return MaintenanceAgreementMapper.fromRow(MapperHelpers.row(row), annualAmount: pricing[agreementId]);
  }

  Future<Map<String, double>> _loadPricingMap({String? agreementId}) async {
    var query = client.from('maintenance_agreement_pricing').select('agreement_id, annual_amount');
    if (agreementId != null) {
      query = query.eq('agreement_id', agreementId);
    }
    final rows = await query;
    return {
      for (final row in rows)
        MapperHelpers.uuid(row['agreement_id']): MapperHelpers.dbl(row['annual_amount']),
    };
  }
}

class SupabaseSettingsRepository implements SettingsRepository {
  SupabaseSettingsRepository(this.client, {SupabaseAuditLog? audit}) : _audit = audit;

  final SupabaseClient client;
  final SupabaseAuditLog? _audit;

  static const _columns =
      'company_name, phone, address_line, city, state, zip, logo_storage_path, '
      'gps_workday_start, gps_workday_end, gps_timezone, gps_timezone_note, '
      'appointment_reminder_enabled, appointment_reminder_lead_hours, maintenance_reminder_enabled';
  static const _integrationColumns =
      'twilio_account_sid, twilio_auth_token, twilio_from_number, resend_api_key, resend_from_email, translate_api_key';

  @override
  Future<CompanySettings> getCompanySettings() async {
    final row = await client.from('company_settings').select(_columns).eq('id', 1).maybeSingle();
    if (row == null) return CompanySettings.defaults();
    return CompanySettingsMapper.fromRow(MapperHelpers.row(row));
  }

  @override
  Future<CompanySettings> saveCompanySettings(CompanySettings settings) async {
    final before = await getCompanySettings();
    final row = await client
        .from('company_settings')
        .upsert(CompanySettingsMapper.toRow(settings))
        .select(_columns)
        .single();
    final saved = CompanySettingsMapper.fromRow(MapperHelpers.row(row));
    await _audit?.record(
      action: AuditActions.settingsUpdate,
      entityType: 'company_settings',
      entityId: '1',
      metadata: AuditMetadata.settingsChange(
        beforeCompanyName: before.companyName,
        afterCompanyName: saved.companyName,
      ),
    );
    return saved;
  }

  @override
  Future<IntegrationCredentials> getIntegrationCredentials() async {
    final row = await client
        .from('integration_credentials')
        .select(_integrationColumns)
        .eq('id', 1)
        .maybeSingle();
    if (row == null) return IntegrationCredentials.empty();
    return IntegrationCredentialsMapper.fromRow(MapperHelpers.row(row));
  }

  @override
  Future<IntegrationCredentials> saveIntegrationCredentials(
    IntegrationCredentials credentials,
  ) async {
    final payload = {
      ...IntegrationCredentialsMapper.toRow(credentials),
      'updated_by': client.auth.currentUser?.id,
    };
    final row = await client
        .from('integration_credentials')
        .upsert(payload)
        .select(_integrationColumns)
        .single();
    final saved = IntegrationCredentialsMapper.fromRow(MapperHelpers.row(row));
    await _audit?.record(
      action: AuditActions.integrationsUpdate,
      entityType: 'integration_credentials',
      entityId: '1',
      metadata: AuditMetadata.integrationsChange(
        twilioConfigured: saved.hasTwilio,
        resendConfigured: saved.hasResend,
      ),
    );
    return saved;
  }

  @override
  Future<List<OfficeUser>> getOfficeUsers() async {
    final rows = await client
        .from('profiles')
        .select('id, first_name, last_name, email, role, is_active')
        .neq('role', UserRole.technician.dbValue)
        .order('role')
        .order('last_name');
    return [
      for (final row in rows) OfficeUserMapper.fromRow(MapperHelpers.row(row)),
    ];
  }
}
class SupabaseDocumentTemplateRepository implements DocumentTemplateRepository {
  SupabaseDocumentTemplateRepository(this._client, {SupabaseAuditLog? audit}) : _audit = audit;

  final SupabaseClient _client;
  final SupabaseAuditLog? _audit;

  @override
  Future<List<ManagedDocumentTemplate>> getTemplates() async {
    final templateRows = await _client
        .from('document_templates')
        .select('id, title, status, last_updated')
        .order('title');
    if (templateRows.isEmpty) return const [];

    final templateIds = [for (final row in templateRows) MapperHelpers.uuid(row['id'])];
    final versionRows = await _client
        .from('document_template_versions')
        .select('id, template_id, version, created_at, body, fields, note')
        .inFilter('template_id', templateIds)
        .order('version');

    final versionsByTemplate = <String, List<Map<String, dynamic>>>{};
    for (final row in versionRows) {
      final templateId = MapperHelpers.uuid(row['template_id']);
      versionsByTemplate.putIfAbsent(templateId, () => []).add(MapperHelpers.row(row));
    }

    return [
      for (final row in templateRows)
        DocumentTemplateMapper.fromRows(
          MapperHelpers.row(row),
          versionsByTemplate[MapperHelpers.uuid(row['id'])] ?? const [],
        ),
    ];
  }

  @override
  Future<ManagedDocumentTemplate?> getById(String id) async {
    final row = await _client
        .from('document_templates')
        .select('id, title, status, last_updated')
        .eq('id', id)
        .maybeSingle();
    if (row == null) return null;
    final versionRows = await _client
        .from('document_template_versions')
        .select('id, template_id, version, created_at, body, fields, note')
        .eq('template_id', id)
        .order('version');
    return DocumentTemplateMapper.fromRows(
      MapperHelpers.row(row),
      [for (final version in versionRows) MapperHelpers.row(version)],
    );
  }

  @override
  Future<List<ManagedDocumentTemplate>> getActiveTemplates() async {
    return [for (final template in await getTemplates()) if (template.isActive) template];
  }

  @override
  Future<ManagedDocumentTemplate> save(ManagedDocumentTemplate template) async {
    if (template.versions.isEmpty) {
      throw StateError('Template must include at least one version');
    }

    final existing = MapperHelpers.isUuid(template.id) ? await getById(template.id) : null;
    if (existing == null) {
      return _createTemplate(template);
    }

    await _client.from('document_templates').update({
      'title': template.title,
      'status': EnumDb.documentTemplateStatus(template.status),
      'last_updated': template.lastUpdated,
    }).eq('id', template.id);

    if (template.versions.length == existing.versions.length) {
      final last = template.versions.last;
      await _client
          .from('document_template_versions')
          .update({
            'body': last.body,
            'fields': DocumentTemplateMapper.fieldsToJson(last.fields),
            'note': last.note,
          })
          .eq('template_id', template.id)
          .eq('version', last.version);
    } else if (template.versions.length > existing.versions.length) {
      for (var i = existing.versions.length; i < template.versions.length; i++) {
        await _insertVersion(template.id, template.versions[i]);
      }
    }

    final saved = (await getById(template.id))!;
    if (!existing.isActive && saved.isActive) {
      await _audit?.record(
        action: AuditActions.templatePublish,
        entityType: 'document_template',
        entityId: saved.id,
        metadata: AuditMetadata.templatePublish(
          templateId: saved.id,
          title: saved.title,
          version: saved.currentVersion,
          note: 'activated',
        ),
      );
    } else if (saved.versions.length > existing.versions.length) {
      await _audit?.record(
        action: AuditActions.templatePublish,
        entityType: 'document_template',
        entityId: saved.id,
        metadata: AuditMetadata.templatePublish(
          templateId: saved.id,
          title: saved.title,
          version: saved.currentVersion,
          note: 'new_version',
        ),
      );
    }
    return saved;
  }

  Future<ManagedDocumentTemplate> _createTemplate(ManagedDocumentTemplate template) async {
    final row = await _client
        .from('document_templates')
        .insert({
          'title': template.title,
          'status': EnumDb.documentTemplateStatus(template.status),
          'last_updated': template.lastUpdated,
        })
        .select('id, title, status, last_updated')
        .single();
    final templateId = MapperHelpers.uuid(row['id']);
    for (final version in template.versions) {
      await _insertVersion(templateId, version);
    }
    final saved = (await getById(templateId))!;
    await _audit?.record(
      action: AuditActions.templatePublish,
      entityType: 'document_template',
      entityId: saved.id,
      metadata: AuditMetadata.templatePublish(
        templateId: saved.id,
        title: saved.title,
        version: saved.currentVersion,
        note: 'created',
      ),
    );
    return saved;
  }

  Future<void> _insertVersion(String templateId, DocumentTemplateVersion version) async {
    await _client.from('document_template_versions').insert({
      'template_id': templateId,
      'version': version.version,
      'body': version.body,
      'fields': DocumentTemplateMapper.fieldsToJson(version.fields),
      'note': version.note,
      'created_at': version.createdAt,
    });
  }
}

class SupabaseTechnicianLocationRepository implements TechnicianLocationRepository {
  SupabaseTechnicianLocationRepository(this.client);

  final SupabaseClient client;

  @override
  Future<List<TechnicianLocationFix>> historyFor(String technicianId, {int limit = 40}) async {
    if (!MapperHelpers.isUuid(technicianId)) return const [];
    final rows = await client
        .from('technician_locations')
        .select('id, technician_id, recorded_at, latitude, longitude, accuracy_meters, job_id')
        .eq('technician_id', technicianId)
        .order('recorded_at', ascending: false)
        .limit(limit);

    return [
      for (final row in rows)
        TechnicianLocationFix(
          id: MapperHelpers.strOrNull(row['id']),
          technicianId: MapperHelpers.uuid(row['technician_id']),
          latitude: MapperHelpers.dbl(row['latitude']),
          longitude: MapperHelpers.dbl(row['longitude']),
          accuracyMeters: row['accuracy_meters'] == null ? null : MapperHelpers.dbl(row['accuracy_meters']),
          recordedAt: DateTime.parse(MapperHelpers.isoTimestamp(row['recorded_at'])),
          jobId: MapperHelpers.strOrNull(row['job_id']),
        ),
    ];
  }
}
