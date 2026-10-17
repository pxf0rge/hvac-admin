# Phase 19 — Document Template Library

## Goal
Upload, create, and manage reusable document templates that technicians fill and sign in the field app.

## Constraints
- Templates stored in `document_templates` + `document_template_versions` (see `../hvac_client/docs/db/document-generation.md`).
- Admin manages templates; technician app consumes them — do not duplicate template storage.
- Templates auto-populate: customer, address, job number, technician, date, equipment, company info.
- Updating a template must not require rebuilding either app.
- Customer-facing documents default to professional English.

## What to do (execution checklist)
1. Template list: name, type, version, last updated, active/inactive.
2. Template editor or upload (HTML/PDF field mapping).
3. Preview with sample data.
4. Version history; publish new version without breaking in-progress jobs.
5. Seed templates: Service Authorization, Diagnostic Consent, Service Completion, Installation Agreement, etc.

## Verification
1. Create template in admin → technician can select it on a job.
2. Signed document saved under Customer → Property → Job → Documents.
3. Template update creates new version; old signed docs unchanged.

## Stop condition
Template library is manageable from admin and consumable by field app.
