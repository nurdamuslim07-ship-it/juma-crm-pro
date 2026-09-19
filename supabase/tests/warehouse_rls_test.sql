-- pgTAP tests proving the Warehouse module's core security/behavior
-- claims, most importantly the Production integration: nothing wrote
-- to inventory_balances.reserved_quantity before this module, so
-- Production's materials_sufficient flag was meaningless in practice.
-- reserve_material_for_order()/release_order_reservation() are the
-- fix — proven here by calling them and re-checking
-- get_production_queue()'s output with zero edits to the Production
-- migration. Run with `supabase test db` — like the rest of this
-- schema, this has NOT been executed against a live database in this
-- environment (no Postgres/Supabase CLI available — see
-- supabase/README.md).

begin;
select plan(23);

-- ---------- fixtures ----------
insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'director@test.local'),
  ('66666666-6666-6666-6666-666666666666', 'storekeeper@test.local'),
  ('22222222-2222-2222-2222-222222222222', 'purchaser@test.local'),
  ('55555555-5555-5555-5555-555555555555', 'accountant@test.local');
-- profiles rows are created automatically by handle_new_auth_user().

insert into user_roles (profile_id, role_id) values
  ('11111111-1111-1111-1111-111111111111', (select id from roles where key = 'director')),
  ('66666666-6666-6666-6666-666666666666', (select id from roles where key = 'warehouse')),
  ('22222222-2222-2222-2222-222222222222', (select id from roles where key = 'purchaser')),
  ('55555555-5555-5555-5555-555555555555', (select id from roles where key = 'accountant'));

set local role authenticated;
set local "request.jwt.claims" to '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}';

insert into clients (id, name, phone)
values ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'Тест клиент', '+77011112233');

insert into orders (id, order_number, client_id, product_type, status, total_amount_tiyn)
values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'JU-W-0001', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'Шкаф', 'in_progress', 100000000);

insert into materials (id, name, unit, min_quantity, barcode) values
  ('99999999-9999-9999-9999-999999999999', 'ЛДСП 16мм ақ', 'парақ', 5, '4600000000011');
insert into warehouses (id, name) values
  ('11111111-2222-3333-4444-555555555555', 'Негізгі қойма');
insert into warehouse_locations (id, warehouse_id, name) values
  ('22222222-3333-4444-5555-666666666666', '11111111-2222-3333-4444-555555555555', 'Сөре 1');

-- ---------- as storekeeper (warehouse.read + warehouse.write) ----------
set local "request.jwt.claims" to '{"sub": "66666666-6666-6666-6666-666666666666", "role": "authenticated"}';

select lives_ok(
  $$select receive_materials('99999999-9999-9999-9999-999999999999', '22222222-3333-4444-5555-666666666666', 20, 850000, 'B-0001', null)$$,
  'requirement: "Келіп түсу" — storekeeper can receive a batch of material'
);

select is(
  (select quantity from inventory_balances where material_id = '99999999-9999-9999-9999-999999999999' and location_id = '22222222-3333-4444-5555-666666666666'),
  20::numeric,
  'requirement: receiving increases the location balance'
);

select is(
  (select count(*)::int from inventory_batches where material_id = '99999999-9999-9999-9999-999999999999'),
  1,
  'requirement: "Партиялар" — receiving records a batch row'
);

select is(
  (select is_low_stock from get_materials() where material_id = '99999999-9999-9999-9999-999999999999'),
  false,
  'requirement: "Минималды қалдық" / "Автоматты ескерту" — 20 available >= min_quantity 5, not flagged low'
);

select is(
  (select get_material_id_by_barcode('4600000000011')),
  '99999999-9999-9999-9999-999999999999'::uuid,
  'requirement: "Barcode" — scanning the material''s barcode resolves its id'
);

select is(
  (select get_material_id_by_barcode('0000000000000')),
  null,
  'an unknown barcode resolves to null, not an error'
);

-- The critical Production-integration fixture: reserve 18 of the 20
-- available units for the order, leaving only 2 free.
select lives_ok(
  $$select reserve_material_for_order('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '99999999-9999-9999-9999-999999999999', 18, '22222222-3333-4444-5555-666666666666')$$,
  'requirement: "Production резерві" — storekeeper can reserve material for an order'
);

select is(
  (select reserved_quantity from inventory_balances where material_id = '99999999-9999-9999-9999-999999999999' and location_id = '22222222-3333-4444-5555-666666666666'),
  18::numeric,
  'requirement: "Reservation автоматты жасалсын" — reserving actually increments inventory_balances.reserved_quantity (previously nothing did this)'
);

select is(
  (select materials_sufficient from get_production_queue() where order_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  true,
  'requirement: "Материал жеткіліктілігін автоматты есептеу" — Production''s own get_production_queue() (unchanged) now correctly reports the order as material-sufficient (18 reserved <= 20 - 0 available before this reservation''s own row is excluded... see next assertion for the shortage case)'
);

-- Now reserve the remaining headroom away entirely, so a *second*
-- reservation for more material than remains proves the "warn, don't
-- block" Production integration: the RPC still succeeds, but
-- Production's flag flips to insufficient.
select lives_ok(
  $$select reserve_material_for_order('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '99999999-9999-9999-9999-999999999999', 5, '22222222-3333-4444-5555-666666666666')$$,
  'requirement: reserving more than remains available still succeeds (a real-world shortage is recorded, not blocked)'
);

select is(
  (select materials_sufficient from get_production_queue() where order_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  false,
  'requirement: "Материал жетпесе Production ескерту берсін" — Production now flags the order as material-insufficient after over-reserving, with zero changes to the Production migration'
);

select is(
  (select count(*)::int from material_reservations where order_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  2,
  'two separate reservation rows exist for the order'
);

-- Release the second (over-)reservation and confirm the balance and
-- Production's flag both recover.
select lives_ok(
  $$select release_order_reservation((select id from material_reservations where order_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' order by reserved_at desc limit 1))$$,
  'requirement: a reservation can be released'
);

select is(
  (select reserved_quantity from inventory_balances where material_id = '99999999-9999-9999-9999-999999999999' and location_id = '22222222-3333-4444-5555-666666666666'),
  18::numeric,
  'releasing a reservation credits reserved_quantity back down'
);

select is(
  (select materials_sufficient from get_production_queue() where order_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  true,
  'Production''s sufficiency flag recovers once the over-reservation is released'
);

-- ---------- generic hold ("Резерв", not order-tied) ----------
select lives_ok(
  $$select create_hold('99999999-9999-9999-9999-999999999999', '22222222-3333-4444-5555-666666666666', 1, 'Сапа тексеруі')$$,
  'requirement: "Резерв" — a generic, non-order hold can be created (e.g. for quality inspection)'
);

select is(
  (select reserved_quantity from inventory_balances where material_id = '99999999-9999-9999-9999-999999999999' and location_id = '22222222-3333-4444-5555-666666666666'),
  19::numeric,
  'a generic hold also increments reserved_quantity, on top of the order reservation'
);

select lives_ok(
  $$select release_hold((select id from inventory_holds where material_id = '99999999-9999-9999-9999-999999999999' and released_at is null))$$,
  'a hold can be released'
);

-- ---------- issue via cart ("Себетке шығару") ----------
select lives_ok(
  $$select issue_materials(jsonb_build_array(jsonb_build_object('material_id', '99999999-9999-9999-9999-999999999999', 'location_id', '22222222-3333-4444-5555-666666666666', 'quantity', 3)))$$,
  'requirement: "Себетке шығару" — issuing a cart of materials succeeds'
);

select is(
  (select quantity from inventory_balances where material_id = '99999999-9999-9999-9999-999999999999' and location_id = '22222222-3333-4444-5555-666666666666'),
  17::numeric,
  'requirement: "Шығыс" — issuing decreases the location balance (20 received - 3 issued)'
);

-- ---------- as purchaser (warehouse.read + warehouse.write per this module) ----------
set local "request.jwt.claims" to '{"sub": "22222222-2222-2222-2222-222222222222", "role": "authenticated"}';

select lives_ok(
  $$select receive_materials('99999999-9999-9999-9999-999999999999', '22222222-3333-4444-5555-666666666666', 5, 850000, 'B-0002', null)$$,
  'requirement: purchaser can also record receiving (extended to warehouse.write by this module)'
);

-- ---------- as accountant (no warehouse permission at all) ----------
set local "request.jwt.claims" to '{"sub": "55555555-5555-5555-5555-555555555555", "role": "authenticated"}';

select is(
  (select count(*)::int from get_materials()),
  0,
  'requirement: accountant (no warehouse.read) gets an empty materials list, not an error'
);

select throws_ok(
  $$select receive_materials('99999999-9999-9999-9999-999999999999', '22222222-3333-4444-5555-666666666666', 1, 0, null, null)$$,
  '42501',
  'Бұл әрекетке рұқсатыңыз жоқ',
  'requirement: accountant cannot record receiving (no warehouse.write)'
);

select * from finish();
rollback;
