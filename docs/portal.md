# Customer portal (Phase 12)

Magic links for estimates, invoices, and documents — no office login.

## URLs

| Resource | Path |
|---|---|
| Estimate | `{PORTAL_BASE_URL}/e/{token}` |
| Invoice | `{PORTAL_BASE_URL}/i/{token}` |
| Document | `{PORTAL_BASE_URL}/d/{token}` |

Build with:

```bash
flutter run -d chrome --dart-define=PORTAL_BASE_URL=https://office.yourdomain.com
```

Dev default (if unset): `http://localhost:8080`

## Tokens

- Minted by office via RPC `create_customer_access_token` (raw token returned once; DB stores SHA-256 hash)
- Resolved by anon RPC `resolve_customer_access_token`
- Default TTL: 720 hours (30 days)
- Document links are single-use (`used_at`)

## Ops

1. Apply migration `20260906270000_hvac_customer_portal_tokens.sql`
2. Host admin Flutter web and set `PORTAL_BASE_URL` to that origin
3. Send estimate/invoice from detail pages — Communication templates receive real URLs
4. Invalid/expired tokens show a safe error (no data leak)

## Invoice pay (Phase 13)

Unpaid invoice portal pages show **Pay now**, which calls Edge Function `portal-pay` with the magic-link token (no office login). Stripe Checkout URL is returned when `STRIPE_SECRET_KEY` and redirect URLs are configured. Until then, the button surfaces a clear “not configured / contact office” error.

Payment redirects land on `{PORTAL_BASE_URL}/payments/success` and `/payments/cancel`.
