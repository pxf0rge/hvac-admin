# HVAC Admin — Third-party integrations

Secrets live in **Supabase Edge Function secrets** or CI/CD vaults — never in the Flutter admin app.

Edge functions and SQL are owned by `../hvac_client/supabase/`. Deploy from that project.

**Security:** [security.md](security.md) · **Payments detail:** [payments.md](payments.md) · **Accounting CSV:** [accounting-export.md](accounting-export.md)

## Messaging (SMS + email)

Edge function: `supabase/functions/send-message`

```bash
cd ../hvac_client
supabase functions deploy send-message
```

### Required secrets (production)

| Secret | Provider | Purpose |
|--------|----------|---------|
| `TWILIO_ACCOUNT_SID` | Twilio | SMS account |
| `TWILIO_AUTH_TOKEN` | Twilio | SMS auth |
| `TWILIO_FROM_NUMBER` | Twilio | Sender phone (E.164) |
| `RESEND_API_KEY` | Resend | Email API key |
| `RESEND_FROM_EMAIL` | Resend | Verified sender address |

Auto-injected: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`

### Optional

| Secret | Purpose |
|--------|---------|
| `MESSAGING_TEST_MODE=true` | Staging — mock provider ids without Twilio/Resend |

### Admin app behavior

| Context | Sender | Notes |
|---------|--------|-------|
| Widget tests (`supabase: null`) | `MockMessageSender` | No network |
| Production boot | `SupabaseMessageSender` → `send-message` | Office JWT required; edge checks `profiles.role` |

Persistence: `SupabaseCommunicationRepository` → `public.messages`.

### Inbound webhooks

Edge function: `messaging-webhook` (deploy with `--no-verify-jwt`: providers POST `x-hvac-signature`, not a Supabase JWT — the function verifies the shared secret itself)  
Secret: `WEBHOOK_SHARED_SECRET` (header `x-hvac-signature`)

Admin UI surfaces delivery status and webhook failures in Communication module.

## Payments (Stripe Checkout)

Edge functions: `create-checkout`, `payments-webhook`, `payments-status`, `portal-pay`

| Secret | Purpose |
|--------|---------|
| `STRIPE_SECRET_KEY` | Live/test Stripe secret |
| `STRIPE_WEBHOOK_SECRET` | Webhook signature verification |
| `PAYMENTS_TEST_MODE` | Mock checkout when Stripe unset (dev) |
| `PAYMENTS_SUCCESS_URL` / `PAYMENTS_CANCEL_URL` | Real HTTPS redirects (required for Stripe) |
| `PORTAL_BASE_URL` | Alternate base for success/cancel + portal links |

```bash
cd ../hvac_client
supabase functions deploy create-checkout
supabase functions deploy payments-webhook
supabase functions deploy payments-status
supabase functions deploy portal-pay --no-verify-jwt
```

Admin flow: Invoice detail → **Pay online** (label from `payments-status`) → `SupabasePaymentProvider` → hosted Checkout URL.

Portal flow: `/i/:token` → **Pay now** → `portal-pay`.

Settings → Online payments readiness (flags only; secrets stay in Supabase).

Manual cash/check: `PaymentService.recordManualPayment()` (owner/admin only).

See [payments.md](payments.md) for E2E checklist.
## Realtime + GPS

No third-party API keys. Admin subscribes to Supabase Realtime (`SupabaseRealtimeService`) for jobs, assignments, technician locations, notifications.

Technician GPS fixes are written by `hvac_client` → read by admin GPS map via `SupabaseTechnicianLocationRepository`.

## Cross-app dependency

| Integration | Admin | Technician (`hvac_client`) |
|-------------|-------|----------------------------|
| Supabase Auth | Office roles | Technician role |
| Job assignments | Creates via dispatch | Receives on mobile |
| Messaging | Sends from office | May receive notifications |
| Payments | Initiates checkout | N/A |
| Document signatures | Views completed docs | Captures in field |

Both apps must use the **same** `SUPABASE_URL` per environment ([environments.md](environments.md)).

## Verification

- [ ] `send-message` returns provider id for owner JWT
- [ ] `create-checkout` returns `checkout_url` for owner/admin
- [ ] Webhook signatures rejected when invalid
- [ ] `office_staff` cannot access invoices or financial RPCs
- [ ] Cross-app: assign job in admin → visible in technician app
