# Accounting export (Phase 14)

Management can export invoice/payment data as CSV for bookkeeping tools. Arctic HVAC Solutions is **not** a general ledger.

> **Phase 22 tax model:** invoices carry an optional invoice-level `tax_rate_pct` (percentage applied to the line-item subtotal). `tax_amount` in this CSV is the derived tax; grand total due = `amount + tax_amount`. Stripe/portal checkout charges the tax-inclusive total.

## Where

**Reports** → **Export for accounting** (owner/admin only; same gate as financial KPIs).

- Filter by invoice **issued** date range
- Downloads `hvac_accounting_YYYY-MM-DD_YYYY-MM-DD.csv` on web; otherwise copies CSV to clipboard
- Empty range → clear error (no file)
- Each export writes audit action `accounting.export`

## CSV columns

| Column | Notes |
|--------|--------|
| `invoice_number` | Human invoice number |
| `invoice_id` | UUID |
| `customer_id` / `customer_name` | From property → customer |
| `property_address` | Full address |
| `job_id` | Linked job UUID |
| `issued_on` / `due_on` | ISO dates |
| `amount` / `currency` | Pre-tax line-item subtotal; currency is `usd` |
| `tax_amount` | Phase 22: invoice-level tax (`amount × tax_rate_pct/100`, rounded to cents). `0.00` for tax-free/legacy invoices |
| `invoice_status` | draft / sent / overdue / paid / cancelled |
| `payment_status` | paid / partial / unpaid / void |
| `payment_provider` | Succeeded providers joined with `\|` |
| `payment_amount_total` | Sum of succeeded payments |
| `payment_paid_at` | Latest paid date |
| `payment_ids` | Succeeded payment UUIDs joined with `\|` |

Provider interface: `AccountingExportProvider` (`LocalAccountingCsvProvider` default; `QuickBooksAccountingExportStub` for future OAuth).

## QuickBooks Online (manual import)

1. Export CSV from Reports.
2. In QBO: **Sales → Invoices → Import** (or **Banking / Upload** depending on plan) — or use **Gear → Import Data → Invoices** if available.
3. Map columns approximately:

| Arctic HVAC Solutions | QuickBooks |
|----------|------------|
| `invoice_number` | Invoice no. |
| `customer_name` | Customer |
| `issued_on` | Invoice date |
| `due_on` | Due date |
| `amount` | Amount / Total |
| `invoice_status` / `payment_status` | Use to decide open vs paid after import |

4. Create customers in QBO first when names must match exactly; keep `customer_id` as an external reference in a custom field if needed.
5. Payments: import deposits separately using `payment_amount_total` / `payment_provider`, or mark invoices paid in QBO after bank match.

Tax: Phase 22 invoices carry `tax_rate_pct`; `tax_amount` is now the real derived tax (`0.00` only for tax-free/legacy invoices). Set/override sales tax in QBO only when jurisdiction rules differ.

## Xero (manual import)

1. Export CSV from Reports.
2. Xero: **Business → Invoices → Import** (or **Accounting → Reports** tools / CSV import for sales invoices).
3. Map:

| Arctic HVAC Solutions | Xero |
|----------|------|
| `invoice_number` | InvoiceNumber |
| `customer_name` | ContactName |
| `issued_on` | InvoiceDate |
| `due_on` | DueDate |
| `amount` | UnitAmount / Total (may need a single line description e.g. “HVAC services”) |
| `currency` | Currency (`USD`) |

4. Contacts: create or match by name before import; store `customer_id` in a tracking/reference field.
5. Paid invoices: either import as paid with payment date `payment_paid_at`, or import unpaid and reconcile bank feed.

## Future automation

- Implement a real `AccountingExportProvider` with vendor OAuth (QuickBooks/Xero) — do **not** put client secrets in Flutter.
- Prefer Edge Function for token exchange and push of invoices/payments.
- Keep CSV export as the fallback forever.

## Related

- Audit log: Settings → Audit (`accounting.export`)
- Payments / Stripe: [payments.md](payments.md)
