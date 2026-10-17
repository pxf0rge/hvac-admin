# Phase 25 — Real Inventory

## Goal
Inventory management for HVAC equipment and parts across warehouse, trucks, and devices.

## Constraints
- Stock lives on `inventory_locations` (warehouse, truck, device) — not on technician record.
- Movements recorded in `stock_movements` ledger.
- Technicians do not manage inventory; admin/office staff do.
- See `../hvac_client/docs/db/inventory.md`.

## What to do (execution checklist)
1. Inventory item list: SKU, name, category, total qty, reorder level.
2. Item detail: stock by location (warehouse/truck/device), movement history.
3. Create/edit items and locations.
4. Stock adjustment and transfer between locations.
5. Low-stock alerts on dashboard (optional).
6. Link parts used to jobs (consumption movement).

## Verification
1. Add part → stock appears at warehouse.
2. Transfer to truck → quantities update at both locations.
3. Job part usage decrements truck stock.

## Stop condition
Inventory module is production-backed with movement ledger.
