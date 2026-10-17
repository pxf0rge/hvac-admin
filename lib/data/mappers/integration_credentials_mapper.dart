import 'package:hvac_admin/core/models/integration_credentials.dart';

abstract final class IntegrationCredentialsMapper {
  static IntegrationCredentials fromRow(Map<String, dynamic> row) {
    return IntegrationCredentials(
      twilioAccountSid: (row['twilio_account_sid'] as String?)?.trim() ?? '',
      twilioAuthToken: (row['twilio_auth_token'] as String?)?.trim() ?? '',
      twilioFromNumber: (row['twilio_from_number'] as String?)?.trim() ?? '',
      resendApiKey: (row['resend_api_key'] as String?)?.trim() ?? '',
      resendFromEmail: (row['resend_from_email'] as String?)?.trim() ?? '',
      translateApiKey: (row['translate_api_key'] as String?)?.trim() ?? '',
    );
  }

  static Map<String, dynamic> toRow(IntegrationCredentials credentials) {
    return {
      'id': 1,
      'twilio_account_sid': credentials.twilioAccountSid.trim(),
      'twilio_auth_token': credentials.twilioAuthToken.trim(),
      'twilio_from_number': credentials.twilioFromNumber.trim(),
      'resend_api_key': credentials.resendApiKey.trim(),
      'resend_from_email': credentials.resendFromEmail.trim(),
      'translate_api_key': credentials.translateApiKey.trim(),
    };
  }
}
