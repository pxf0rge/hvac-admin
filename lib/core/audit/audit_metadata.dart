/// Helpers for consistent audit metadata shapes.
abstract final class AuditMetadata {
  static Map<String, Object?> jobAssignment({
    String? beforeTechnicianId,
    String? afterTechnicianId,
    bool reassigned = false,
  }) {
    return {
      if (beforeTechnicianId != null) 'before_technician_id': beforeTechnicianId,
      if (afterTechnicianId != null) 'after_technician_id': afterTechnicianId,
      'reassigned': reassigned,
    };
  }

  static Map<String, Object?> jobStatus({
    required String kind,
    String? beforeStatus,
    String? afterStatus,
  }) {
    return {
      'kind': kind,
      if (beforeStatus != null) 'before_status': beforeStatus,
      if (afterStatus != null) 'after_status': afterStatus,
    };
  }

  static Map<String, Object?> authLogin({required String email}) {
    return {'email': email.trim().toLowerCase()};
  }

  static Map<String, Object?> settingsChange({
    required String beforeCompanyName,
    required String afterCompanyName,
  }) {
    return {
      'before_company_name': beforeCompanyName,
      'after_company_name': afterCompanyName,
    };
  }

  /// Never include secret values — only configuration flags.
  static Map<String, Object?> integrationsChange({
    required bool twilioConfigured,
    required bool resendConfigured,
  }) {
    return {
      'twilio_configured': twilioConfigured,
      'resend_configured': resendConfigured,
    };
  }

  static Map<String, Object?> templatePublish({
    required String templateId,
    required String title,
    int? version,
    String? note,
  }) {
    return {
      'template_id': templateId,
      'title': title,
      if (version != null) 'version': version,
      if (note != null) 'note': note,
    };
  }

  static Map<String, Object?> invoiceStatusChange({
    required String invoiceId,
    required String number,
    required String beforeStatus,
    required String afterStatus,
    required double amount,
  }) {
    return {
      'invoice_id': invoiceId,
      'number': number,
      'before_status': beforeStatus,
      'after_status': afterStatus,
      'amount': amount,
    };
  }

  static Map<String, Object?> customerSnapshot({
    required String customerId,
    required String firstName,
    required String lastName,
  }) {
    return {
      'customer_id': customerId,
      'name': '$firstName $lastName'.trim(),
    };
  }

  static Map<String, Object?> documentSigned({
    required String documentId,
    required String signerName,
    String? templateId,
  }) {
    return {
      'document_id': documentId,
      'signer_name': signerName,
      if (templateId != null) 'template_id': templateId,
    };
  }

  static Map<String, Object?> invoice({
    required String invoiceId,
    required String number,
    required String status,
    required double amount,
  }) {
    return {
      'invoice_id': invoiceId,
      'number': number,
      'status': status,
      'amount': amount,
    };
  }

  static Map<String, Object?> payment({
    required String paymentId,
    required String invoiceId,
    required String status,
    required double amount,
    required String provider,
  }) {
    return {
      'payment_id': paymentId,
      'invoice_id': invoiceId,
      'status': status,
      'amount': amount,
      'provider': provider,
    };
  }
}
