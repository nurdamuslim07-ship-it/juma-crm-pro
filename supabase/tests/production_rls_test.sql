-- pgTAP tests proving the Production module's core security claims:
-- master/other non-broad roles only ever see orders they're assigned
-- to (never the whole shop floor), moving a card and starting a time
-- log require production.write, reassigning the responsible master is
-- director/workshop_manager only, and materials_sufficient correctly
-- reflects reservation vs. available stock. Run with `supabase test
-- db` — like the rest of this schema, this has NOT been executed
-- against a live database in this environment (no Postgres/Supabase
-- CLI available — see supabase/README.md).

begin;
select plan(20);

-- ---------- fixtures ----------
insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'director@test.local'),
  ('44444444-4444-4444-4444-444444444444', 'workshopmgr@test.local'),
  ('77777777-7777-7777-7777-777777777777', 'master1@test.local'),
  ('88888888-8888-8888-8888-888888888888', 'master2@test.local'),
  ('55555555-5555-5555-5555-555555555555', 'accountant@test.local'),
  ('33333333-3333-3333-3333-333333333333', 'manager@test.local');
-- profiles rows are created automatically by handle_new_auth_user().

insert into user_roles (profile_id, role_id) values
  ('11111111-1111-1111-1111-111111111111', (select id from roles where key = 'director')),
  ('44444444-4444-4444-4444-444444444444', (select id from roles where key = 'workshop_manager')),
  ('77777777-7777-7777-7777-777777777777', (select id from roles where key = 'master')),
  ('88888888-8888-8888-8888-888888888888', (select id from roles where key = 'master')),
  ('55555555-5555-5555-5555-555555555555', (select id from roles where key = 'accountant')),
  ('33333333-3333-3333-3333-333333333333', (select id from roles where key = 'manager'));

-- Fixture data is created as the director — the
-- orders_status_transition_guard trigger requires
-- auth_can_set_order_status('in_progress'), which order_assignments
-- inserts (orders.write) and warehouse rows (warehouse.write) also
-- need director's bulk-granted permissions.
set local role authenticated;
set local "request.jwt.claims" to '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}';

insert into clients (id, name, phone)
values ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'Тест клиент', '+77011112233');

insert into orders (id, order_number, client_id, product_type, status, total_amount_tiyn)
values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'JU-P-0001', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'Шкаф', 'in_progress', 100000000),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'JU-P-0002', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'Үстел', 'in_progress', 50000000);

insert into order_assignments (order_id, profile_id, role) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '77777777-7777-7777-7777-777777777777', 'master'),
  ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '88888888-8888-8888-8888-888888888888', 'master');

insert into materials (id, name, unit) values
  ('99999999-9999-9999-9999-999999999999', 'ЛДСП 16мм', 'парақ');
insert into warehouses (id, name) values
  ('11111111-2222-3333-4444-555555555555', 'Негізгі қойма');
insert into warehouse_locations (id, warehouse_id, name) values
  ('22222222-3333-4444-5555-666666666666', '11111111-2222-3333-4444-555555555555', 'Сөре 1');
-- Only 5 units available, but the order below reserves 10 — deliberately insufficient.
insert into inventory_balances (material_id, location_id, quantity, reserved_quantity) values
  ('99999999-9999-9999-9999-999999999999', '22222222-3333-4444-5555-666666666666', 5, 0);
insert into material_reservations (order_id, material_id, quantity) values
  ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '99999999-9999-9999-9999-999999999999', 10);

-- ---------- as master1 (assigned only to order A) ----------
set local "request.jwt.claims" to '{"sub": "77777777-7777-7777-7777-777777777777", "role": "authenticated"}';

select is(
  (select count(*)::int from get_production_queue()),
  1,
  'requirement: master1 sees only their assigned order, never the whole shop floor'
);

select is(
  (select order_id from get_production_queue() limit 1),
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  'requirement: the one visible order is master1''s assigned order A'
);

select is(
  (select materials_sufficient from get_production_queue() where order_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  false,
  'requirement: "Материал жеткіліктілігін көрсету" — order A is correctly flagged as material-insufficient (needs 10, only 5 available)'
);

select lives_ok(
  $$select * from get_order_production_detail('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa')$$,
  'master1 can fetch production detail for their own assigned order'
);

select throws_ok(
  $$select * from get_order_production_detail('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb')$$,
  '42501',
  'Бұл әрекетке рұқсатыңыз жоқ',
  'requirement: master1 cannot fetch detail for an order they are not assigned to'
);

select lives_ok(
  $$select move_order_to_stage('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', (select id from production_stages where key = 'cutting'))$$,
  'requirement: "Drag & Drop Kanban" — master1 (production.write) can move their assigned order to a new stage'
);

select is(
  (select percent_complete from get_production_queue() where order_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  15::smallint,
  'percent_complete is auto-synced to the new stage''s default_percent by the trigger'
);

select throws_ok(
  $$select set_order_master('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '88888888-8888-8888-8888-888888888888')$$,
  '42501',
  'Бұл әрекетке рұқсатыңыз жоқ',
  'requirement: a plain master cannot reassign the responsible master (director/workshop_manager only)'
);

select lives_ok(
  $$select start_time_log('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', (select id from production_stages where key = 'cutting'))$$,
  'requirement: "Уақыт журналдары" — master1 can start a time log for their own work'
);

select throws_ok(
  $$select start_time_log('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', null)$$,
  '23514',
  null,
  'requirement: master1 cannot start a second concurrent time log'
);

-- ---------- as master2 (not assigned to order A) ----------
set local "request.jwt.claims" to '{"sub": "88888888-8888-8888-8888-888888888888", "role": "authenticated"}';

select throws_ok(
  $$select stop_time_log((select id from production_time_logs where employee_id = '77777777-7777-7777-7777-777777777777' and ended_at is null))$$,
  'P0002',
  null,
  'requirement: master2 cannot stop master1''s open time log'
);

-- ---------- as workshop_manager (sees everything) ----------
set local "request.jwt.claims" to '{"sub": "44444444-4444-4444-4444-444444444444", "role": "authenticated"}';

select is(
  (select count(*)::int from get_production_queue()),
  2,
  'requirement: workshop_manager sees every order in production, not just assigned ones'
);

select lives_ok(
  $$select set_order_master('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '88888888-8888-8888-8888-888888888888')$$,
  'requirement: workshop_manager can reassign the responsible master'
);

-- ---------- as manager ("көру және жоспарлау" — view + planning) ----------
set local "request.jwt.claims" to '{"sub": "33333333-3333-3333-3333-333333333333", "role": "authenticated"}';

select is(
  (select count(*)::int from get_production_queue()),
  2,
  'requirement: manager ("көру") sees every order in production, same broad scope as workshop_manager/director'
);

select throws_ok(
  $$select move_order_to_stage('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', (select id from production_stages where key = 'painting'))$$,
  '42501',
  'Бұл әрекетке рұқсатыңыз жоқ',
  'requirement: manager cannot move a Kanban card — planning, not day-to-day execution (no production.write)'
);

select lives_ok(
  $$select set_order_master('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '77777777-7777-7777-7777-777777777777')$$,
  'requirement: manager ("жоспарлау") can reassign the responsible master'
);

select is(
  (select count(*)::int from get_masters()),
  2,
  'requirement: manager (can assign a master) sees the master picker list'
);

-- ---------- as accountant (no production permission at all) ----------
set local "request.jwt.claims" to '{"sub": "55555555-5555-5555-5555-555555555555", "role": "authenticated"}';

select is(
  (select count(*)::int from get_production_queue()),
  0,
  'requirement: accountant (no production.read) gets an empty queue, not an error'
);

select throws_ok(
  $$select move_order_to_stage('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', (select id from production_stages where key = 'painting'))$$,
  '42501',
  'Бұл әрекетке рұқсатыңыз жоқ',
  'requirement: accountant cannot move a Kanban card (no production.write)'
);

select is(
  (select count(*)::int from get_masters()),
  0,
  'requirement: accountant (cannot assign a master) gets an empty master picker list'
);

select * from finish();
rollback;
