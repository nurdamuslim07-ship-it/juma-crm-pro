-- pgTAP regression test for the active_payments company_id fix
-- (20260713000030_active_payments_company_id_fix.sql). Proves the
-- view exposes company_id, that get_analytics_summary()/
-- get_employee_kpis() (20260713000031_multi_tenant_rpc_analytics.sql)
-- execute without the "column ap.company_id does not exist" runtime
-- error the missing column previously caused, and that the figures
-- they compute through the view stay company-isolated. Run with
-- `supabase test db` — like the rest of this schema, this has not
-- been executed against a live database in this environment.

begin;
select plan(9);

insert into companies (id, name, country) values
  ('faaaaaaa-0000-0000-0000-000000000001', 'Company A', 'Kazakhstan'),
  ('fbbbbbbb-0000-0000-0000-000000000002', 'Company B', 'Kazakhstan');

insert into auth.users (id, email) values
  ('fa110000-0000-0000-0000-000000000001', 'director-a@test.local'),
  ('fb220000-0000-0000-0000-000000000002', 'director-b@test.local');
-- profiles rows are created automatically by handle_new_auth_user().

select set_config('app.bypass_profile_guard', 'on', true);

update profiles set company_id = 'faaaaaaa-0000-0000-0000-000000000001', status = 'active'
  where id = 'fa110000-0000-0000-0000-000000000001';
update profiles set company_id = 'fbbbbbbb-0000-0000-0000-000000000002', status = 'active'
  where id = 'fb220000-0000-0000-0000-000000000002';

insert into user_roles (profile_id, role_id) values
  ('fa110000-0000-0000-0000-000000000001', (select id from roles where key = 'director')),
  ('fb220000-0000-0000-0000-000000000002', (select id from roles where key = 'director'));

insert into employees (id, company_id, user_id, email, salary_type) values
  ('fe110000-0000-0000-0000-000000000001', 'faaaaaaa-0000-0000-0000-000000000001', 'fa110000-0000-0000-0000-000000000001', 'director-a@test.local', 'fixed'),
  ('fe220000-0000-0000-0000-000000000002', 'fbbbbbbb-0000-0000-0000-000000000002', 'fb220000-0000-0000-0000-000000000002', 'director-b@test.local', 'fixed');

insert into clients (id, company_id, name, phone) values
  ('fc110000-0000-0000-0000-000000000001', 'faaaaaaa-0000-0000-0000-000000000001', 'Client A', '+77010000001'),
  ('fc220000-0000-0000-0000-000000000002', 'fbbbbbbb-0000-0000-0000-000000000002', 'Client B', '+77010000002');

-- orders inserted per-director (enforce_order_status_change resolves
-- auth.uid() from the session's JWT claims), same reason
-- multi_tenant_rpc_isolation_test.sql does the same.
set local role authenticated;
set local "request.jwt.claims" to '{"sub": "fa110000-0000-0000-0000-000000000001", "role": "authenticated"}';

insert into orders (id, company_id, order_number, client_id, product_type, status, total_amount_tiyn)
values ('fd110000-0000-0000-0000-000000000001', 'faaaaaaa-0000-0000-0000-000000000001', 'JU-FA-0001', 'fc110000-0000-0000-0000-000000000001', 'Шкаф', 'in_progress', 1000000);

select record_payment('idem-fix-a-1', 'fd110000-0000-0000-0000-000000000001', 'fc110000-0000-0000-0000-000000000001', 500000, null);

set local "request.jwt.claims" to '{"sub": "fb220000-0000-0000-0000-000000000002", "role": "authenticated"}';

insert into orders (id, company_id, order_number, client_id, product_type, status, total_amount_tiyn)
values ('fd220000-0000-0000-0000-000000000002', 'fbbbbbbb-0000-0000-0000-000000000002', 'JU-FB-0001', 'fc220000-0000-0000-0000-000000000002', 'Үстел', 'in_progress', 1000000);

select record_payment('idem-fix-b-1', 'fd220000-0000-0000-0000-000000000002', 'fc220000-0000-0000-0000-000000000002', 300000, null);

-- ---------- the fix itself ----------
select lives_ok(
  $$select company_id from active_payments limit 0$$,
  'active_payments exposes a company_id column'
);

-- ---------- as Director A ----------
set local "request.jwt.claims" to '{"sub": "fa110000-0000-0000-0000-000000000001", "role": "authenticated"}';

select lives_ok(
  $$select * from get_analytics_summary(current_date - 30, current_date + 1)$$,
  'get_analytics_summary() no longer fails with "column ap.company_id does not exist"'
);

select is(
  (select payments_received_tiyn from get_analytics_summary(current_date - 30, current_date + 1)),
  500000::bigint,
  'requirement: get_analytics_summary() payments_received_tiyn reflects only Company A''s own confirmed payment'
);

select lives_ok(
  $$select * from get_employee_kpis(current_date - 30, current_date + 1)$$,
  'get_employee_kpis() no longer fails with "column ap.company_id does not exist"'
);

select is(
  (select payments_recorded_amount_tiyn from get_employee_kpis(current_date - 30, current_date + 1)
   where employee_id = 'fa110000-0000-0000-0000-000000000001'),
  500000::bigint,
  'requirement: get_employee_kpis() payments_recorded_amount_tiyn reflects only Director A''s own recorded payment'
);

select is(
  (select count(*)::int from get_employee_kpis(current_date - 30, current_date + 1)),
  1,
  'requirement: get_employee_kpis() never surfaces Company B''s employee to Director A'
);

-- ---------- as Director B ----------
set local "request.jwt.claims" to '{"sub": "fb220000-0000-0000-0000-000000000002", "role": "authenticated"}';

select lives_ok(
  $$select * from get_analytics_summary(current_date - 30, current_date + 1)$$,
  'get_analytics_summary() also runs cleanly for Company B'
);

select is(
  (select payments_received_tiyn from get_analytics_summary(current_date - 30, current_date + 1)),
  300000::bigint,
  'requirement: get_analytics_summary() payments_received_tiyn reflects only Company B''s own confirmed payment, never combined with Company A''s'
);

select is(
  (select payments_recorded_amount_tiyn from get_employee_kpis(current_date - 30, current_date + 1)
   where employee_id = 'fb220000-0000-0000-0000-000000000002'),
  300000::bigint,
  'requirement: get_employee_kpis() payments_recorded_amount_tiyn reflects only Director B''s own recorded payment'
);

select * from finish();
rollback;
