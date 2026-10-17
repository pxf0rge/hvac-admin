import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/config/portal_config.dart';
import 'package:hvac_admin/core/messaging/message_variables.dart';
import 'package:hvac_admin/core/models/office_directory.dart';
import 'package:hvac_admin/core/enums/domain_enums.dart';
import 'package:hvac_admin/core/portal/portal_link_service.dart';
import 'package:hvac_admin/data/repositories/mock_portal_repository.dart';

void main() {
  test('PortalConfig builds estimate/invoice/document URLs without example domains', () {
    expect(PortalConfig.estimateUrl('abc123'), contains('/e/abc123'));
    expect(PortalConfig.invoiceUrl('abc123'), contains('/i/abc123'));
    expect(PortalConfig.documentUrl('abc123'), contains('/d/abc123'));
    expect(PortalConfig.estimateUrl('abc123'), isNot(contains('hvacpro.example')));
  });

  test('MessageVariables defaults do not use hvacpro.example', () {
    final job = HistoryJob(
      id: 'j1',
      propertyId: 'p1',
      jobNumber: 'JOB-1',
      type: JobType.diagnostic,
      status: JobStatus.assigned,
      priority: JobPriority.normal,
      date: '2026-09-10',
      startTime: '09:00',
      endTime: '11:00',
      technicianName: 'Tech',
    );
    final vars = MessageVariables.forJob(job: job);
    expect(vars['estimate_url'], isNot(contains('hvacpro.example')));
    expect(vars['invoice_url'], isNot(contains('hvacpro.example')));
    expect(vars['document_url'], isNot(contains('hvacpro.example')));
  });

  test('PortalLinkService mints and resolves mock tokens', () async {
    final service = PortalLinkService(MockPortalRepository());
    final url = await service.mintEstimateUrl('est-1');
    expect(url, contains('/e/'));
    final token = url.split('/e/').last;
    final resolved = await service.resolve(token);
    expect(resolved['ok'], isTrue);
    expect(resolved['payload']['resource_type'], 'estimate');

    final bad = await service.resolve('nope');
    expect(bad['ok'], isFalse);
  });
}
