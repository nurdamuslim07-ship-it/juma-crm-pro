-- pgTAP tests proving Stage 1d's claim: every SECURITY DEFINER RPC is
-- now company-scoped, not just table-level RLS (which
-- multi_tenant_company_isolation_rls_test.sql already covers for the
-- tables a client can query directly). Run with `supabase test db` —
-- like the rest of this schema, this has NOT been executed against a
-- live database in this environment (no Postgres/Supabase CLI
-- available — see supabase/README.md).
--
-- This is representative, not exhaustive, coverage: 1-3 assertions per
-- RPC-gated module (employees, partners, production, analytics,
-- warehouse, purchases), enough to prove the company-scoping pattern
-- holds everywhere it was applied, mirroring how e.g.
-- purchases_rls_test.sql covers the full role matrix for ONE company
-- — this file's job is specifically the cross-company dimension.
--
-- Fixture data for every table EXCEPT `orders` is inserted here, as
-- the test session's own (superuser/table-owner) role — i.e. BEFORE
-- `set local role authenticated` below — for two reasons: (1)
-- `partners`/`employees` have ALL direct grants revoked from
-- `authenticated` (see 20260713000017/18's own header comments), so a
-- client-role insert would fail outright regardless of RLS, same
-- reason partners_rls_test.sql/employees_rls_test.sql seed those two
-- tables before switching role; (2) the superuser/owner bypasses RLS
-- entirely, so every other table's `with check (company_id =
-- auth_company_id())` insert policy is moot here — company_id is set
-- explicitly on each row regardless. `orders` is the one exception:
-- its `enforce_order_status_change` trigger calls
-- `auth_can_set_order_status()`, which resolves `auth.uid()` from the
-- session's JWT claims — it must be inserted AFTER switching to each
-- director's own authenticated context, same reason
-- production_rls_test.sql's own order fixtures are inserted as the
-- director rather than as the migration-running superuser.

begin;
select plan(25);

-- ---------- fixtures (not orders): Company A + Company B ----------
insert into companies (id, name, country) values
  ('aaaaaaaa-0000-0000-0000-000000000001', 'Company A', 'Kazakhstan'),
  ('bbbbbbbb-0000-0000-0000-000000000002', 'Company B', 'Kazakhstan');

insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'director-a@test.local'),
  ('22222222-2222-2222-2222-222222222222', 'director-b@test.local');
-- profiles rows are created automatically by handle_new_auth_user().

-- 20260713000036 made company_id/status unwritable outside the
-- onboarding RPCs' own transaction-local bypass flag — fixture setup
-- needs it too, same as any of those RPCs would.
select set_config('app.bypass_profile_guard', 'on', true);

update profiles set company_id = 'aaaaaaaa-0000-0000-0000-000000000001', status = 'active'
  where id = '11111111-1111-1111-1111-111111111111';
update profiles set company_id = 'bbbbbbbb-0000-0000-0000-000000000002', status = 'active'
  where id = '22222222-2222-2222-2222-222222222222';

insert into user_roles (profile_id, role_id) values
  ('11111111-1111-1111-1111-111111111111', (select id from roles where key = 'director')),
  ('22222222-2222-2222-2222-222222222222', (select id from roles where key = 'director'));

insert into employees (id, company_id, user_id, email, salary_type) values
  ('e1111111-0000-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'director-a@test.local', 'fixed'),
  ('e2222222-0000-0000-0000-000000000002', 'bbbbbbbb-0000-0000-0000-000000000002', '22222222-2222-2222-2222-222222222222', 'director-b@test.local', 'fixed');

insert into partners (id, company_id, display_name, category, is_active) values
  ('p1111111-0000-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0000-000000000001', 'Partner A', 'ldsp', true),
  ('p2222222-0000-0000-0000-000000000002', 'bbbbbbbb-0000-0000-0000-000000000002', 'Partner B', 'ldsp', true);

insert into clients (id, company_id, name, phone) values
  ('c1111111-0000-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0000-000000000001', 'Client A', '+77010000001'),
  ('c2222222-0000-0000-0000-000000000002', 'bbbbbbbb-0000-0000-0000-000000000002', 'Client B', '+77010000002');

insert into material_categories (id, company_id, key, name_kk) values
  ('m1111111-0000-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0000-000000000001', 'category-a', 'Category A'),
  ('m2222222-0000-0000-0000-000000000002', 'bbbbbbbb-0000-0000-0000-000000000002', 'category-b', 'Category B');

insert into materials (id, company_id, name, category_id, unit) values
  ('t1111111-0000-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0000-000000000001', 'Material A', 'm1111111-0000-0000-0000-000000000001', 'дана'),
  ('t2222222-0000-0000-0000-000000000002', 'bbbbbbbb-0000-0000-0000-000000000002', 'Material B', 'm2222222-0000-0000-0000-000000000002', 'дана');

insert into warehouses (id, company_id, name) values
  ('w1111111-0000-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0000-000000000001', 'Warehouse A');

insert into warehouse_locations (id, company_id, warehouse_id, name) values
  ('l1111111-0000-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0000-000000000001', 'w1111111-0000-0000-0000-000000000001', 'Location A');

insert into purchase_orders (id, company_id, order_number, supplier_partner_id, status) values
  ('o1111111-0000-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0000-000000000001', 'PO-A-0001', 'p1111111-0000-0000-0000-000000000001', 'draft'),
  ('o2222222-0000-0000-0000-000000000002', 'bbbbbbbb-0000-0000-0000-000000000002', 'PO-B-0001', 'p2222222-0000-0000-0000-000000000002', 'draft');

-- ---------- fixtures: orders (must be inserted per-director — see header) ----------
set local role authenticated;
set local "request.jwt.claims" to '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}';

insert into orders (id, company_id, order_number, client_id, product_type, status, total_amount_tiyn)
values ('d1111111-0000-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0000-000000000001', 'JU-A-0001', 'c1111111-0000-0000-0000-000000000001', 'Шкаф', 'in_progress', 100000000);

set local "request.jwt.claims" to '{"sub": "22222222-2222-2222-2222-222222222222", "role": "authenticated"}';

insert into orders (id, company_id, order_number, client_id, product_type, status, total_amount_tiyn)
values ('d2222222-0000-0000-0000-000000000002', 'bbbbbbbb-0000-0000-0000-000000000002', 'JU-B-0001', 'c2222222-0000-0000-0000-000000000002', 'Үстел', 'in_progress', 50000000);

-- ---------- as Director A ----------
set local "request.jwt.claims" to '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}';

-- Employees
select is(
  (select count(*)::int from get_employees()),
  1,
  'requirement: get_employees() returns exactly Company A''s own employee'
);

select is(
  (select count(*)::int from get_employees(p_user_id => '22222222-2222-2222-2222-222222222222')),
  0,
  'requirement: get_employees(p_user_id) for Company B''s user returns nothing to Director A'
);

select throws_ok(
  $$select update_employee('22222222-2222-2222-2222-222222222222', 'Hijack', '+77010000000', 'director')$$,
  'P0002',
  null,
  'requirement: update_employee() cannot touch Company B''s employee'
);

-- Partners
select is(
  (select count(*)::int from get_partners()),
  1,
  'requirement: get_partners() returns exactly Company A''s own partner'
);

select throws_ok(
  $$select update_partner('p2222222-0000-0000-0000-000000000002', 'Hijack', 'ldsp')$$,
  'P0002',
  null,
  'requirement: update_partner() cannot touch Company B''s partner'
);

select throws_ok(
  $$select update_partner_financials('p2222222-0000-0000-0000-000000000002', 'hacked bank details', 999999999)$$,
  'P0002',
  null,
  'requirement: update_partner_financials() cannot touch Company B''s partner'
);

-- Analytics — turnover must reflect only Company A's own order total
-- (100000000 tiyn), never Company B's (50000000 tiyn) or the combined sum.
select is(
  (select turnover_tiyn from get_analytics_summary(current_date - 30, current_date + 1)),
  100000000::bigint,
  'requirement: get_analytics_summary() turnover is scoped to Company A''s own orders only'
);

select is(
  (select count(*)::int from get_top_clients(current_date - 30, current_date + 1)),
  1,
  'requirement: get_top_clients() returns exactly Company A''s own client'
);

-- Production
select is(
  (select count(*)::int from get_production_queue()),
  1,
  'requirement: get_production_queue() returns exactly Company A''s own order'
);

-- Director A holds v_scope_all (director), so the assignment check is
-- skipped entirely and the company filter in the main query is what
-- must do the work here — same "empty, not an exception" shape as the
-- original (pre-multi-tenant) function already had for a non-existent
-- order id.
select is(
  (select count(*)::int from get_order_production_detail('d2222222-0000-0000-0000-000000000002')),
  0,
  'requirement: get_order_production_detail() returns nothing for Company B''s order'
);

select throws_ok(
  $$select set_order_master('d2222222-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111')$$,
  'P0002',
  null,
  'requirement: set_order_master() cannot target Company B''s order'
);

-- Warehouse
select is(
  (select count(*)::int from get_materials()),
  1,
  'requirement: get_materials() returns exactly Company A''s own material'
);

select is(
  get_material_id_by_barcode('no-such-barcode'),
  null,
  'sanity: get_material_id_by_barcode() with no match returns null (not an error)'
);

select throws_ok(
  $$select receive_materials('t2222222-0000-0000-0000-000000000002', 'l1111111-0000-0000-0000-000000000001', 5)$$,
  'P0002',
  null,
  'requirement: receive_materials() cannot receive Company B''s material'
);

select throws_ok(
  $$select reserve_material_for_order('d1111111-0000-0000-0000-000000000001', 't2222222-0000-0000-0000-000000000002', 1)$$,
  'P0002',
  null,
  'requirement: reserve_material_for_order() cannot reserve Company B''s material for Company A''s own order'
);

-- Purchases
select is(
  (select count(*)::int from get_purchase_orders()),
  1,
  'requirement: get_purchase_orders() returns exactly Company A''s own PO'
);

select throws_ok(
  $$select get_purchase_order_detail('o2222222-0000-0000-0000-000000000002')$$,
  'P0002',
  null,
  'requirement: get_purchase_order_detail() cannot fetch Company B''s PO'
);

select throws_ok(
  $$select create_purchase_order('PO-A-0002', 'p2222222-0000-0000-0000-000000000002', '[]'::jsonb)$$,
  'P0002',
  null,
  'requirement: create_purchase_order() cannot use Company B''s supplier partner'
);

-- p_method_id is null here deliberately — the partner check this test
-- targets runs (and must fail) before the function ever touches it.
select throws_ok(
  $$select record_supplier_payment('idem-a-1', 'p2222222-0000-0000-0000-000000000002', 1000, null)$$,
  'P0002',
  null,
  'requirement: record_supplier_payment() cannot pay against Company B''s partner'
);

-- ---------- as Director B ----------
set local "request.jwt.claims" to '{"sub": "22222222-2222-2222-2222-222222222222", "role": "authenticated"}';

select is(
  (select count(*)::int from get_employees()),
  1,
  'requirement: get_employees() returns exactly Company B''s own employee'
);

select is(
  (select count(*)::int from get_partners()),
  1,
  'requirement: get_partners() returns exactly Company B''s own partner'
);

select is(
  (select turnover_tiyn from get_analytics_summary(current_date - 30, current_date + 1)),
  50000000::bigint,
  'requirement: get_analytics_summary() turnover is scoped to Company B''s own orders only'
);

select is(
  (select count(*)::int from get_production_queue()),
  1,
  'requirement: get_production_queue() returns exactly Company B''s own order'
);

select is(
  (select count(*)::int from get_materials()),
  1,
  'requirement: get_materials() returns exactly Company B''s own material'
);

select is(
  (select count(*)::int from get_purchase_orders()),
  1,
  'requirement: get_purchase_orders() returns exactly Company B''s own PO'
);

select * from finish();
rollback;
