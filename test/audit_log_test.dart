import 'package:flutter_test/flutter_test.dart';
import 'package:hvac_admin/core/audit/audit_actions.dart';
import 'package:hvac_admin/core/audit/audit_metadata.dart';
import 'package:hvac_admin/core/audit/in_memory_audit_log.dart';
import 'package:hvac_admin/data/repositories/mock_repositories.dart';

void main() {
  test('job reassign writes audit entry with before and after technician', () async {
    final audit = InMemoryAuditLog();
    final jobs = MockJobRepository(auditLog: audit);
    final all = await jobs.getJobs();
    expect(all, isNotEmpty);

    final job = all.first;
    final technicians = await MockTechnicianRepository().getTechnicians();
    expect(technicians.length, greaterThanOrEqualTo(2));
    final firstTech = technicians[0].id;
    final secondTech = technicians[1].id;

    await jobs.assignJob(jobId: job.id, technicianId: firstTech);
    await jobs.assignJob(jobId: job.id, technicianId: secondTech);

    final reassign = audit.entries.where((entry) => entry.action == AuditActions.jobReassign);
    expect(reassign, isNotEmpty);
    final entry = reassign.last;
    expect(entry.action, AuditActions.jobReassign);
    expect(entry.entityType, 'job');
    expect(entry.entityId, job.id);
    expect(entry.metadata['before_technician_id'], firstTech);
    expect(entry.metadata['after_technician_id'], secondTech);
    expect(entry.metadata['reassigned'], isTrue);
  });

  test('AuditMetadata.jobAssignment shapes consistent payload', () {
    final metadata = AuditMetadata.jobAssignment(
      beforeTechnicianId: 'tech_a',
      afterTechnicianId: 'tech_b',
      reassigned: true,
    );
    expect(metadata['before_technician_id'], 'tech_a');
    expect(metadata['after_technician_id'], 'tech_b');
    expect(metadata['reassigned'], isTrue);
  });
}
