import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/office_billing.dart';
import 'package:hvac_admin/data/mappers/billing_mapper.dart';
import 'package:hvac_admin/data/mappers/customer_mapper.dart';
import 'package:hvac_admin/data/mappers/enum_db.dart';
import 'package:hvac_admin/data/mappers/equipment_mapper.dart';
import 'package:hvac_admin/data/mappers/job_mapper.dart';
import 'package:hvac_admin/data/mappers/property_mapper.dart';
import 'package:hvac_admin/data/repositories/mock_repositories.dart';

void main() {
  const customerId = '11111111-1111-4111-8111-111111111111';
  const propertyId = '22222222-2222-4222-8222-222222222222';
  const jobId = '33333333-3333-4333-8333-333333333333';
  const equipmentId = '44444444-4444-4444-8444-444444444444';
  const estimateId = '55555555-5555-4555-8555-555555555555';
  const invoiceId = '66666666-6666-4666-8666-666666666666';

  test('EnumDb round-trips job and billing enums', () {
    expect(EnumDb.jobStatusFromDb(EnumDb.jobStatus(JobStatus.onTheWay)), JobStatus.onTheWay);
    expect(EnumDb.jobTypeFromDb(EnumDb.jobType(JobType.acNotCooling)), JobType.acNotCooling);
    expect(EnumDb.invoiceStatusFromDb(EnumDb.invoiceStatus(InvoiceStatus.overdue)), InvoiceStatus.overdue);
    expect(EnumDb.estimateStatusFromDb(EnumDb.estimateStatus(EstimateStatus.approved)), EstimateStatus.approved);
  });

  test('CustomerMapper round-trips', () {
    const row = {
      'id': customerId,
      'first_name': 'Pat',
      'last_name': 'Nguyen',
      'phone': '2175550100',
      'email': 'pat.rls@hvacpro.com',
      'city': 'Springfield',
      'state': 'IL',
    };
    final model = CustomerMapper.fromRow(row);
    expect(model.id, customerId);
    expect(model.displayName, 'Pat Nguyen');
    expect(CustomerMapper.toRow(model)['email'], 'pat.rls@hvacpro.com');
  });

  test('PropertyMapper round-trips property types', () {
    const row = {
      'id': propertyId,
      'customer_id': customerId,
      'address': '77 Oak Lane',
      'city': 'Springfield',
      'state': 'IL',
      'zip': '62704',
      'type': 'multi_family',
      'label': 'Main home',
    };
    final model = PropertyMapper.fromRow(row);
    expect(model.type, PropertyType.multiFamily);
    expect(PropertyMapper.toRow(model)['type'], 'multi_family');
  });

  test('JobMapper maps job_number as display field with uuid id', () {
    const row = {
      'id': jobId,
      'property_id': propertyId,
      'job_number': 'JOB-RLS-21',
      'type': 'ac_not_cooling',
      'status': 'assigned',
      'priority': 'high',
      'scheduled_date': '2026-08-28',
      'start_time': '09:00:00',
      'end_time': '11:00:00',
      'technician_id': '77777777-7777-4777-8777-777777777777',
      'description': 'RLS verification job',
      'notes': '',
      'parts_used': '',
    };
    final history = JobMapper.historyFromRow(row, technicianName: 'Carlos Rodriguez');
    expect(history.id, jobId);
    expect(history.jobNumber, 'JOB-RLS-21');
    expect(history.type, JobType.acNotCooling);
    expect(history.priority, JobPriority.high);
    expect(history.startTime, '09:00');
    expect(JobMapper.historyToRow(history)['job_number'], 'JOB-RLS-21');
  });

  test('EquipmentMapper round-trips equipment type', () {
    const row = {
      'id': equipmentId,
      'property_id': propertyId,
      'name': 'Carrier split',
      'manufacturer': 'Carrier',
      'model': '24ACC6',
      'serial': 'SN-123',
      'type': 'central_ac',
      'capacity': '3 ton',
      'installed_on': '2020-05-01',
      'installer': 'Arctic HVAC Solutions',
    };
    final model = EquipmentMapper.fromRow(row);
    expect(model.typeKey, 'central_ac');
    expect(model.typeLabel, 'Central AC');
    expect(EquipmentMapper.toRow(model)['type'], 'central_ac');
  });

  test('EquipmentMapper maps warranties', () {
    const warrantyRow = {
      'title': 'Compressor',
      'serial': 'W-1',
      'expires_on': '2027-06-01',
    };
    final warranty = EquipmentMapper.warrantyFromRow(warrantyRow);
    expect(warranty.state, WarrantyState.active);
  });

  test('BillingMapper round-trips estimate and invoice', () {
    const estimateRow = {
      'id': estimateId,
      'number': 'EST-RLS-21',
      'status': 'approved',
      'issued_on': '2026-08-28',
      'property_id': propertyId,
      'job_id': jobId,
      'notes': 'Financial row',
    };
    const items = [BillingLineItem(description: 'Capacitor', quantity: 1, unitPrice: 185)];
    final estimate = BillingMapper.estimateFromRow(estimateRow, items: items);
    expect(estimate.number, 'EST-RLS-21');
    expect(estimate.amount, 185);
    expect(BillingMapper.estimateToRow(estimate)['status'], 'approved');

    const invoiceRow = {
      'id': invoiceId,
      'number': 'INV-RLS-21',
      'status': 'sent',
      'issued_on': '2026-08-28',
      'due_on': '2026-09-11',
      'property_id': propertyId,
      'job_id': jobId,
      'estimate_id': estimateId,
      'notes': 'Technician must not see this',
    };
    final invoice = BillingMapper.invoiceFromRow(invoiceRow, items: items);
    expect(invoice.estimateId, estimateId);
    expect(BillingMapper.invoiceToRow(invoice)['due_on'], '2026-09-11');
  });

  test('MockCustomerRepository returns seed customer', () async {
    final repo = MockCustomerRepository();
    final customer = await repo.getCustomer(customerId);
    expect(customer?.displayName, 'Pat Nguyen');
    final properties = await repo.getPropertiesForCustomer(customerId);
    expect(properties, hasLength(1));
    expect(properties.first.address, '77 Oak Lane');
  });

  test('MockJobRepository returns seed job', () async {
    final repo = MockJobRepository();
    final job = await repo.getJob(jobId);
    expect(job?.jobNumber, 'JOB-RLS-21');
    expect(job?.technicianName, 'Carlos Rodriguez');
  });
}
