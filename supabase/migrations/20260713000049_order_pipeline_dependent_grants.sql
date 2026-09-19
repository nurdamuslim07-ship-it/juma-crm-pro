-- Found while running real end-to-end verification of the order
-- creation fix (20260713000048): even with that migration applied,
-- a real INSERT INTO orders (with Prefer: return=representation,
-- exactly what the Flutter client and PostgREST both do on every
-- insert) still failed with:
--   permission denied for table order_assignments
-- `orders_select_assigned` (one of the three OR'd SELECT policies on
-- `orders`) contains an `EXISTS (select 1 from order_assignments ...)`
-- subquery. Postgres checks table-level privileges on every table
-- referenced anywhere in a policy expression at query-rewrite time,
-- regardless of whether that OR branch would ultimately match — so
-- the post-insert SELECT is blocked even for roles that already
-- qualify via `orders_select_broad`/`orders_select_financial`.
--
-- This is the exact same root defect already fixed piecemeal for
-- other tables this session (20260713000043/44/46/47/48): every
-- table in this project was created by the `postgres` role, which
-- never receives the baseline grants `authenticated` needs — these
-- tables were simply not among the ones reached yet. A full
-- schema-wide sweep remains separate, deferred work (tracked in
-- PRODUCTION_BLOCKERS_RESOLVED.md); this migration only grants what
-- is required for the specific pipeline named in this fix's own
-- requirements (order history, production module, payments, audit
-- log) to actually complete a real end-to-end order-creation test,
-- scoped to exactly what each table's own existing RLS policies
-- already declare — no policy is changed, no new access is created.
grant select, insert, update, delete on order_assignments to authenticated;
grant select, insert, update, delete on order_production_progress to authenticated;
grant select, insert on production_stage_history to authenticated;
grant select, insert, update, delete on payments to authenticated;
grant select, insert on audit_logs to authenticated;
grant select, insert, update, delete on production_stages to authenticated;
