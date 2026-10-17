import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/controllers/maintenance_agreement_controller.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/models/maintenance_agreement.dart';
import 'package:hvac_admin/data/datasources/mock_seed_data.dart';
import 'package:hvac_admin/data/mappers/enum_db.dart';
import 'package:hvac_admin/data/mappers/maintenance_agreement_mapper.dart';
import 'package:hvac_admin/data/repositories/mock_repositories.dart';

void main() {
  test('MaintenanceAgreementMapper round-trips enums and row', () {
    expect(
      EnumDb.maintenanceAgreementStatusFromDb(EnumDb.maintenanceAgreementStatus(MaintenanceAgreementStatus.paused)),
      MaintenanceAgreementStatus.paused,
    );
    expect(
      EnumDb.maintenanceAgreementFrequencyFromDb(
        EnumDb.maintenanceAgreementFrequency(MaintenanceAgreementFrequency.semiAnnual),
      ),
      MaintenanceAgreementFrequency.semiAnnual,
    );

    const row = {
      'id': '11111111-1111-4111-8111-111111111111',
      'customer_id': '22222222-2222-4222-8222-222222222222',
      'property_id': '33333333-3333-4333-8333-333333333333',
      'title': 'Annual plan',
      'status': 'active',
      'frequency': 'annual',
      'start_on': '2026-01-01',
      'end_on': '2026-12-31',
      'next_service_on': '2026-04-01',
      'renewal_reminder_on': '2026-11-15',
      'notes': 'Priority dispatch',
    };
    final agreement = MaintenanceAgreementMapper.fromRow(row, annualAmount: 389);
    expect(agreement.annualAmount, 389);
    expect(MaintenanceAgreementMapper.toRow(agreement)['frequency'], 'annual');
  });

  test('expiring filter surfaces agreements due within 30 days', () async {
    final seed = MockSeedData();
    final repo = MockMaintenanceAgreementRepository(seed: seed);
    final controller = MaintenanceAgreementController(repo);
    await controller.load(force: true);

    final expiring = controller.agreementsFor(expiringOnly: true, now: DateTime(2026, 8, 30));
    expect(expiring.any((a) => a.id == MockSeedIds.maintenanceAgreementId), isTrue);
    expect(expiring.every((a) => a.status == MaintenanceAgreementStatus.active), isTrue);
  });

  test('saveAgreement persists create and status update', () async {
    final seed = MockSeedData();
    final repo = MockMaintenanceAgreementRepository(seed: seed);
    final controller = MaintenanceAgreementController(repo);
    await controller.load(force: true);

    final created = await controller.saveAgreement(
      MaintenanceAgreement(
        id: 'maint_new',
        customerId: MockSeedIds.customerId,
        propertyId: MockSeedIds.propertyId,
        title: 'Test plan',
        status: MaintenanceAgreementStatus.active,
        frequency: MaintenanceAgreementFrequency.monthly,
        startOn: '2026-08-29',
        endOn: '2027-08-29',
        renewalReminderOn: '2027-07-15',
        notes: 'Created in test',
      ),
      annualAmount: 120,
    );
    expect(controller.agreementById(created.id), isNotNull);

    await controller.setStatus(created.id, MaintenanceAgreementStatus.paused);
    expect(controller.agreementById(created.id)!.status, MaintenanceAgreementStatus.paused);
  });
}
