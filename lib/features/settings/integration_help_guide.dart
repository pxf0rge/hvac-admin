/// Step-by-step guides so an office owner can obtain Twilio / Resend credentials
/// without developer help. Labels match the live provider consoles (English).
enum IntegrationHelpTopic {
  twilioAccountSid,
  twilioAuthToken,
  twilioFromNumber,
  resendApiKey,
  resendFromEmail,
  translateApiKey,
}

class IntegrationHelpGuide {
  const IntegrationHelpGuide({
    required this.title,
    required this.summary,
    required this.steps,
    required this.tips,
    this.officialUrl,
  });

  final String title;
  final String summary;
  final List<String> steps;
  final List<String> tips;
  final String? officialUrl;

  static IntegrationHelpGuide forTopic(IntegrationHelpTopic topic) {
    switch (topic) {
      case IntegrationHelpTopic.twilioAccountSid:
        return const IntegrationHelpGuide(
          title: 'How to get Twilio Account SID',
          summary:
              'Account SID identifies your Twilio account. It starts with “AC” and is safe to copy into Arctic HVAC Solutions. You create it by signing up for Twilio — no coding required.',
          officialUrl: 'https://console.twilio.com/',
          steps: [
            'Open your browser and go to https://www.twilio.com/try-twilio',
            'Click Sign up and create an account with your work email.',
            'Verify your email, then verify your personal/mobile phone when Twilio asks (required for trial).',
            'Complete the short onboarding questions (company name, what you want to build — choose SMS / messaging).',
            'You land on the Twilio Console home (https://console.twilio.com/).',
            'On the Console dashboard, find the Account Info panel (often on the right or under Account).',
            'Copy Account SID — it looks like ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx.',
            'Paste that value into the “Twilio Account SID” field in Arctic HVAC Solutions Settings, then Save messaging credentials.',
          ],
          tips: [
            'Account SID is an ID, not a password. Still keep it private inside your company.',
            'If you have multiple Twilio projects/subaccounts, use the SID from the account that owns your SMS number.',
            'You can always find it again: Console → Account → Account Info / API keys & tokens area.',
          ],
        );
      case IntegrationHelpTopic.twilioAuthToken:
        return const IntegrationHelpGuide(
          title: 'How to get Twilio Auth Token',
          summary:
              'Auth Token is the secret password for your Twilio account. Arctic HVAC Solutions stores it in Supabase so SMS can be sent. Treat it like a bank password.',
          officialUrl: 'https://console.twilio.com/',
          steps: [
            'Sign in at https://console.twilio.com/ with the same Twilio account you used for Account SID.',
            'Open the Console dashboard home.',
            'In Account Info, find Auth Token next to Account SID.',
            'Click the eye / “Show” control to reveal the Auth Token (Twilio hides it by default).',
            'Click Copy.',
            'Paste into “Twilio Auth Token” in Arctic HVAC Solutions Settings.',
            'Click Save messaging credentials in Arctic HVAC Solutions.',
            'Optional but recommended: if this token was ever shared in chat or email, click “Request a new Auth Token” / rotate it in Twilio, then paste the new token into Arctic HVAC Solutions and save again.',
          ],
          tips: [
            'Never put Auth Token in customer emails, Slack, or screenshots.',
            'Do not confuse Auth Token with API Key SID (starts with SK…) — Arctic HVAC Solutions needs the primary Auth Token from Account Info.',
            'After rotating the token in Twilio, old tokens stop working until you update Settings.',
          ],
        );
      case IntegrationHelpTopic.twilioFromNumber:
        return const IntegrationHelpGuide(
          title: 'How to get a Twilio SMS from-number',
          summary:
              'SMS must be sent FROM a phone number you own in Twilio. Trial accounts usually get one free US number. Enter it in E.164 format, e.g. +17372583742.',
          officialUrl: 'https://console.twilio.com/us1/develop/phone-numbers/manage/incoming',
          steps: [
            'Sign in at https://console.twilio.com/.',
            'In the left menu open Phone Numbers → Manage → Buy a number (or Active numbers).',
            'If Active numbers is empty: click Buy a number / Get a number.',
            'Search for a number in your country. Make sure SMS capability is checked.',
            'Click Buy / Get this number and confirm (trial often includes one free number).',
            'Open Phone Numbers → Manage → Active numbers and click your new number.',
            'Copy the Phone Number exactly as shown (example: +1 737 258 3742).',
            'In Arctic HVAC Solutions, enter it with no spaces: +17372583742 (always start with + and country code).',
            'Save messaging credentials.',
            'Trial accounts: open Phone Numbers → Manage → Verified Caller IDs and add / verify every customer phone you want to text during trial. Paid accounts can text most numbers without this list.',
          ],
          tips: [
            'If Active numbers is empty, SMS will fail even when SID and token are correct.',
            'Format must be E.164: + then country code then number, no spaces or dashes.',
            'Geo permissions: Console → Messaging → Settings → Geo permissions — enable the countries you send to.',
            'Upgrading from Trial removes the “verified numbers only” limit.',
          ],
        );
      case IntegrationHelpTopic.resendApiKey:
        return const IntegrationHelpGuide(
          title: 'How to get a Resend API key',
          summary:
              'Resend sends outbound email for Arctic HVAC Solutions. Create a free account, then create an API key and paste it here.',
          officialUrl: 'https://resend.com/api-keys',
          steps: [
            'Open https://resend.com/signup and create an account (Google or email).',
            'Confirm your email if Resend asks.',
            'After login, open https://resend.com/api-keys (or Dashboard → API Keys).',
            'Click Create API Key.',
            'Name it something clear, e.g. “Arctic HVAC Solutions production”.',
            'Permission: choose Sending access (enough for Arctic HVAC Solutions). Full access also works.',
            'Click Add / Create.',
            'Copy the key immediately — it starts with re_ and is shown only once.',
            'Paste into “Resend API key” in Arctic HVAC Solutions Settings and Save messaging credentials.',
            'If you lose the key, create a new API key in Resend, paste the new value into Arctic HVAC Solutions, and delete the old key in Resend.',
          ],
          tips: [
            'Store the key only in Arctic HVAC Solutions Settings (Supabase). Do not commit it to code or chat.',
            'A “Sending only” restricted key is fine — Arctic HVAC Solutions only sends email.',
            'If send fails with 401, the key was revoked or mistyped — create a fresh key.',
          ],
        );
      case IntegrationHelpTopic.resendFromEmail:
        return const IntegrationHelpGuide(
          title: 'How to set Resend from-email',
          summary:
              'From email is the address customers see as the sender. For quick testing use Resend’s onboarding address; for real customers, verify your own domain.',
          officialUrl: 'https://resend.com/domains',
          steps: [
            'Option A — Testing only (fastest):',
            'Use exactly: onboarding@resend.dev in the “Resend from email” field.',
            'With this address, Resend usually allows sending only to the email of your Resend account (and sometimes other verified test recipients).',
            'Save credentials, then send a test email from Arctic HVAC Solutions Communication to your own Resend login email.',
            'Option B — Real customer email (recommended for production):',
            'In Resend open https://resend.com/domains and click Add Domain.',
            'Enter your company domain (example: yourhvaccompany.com).',
            'Resend shows DNS records (SPF, DKIM, and sometimes MX/DMARC). Copy them.',
            'In your domain registrar (GoDaddy, Cloudflare, Namecheap, etc.), add those DNS records exactly as shown.',
            'Return to Resend and click Verify. Wait until the domain status is Verified (can take minutes to a few hours).',
            'Choose a from address on that domain, e.g. noreply@yourhvaccompany.com or office@yourhvaccompany.com.',
            'Enter that full address in Arctic HVAC Solutions “Resend from email” and Save.',
            'Send a test from Communication to a real customer inbox and confirm it arrives (check spam once).',
          ],
          tips: [
            'Do not invent a from address on a domain you have not verified — Resend will reject the send.',
            'Keep the display style professional: office@… or noreply@… rather than a personal Gmail.',
            'If using onboarding@resend.dev, customer emails to arbitrary addresses will fail until you verify a domain.',
          ],
        );
      case IntegrationHelpTopic.translateApiKey:
        return const IntegrationHelpGuide(
          title: 'How to get a DeepL API key',
          summary:
              'Arctic HVAC Solutions translates job notes EN ↔ ES through DeepL. The API key stays on the server (Settings / Edge secret) and never overwrites the original note.',
          officialUrl: 'https://www.deepl.com/pro-api',
          steps: [
            'Open https://www.deepl.com/pro-api and create a DeepL account (Free API plan is enough to start).',
            'Complete email verification if DeepL asks.',
            'Open the DeepL API account dashboard / Account → API Keys.',
            'Copy your Authentication Key (Free keys often end with “:fx”).',
            'Paste it into “DeepL API key” in Arctic HVAC Solutions Settings.',
            'Click Save messaging credentials.',
            'Open a job with technician notes and tap Translate to confirm a Spanish (or English) translation appears under the original.',
          ],
          tips: [
            'Without a key, Translate shows a clear “not configured” message — it will not invent fake translations.',
            'You can also set the Edge secret DEEPL_API_KEY; Settings overrides it when filled.',
            'Free DeepL has monthly character limits — cache avoids repeat spend on the same note.',
          ],
        );
    }
  }
}
