import 'package:hvac_admin/core/audit/audit_actions.dart';

String auditActionLabel(String action) {
  return switch (action) {
    AuditActions.authLogin => 'Sign in',
    AuditActions.settingsUpdate => 'Settings updated',
    AuditActions.templatePublish => 'Template published',
    AuditActions.invoiceVoid => 'Invoice voided',
    AuditActions.jobAssign => 'Job assigned',
    AuditActions.jobReassign => 'Job reassigned',
    AuditActions.jobUnassign => 'Job unassigned',
    AuditActions.jobStatus => 'Job status changed',
    AuditActions.customerCreate => 'Customer created',
    AuditActions.customerUpdate => 'Customer updated',
    AuditActions.documentSign => 'Document signed',
    AuditActions.invoiceSave => 'Invoice saved',
    AuditActions.invoiceStatus => 'Invoice status changed',
    AuditActions.paymentRecorded => 'Payment recorded',
    AuditActions.accountingExport => 'Accounting export',
    _ => action.replaceAll('.', ' ').replaceAll('_', ' '),
  };
}
