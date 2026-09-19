-- pgTAP tests proving the Analytics module's role split: manager sees
-- sales/orders figures but never payment/finance ones, accountant sees
-- payment/finance figures but never sales/orders ones, and a base role
-- (no analytics permission at all) only ever sees their own KPI row —
-- never the company-wide summary or the top-clients list. Run with
-- `supabase test db` — like the rest of this schema, this has NOT been
-- executed against a live database in this environment (no Postgres/
-- Supabase CLI available — see supabase/README.md).

begin;
select plan(14);

-- ---------- fixtures ----------
insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'director@test.local'),
  ('33333333-3333-3333-3333-333333333333', 'manager@test.local'),
  ('55555555-5555-5555-5555-555555555555', 'accountant@test.local'),
  ('66666666-6666-6666-6666-666666666666', 'master@test.local');
-- profiles rows are created automatically by handle_new_auth_user().

insert into user_roles (profile_id, role_id) values
  ('11111111-1111-1111-1111-111111111111', (select id from roles where key = 'director')),
  ('33333333-3333-3333-3333-333333333333', (select id from roles where key = 'manager')),
  ('55555555-5555-5555-5555-555555555555', (select id from roles where key = 'accountant')),
  ('66666666-6666-6666-6666-666666666666', (select id from roles where key = 'master'));

insert into employees (user_id, email)
values ('66666666-6666-6666-6666-666666666666', 'master@test.local');

-- Fixture data (client/order/payment) is created as the director —
-- the orders_status_transition_guard trigger requires
-- auth_can_set_order_status('installed'), which only director/
-- manager/workshop_manager hold, regardless of the inserting role's
-- table-level grants.
set local role authenticated;
set local "request.jwt.claims" to '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}';

insert into clients (id, name, phone, created_at)
values ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'Тест клиент', '+77011112233', '2026-06-15');

insert into orders (
  id, order_number, client_id, product_type, status, total_amount_tiyn,
  responsible_employee_id, created_at, installation_date
) values (
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'JU-TEST-0001',
  'cccccccc-cccc-cccc-cccc-cccccccccccc', 'Шкаф', 'installed', 100000000,
  '66666666-6666-6666-6666-666666666666', '2026-06-10', '2026-06-20'
);

insert into payments (
  id, order_id, client_id, amount_tiyn, method_id, paid_at,
  recorded_by, confirmed_by, confirmed_at, status, idempotency_key
) values (
  'dddddddd-dddd-dddd-dddd-dddddddddddd', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  'cccccccc-cccc-cccc-cccc-cccccccccccc', 50000000,
  (select id from payment_methods where key = 'cash'), '2026-06-18',
  '66666666-6666-6666-6666-666666666666', '11111111-1111-1111-1111-111111111111',
  now(), 'confirmed', 'analytics-test-payment-1'
);

-- ---------- as manager (analytics.read_sales, analytics.read_all_kpi) ----------
set local "request.jwt.claims" to '{"sub": "33333333-3333-3333-3333-333333333333", "role": "authenticated"}';

select is(
  (select turnover_tiyn from get_analytics_summary('2026-06-01', '2026-06-30')),
  100000000,
  'requirement: manager (analytics.read_sales) sees turnover for the period'
);

select is(
  (select payments_received_tiyn from get_analytics_summary('2026-06-01', '2026-06-30')),
  null,
  'requirement: manager never sees payments_received (analytics.read_financial not granted)'
);

select is(
  (select count(*)::int from get_employee_kpis('2026-06-01', '2026-06-30')),
  1,
  'requirement: manager (analytics.read_all_kpi) can see every employee''s KPI row'
);

select is(
  (select count(*)::int from get_top_clients('2026-06-01', '2026-06-30')),
  1,
  'requirement: manager (analytics.read_sales) sees the top-clients list'
);

-- ---------- as accountant (analytics.read_financial only) ----------
set local "request.jwt.claims" to '{"sub": "55555555-5555-5555-5555-555555555555", "role": "authenticated"}';

select is(
  (select turnover_tiyn from get_analytics_summary('2026-06-01', '2026-06-30')),
  null,
  'requirement: accountant never sees turnover (analytics.read_sales not granted)'
);

select is(
  (select payments_received_tiyn from get_analytics_summary('2026-06-01', '2026-06-30')),
  50000000,
  'requirement: accountant (analytics.read_financial) sees payments_received'
);

select is(
  (select count(*)::int from get_top_clients('2026-06-01', '2026-06-30')),
  0,
  'requirement: accountant (no analytics.read_sales) gets an empty top-clients result, not an error'
);

-- ---------- as master (no analytics permission — "own KPI only") ----------
set local "request.jwt.claims" to '{"sub": "66666666-6666-6666-6666-666666666666", "role": "authenticated"}';

select is(
  (select turnover_tiyn from get_analytics_summary('2026-06-01', '2026-06-30')),
  null,
  'requirement: a base role sees no company-wide summary data at all'
);

select is(
  (select count(*)::int from get_employee_kpis('2026-06-01', '2026-06-30')),
  1,
  'requirement: "Қалған рөлдер: өзіне қатысты KPI ғана" — master sees only their own KPI row, even ignoring any p_employee_id override'
);

select is(
  (select orders_assigned_count from get_employee_kpis('2026-06-01', '2026-06-30')
    where employee_id = '66666666-6666-6666-6666-666666666666'),
  1,
  'requirement: master sees their own orders_assigned_count'
);

select is(
  (select payments_recorded_amount_tiyn from get_employee_kpis('2026-06-01', '2026-06-30')
    where employee_id = '66666666-6666-6666-6666-666666666666'),
  50000000,
  'requirement: master sees their own payments_recorded_amount even without analytics.read_financial — it is their own recorded work, not a global financial figure'
);

select is(
  (select count(*)::int from get_top_clients('2026-06-01', '2026-06-30')),
  0,
  'requirement: master (no analytics.read_sales) gets an empty top-clients result'
);

-- ---------- as director (full analytics) ----------
set local "request.jwt.claims" to '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}';

select is(
  (select turnover_tiyn from get_analytics_summary('2026-06-01', '2026-06-30')),
  100000000,
  'requirement: director sees the full analytics summary, sales fields included'
);

select is(
  (select payments_received_tiyn from get_analytics_summary('2026-06-01', '2026-06-30')),
  50000000,
  'requirement: director also sees financial fields in the same summary call'
);

select * from finish();
rollback;
