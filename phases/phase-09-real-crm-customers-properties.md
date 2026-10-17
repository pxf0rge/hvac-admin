# Phase 09 — Real CRM (Customers + Properties)

## Goal
Full customer and property management backed by Supabase — the foundation of the property-centric data model.

## Constraints
- Customer → Property is the core chain (see `../hvac_client/docs/db/architecture.md`).
- A customer may have multiple properties/addresses.
- CRUD must respect RLS; office_staff can manage CRM, technicians cannot access this app.

## What to do (execution checklist)
1. Customer list with search, create, edit, archive.
2. Customer detail: contact info (name, phone, email), linked properties.
3. Property list and create/edit (address, notes, access instructions).
4. Link property to customer; support multiple properties per customer.
5. `CustomerController` + `CustomerRepository` wired to Supabase.
6. Pagination on list screens.

## Verification
1. Create customer + property in admin → visible in Supabase and (when wired) technician job context.
2. Edit contact info persists.
3. Search finds customer by name, phone, or address.

## Stop condition
CRM CRUD is production-backed; ready for property history in Phase 10.
