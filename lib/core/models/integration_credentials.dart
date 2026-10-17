class IntegrationCredentials {
  const IntegrationCredentials({
    this.twilioAccountSid = '',
    this.twilioAuthToken = '',
    this.twilioFromNumber = '',
    this.resendApiKey = '',
    this.resendFromEmail = '',
    this.translateApiKey = '',
  });

  final String twilioAccountSid;
  final String twilioAuthToken;
  final String twilioFromNumber;
  final String resendApiKey;
  final String resendFromEmail;
  final String translateApiKey;

  factory IntegrationCredentials.empty() => const IntegrationCredentials();

  bool get hasTwilio =>
      twilioAccountSid.trim().isNotEmpty &&
      twilioAuthToken.trim().isNotEmpty &&
      twilioFromNumber.trim().isNotEmpty;

  bool get hasResend =>
      resendApiKey.trim().isNotEmpty && resendFromEmail.trim().isNotEmpty;

  bool get hasTranslate => translateApiKey.trim().isNotEmpty;

  IntegrationCredentials copyWith({
    String? twilioAccountSid,
    String? twilioAuthToken,
    String? twilioFromNumber,
    String? resendApiKey,
    String? resendFromEmail,
    String? translateApiKey,
  }) {
    return IntegrationCredentials(
      twilioAccountSid: twilioAccountSid ?? this.twilioAccountSid,
      twilioAuthToken: twilioAuthToken ?? this.twilioAuthToken,
      twilioFromNumber: twilioFromNumber ?? this.twilioFromNumber,
      resendApiKey: resendApiKey ?? this.resendApiKey,
      resendFromEmail: resendFromEmail ?? this.resendFromEmail,
      translateApiKey: translateApiKey ?? this.translateApiKey,
    );
  }
}
