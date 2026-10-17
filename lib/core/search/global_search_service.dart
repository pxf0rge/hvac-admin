import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/enums/admin_module.dart';
import 'package:hvac_admin/core/models/global_search_hit.dart';
import 'package:hvac_admin/core/utils/formatters.dart';
import 'package:hvac_admin/data/repositories/billing_repository.dart';
import 'package:hvac_admin/data/repositories/customer_repository.dart';
import 'package:hvac_admin/data/repositories/job_repository.dart';

/// Cross-entity search without loading full tables.
class GlobalSearchService {
  const GlobalSearchService({
    required CustomerRepository customers,
    required JobRepository jobs,
    required BillingRepository billing,
  })  : _customers = customers,
        _jobs = jobs,
        _billing = billing;

  final CustomerRepository _customers;
  final JobRepository _jobs;
  final BillingRepository _billing;

  Future<List<GlobalSearchHit>> search(
    String query, {
    int limitPerKind = 8,
    bool includeFinancials = true,
  }) async {
    final needle = query.trim();
    if (needle.isEmpty) return const [];

    final futures = <Future<List<GlobalSearchHit>>>[
      _searchCustomers(needle, limitPerKind),
      _searchProperties(needle, limitPerKind),
      _searchJobs(needle, limitPerKind),
      _searchEquipment(needle, limitPerKind),
      if (includeFinancials) _searchInvoices(needle, limitPerKind),
    ];
    final groups = await Future.wait(futures);
    return [for (final group in groups) ...group];
  }

  Future<List<GlobalSearchHit>> _searchCustomers(String needle, int limit) async {
    final page = await _customers.getCustomersPage(offset: 0, limit: limit, search: needle);
    return [
      for (final customer in page.items)
        GlobalSearchHit(
          kind: GlobalSearchKind.customer,
          id: customer.id,
          title: customer.displayName,
          subtitle: '${customer.phone} · ${customer.email}',
          route: '${AdminModule.customers.path}/${customer.id}',
        ),
    ];
  }

  Future<List<GlobalSearchHit>> _searchProperties(String needle, int limit) async {
    final page = await _customers.getPropertiesPage(offset: 0, limit: limit, search: needle);
    return [
      for (final property in page.items)
        GlobalSearchHit(
          kind: GlobalSearchKind.property,
          id: property.id,
          title: property.address,
          subtitle: property.fullAddress,
          route: '${AdminModule.properties.path}/${property.id}',
        ),
    ];
  }

  Future<List<GlobalSearchHit>> _searchJobs(String needle, int limit) async {
    final page = await _jobs.getJobsPage(offset: 0, limit: limit, search: needle);
    return [
      for (final job in page.items)
        GlobalSearchHit(
          kind: GlobalSearchKind.job,
          id: job.id,
          title: job.jobNumber,
          subtitle: '${job.type.label} · ${job.technicianName}',
          route: '${AdminModule.jobs.path}/${job.id}',
        ),
    ];
  }

  Future<List<GlobalSearchHit>> _searchEquipment(String needle, int limit) async {
    final page = await _customers.getEquipmentPage(offset: 0, limit: limit, search: needle);
    return [
      for (final unit in page.items)
        GlobalSearchHit(
          kind: GlobalSearchKind.equipment,
          id: unit.id,
          title: unit.catalogLine,
          subtitle: unit.serial.isEmpty ? unit.manufacturer : '${unit.manufacturer} · ${unit.serial}',
          route: '${AdminModule.equipment.path}/${unit.id}',
        ),
    ];
  }

  Future<List<GlobalSearchHit>> _searchInvoices(String needle, int limit) async {
    final page = await _billing.getInvoicesPage(offset: 0, limit: limit, search: needle);
    return [
      for (final invoice in page.items)
        GlobalSearchHit(
          kind: GlobalSearchKind.invoice,
          id: invoice.id,
          title: invoice.number,
          subtitle: '${invoice.status.label} · ${formatCurrency(invoice.amount)}',
          route: '${AdminModule.invoices.path}/${invoice.id}',
        ),
    ];
  }
}
