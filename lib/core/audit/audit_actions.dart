/// Canonical audit action names stored in `public.audit_log.action`.
abstract final class AuditActions {
  static const authLogin = 'auth.login';
  static const settingsUpdate = 'settings.update';
  static const integrationsUpdate = 'settings.integrations_update';
  static const templatePublish = 'template.publish';
  static const invoiceVoid = 'invoice.void';
  static const jobAssign = 'job.assign';
  static const jobReassign = 'job.reassign';
  static const jobUnassign = 'job.unassign';
  static const jobStatus = 'job.status';
  static const customerCreate = 'customer.create';
  static const customerUpdate = 'customer.update';
  static const documentSign = 'document.sign';
  static const invoiceSave = 'invoice.save';
  static const invoiceStatus = 'invoice.status';
  static const paymentRecorded = 'payment.recorded';
  static const userInvite = 'user.invite';
  static const userRoleChange = 'user.role_change';
  static const userDeactivate = 'user.deactivate';
  static const userReactivate = 'user.reactivate';
  static const accountingExport = 'accounting.export';
}
