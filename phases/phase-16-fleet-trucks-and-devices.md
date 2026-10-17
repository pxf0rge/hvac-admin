# Phase 16 — Fleet (Trucks + Devices)

## Goal
Manage trucks and devices as separate entities from employees, enabling reassignment without changing employee records.

## Constraints
- Entity chain: Employee → Truck → Device → Jobs.
- Inventory stock can live on warehouse, truck, or device.
- Reassigning truck/device must not require editing the employee record.

## What to do (execution checklist)
1. Truck list: name/plate, assigned technician, status.
2. Device list: type (phone/tablet), assigned truck or technician, last seen.
3. Create/edit truck and device records.
4. Assign/reassign truck to technician; device to truck.
5. Fleet overview on technician detail page.

## Verification
1. Reassign truck from Tech A to Tech B → inventory location follows truck (if applicable).
2. Device record tracks assignment history.
3. Fleet page shows current assignments accurately.

## Stop condition
Fleet module is production-backed; ready for GPS in Phase 17.
