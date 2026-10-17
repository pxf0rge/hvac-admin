# HVAC Admin — payments and Stripe

Online payments use **Stripe Checkout** via Supabase Edge Functions. Flutter never sees Stripe secret keys.

Schema and RPCs live in `../hvac_client/supabase/migrations/` (`payments`, `payment_webhook_events`, `create_payment_intent`, `ingest_payment_webhook`).

## Architecture

```
Invoice detail → Pay online
  → PaymentService.startCheckout()
  → SupabasePaymentProvider → Edge Function `create-checkout`
  → RPC create_payment_intent → payments row + checkout URL

Customer portal `/i/:token` → Pay now
  → Edge Function `portal-pay` (token validated; no office JWT)
  → Stripe Checkout + payments row (service role)

Stripe webhook → Edge Function `payments-webhook`
  → RPC ingest_payment_webhook → payment succeeded + invoice paid

Settings → Online payments readiness
  → Edge Function `payments-status` (flags only; no secrets)
```

Manual cash/check payments create a `provider = manual` row via `PaymentService.recordManualPayment()` (office owner/admin only).

## Edge Function secrets (Supabase dashboard)

Set on the **server** only (Supabase → Edge Functions → Secrets):

| Secret | Required | Description |
|--------|----------|-------------|
| `STRIPE_SECRET_KEY` | For Stripe Checkout | Test or live secret (`sk_test_…` / `sk_live_…`) |
| `STRIPE_WEBHOOK_SECRET` | For webhooks | Stripe signing secret |
| `PAYMENTS_TEST_MODE` | Dev without Stripe | `true` → mock checkout when Stripe key unset |
| `PAYMENTS_SUCCESS_URL` | With Stripe | Real HTTPS success redirect (e.g. `https://office…/payments/success`) |
| `PAYMENTS_CANCEL_URL` | With Stripe | Real HTTPS cancel redirect |
| `PORTAL_BASE_URL` | Alternative | If success/cancel unset, derived as `{PORTAL_BASE_URL}/payments/success\|cancel` |

**Never** use `hvacpro.example` — `create-checkout` refuses Stripe sessions without real redirect URLs.

Also required by functions (usually auto-injected): `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`.

Deploy from `hvac_client`:

```bash
cd ../hvac_client
supabase functions deploy create-checkout
supabase functions deploy payments-webhook --no-verify-jwt
supabase functions deploy payments-status
supabase functions deploy portal-pay --no-verify-jwt
```

`payments-webhook` needs `--no-verify-jwt`: Stripe POSTs `stripe-signature`, not a Supabase JWT — the function verifies the signature itself via `STRIPE_WEBHOOK_SECRET`.

## Flutter / admin app

- **No** `STRIPE_SECRET_KEY` in Dart defines or source.
- Invoice button label comes from `payments-status` (`Pay online`, `Pay online (Stripe test)`, etc.).
- Public routes: `/payments/success`, `/payments/cancel` (Stripe redirects).
- Development and widget tests use `MockPaymentProvider` (no network).

## Webhook setup (Stripe dashboard)

1. Endpoint: `https://<project-ref>.supabase.co/functions/v1/payments-webhook` (deployed with `--no-verify-jwt`)
2. Events: `checkout.session.completed`, `payment_intent.payment_failed` (see `payments-webhook` in `hvac_client`)
3. Signing secret → Supabase secret `STRIPE_WEBHOOK_SECRET`

## E2E (test mode)

1. Set `STRIPE_SECRET_KEY=sk_test_…`, redirect URLs, webhook secret.
2. Invoice → **Pay online (Stripe test)** → open Checkout URL → card `4242…`.
3. Confirm webhook marks payment `succeeded` and invoice `paid`.
4. Invalid webhook signature leaves payment unchanged.
5. Manual **Record payment** still works as fallback.

## Verification checklist

- [ ] `create-checkout` returns `checkout_url` for owner/admin JWT
- [ ] `payments-status` shows ready + correct label
- [ ] Portal **Pay now** returns Checkout URL when Stripe configured
- [ ] Test card → webhook → invoice `paid`
- [ ] Invalid webhook signature does not change payment rows
- [ ] Flutter binary contains no Stripe secret keys
- [ ] Manual “Record payment” creates `manual` payment + marks invoice paid

## Related docs

- [environments.md](environments.md) — Supabase URL and publishable key per environment
- [portal.md](portal.md) — customer magic links
- `../hvac_client/docs/db/payments.md` — schema + webhook details
