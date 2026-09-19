-- pgTAP tests for Stage 4 Part 3's one new RPC (20260713000041). The
-- audit log LIST itself is a direct PostgREST query under the
-- existing `audit_logs_select_director` policy — already covered by
-- that policy's own test in multi_tenant_company_isolation_rls_test.sql
-- in spirit (director-only, company-scoped select); this file only
-- covers the new distinct-values RPC. Run with `supabase test db` —
-- like the rest of this schema, not executed against a live database
-- in this environment (no Postgres/Supabase CLI available).

begin;
select plan(5);

select set_config('app.bypass_profile_guard', 'on', true);

insert into companies (id, name, country, code) values
  ('a0000000-0000-0000-0000-00000000000a', 'Company A', 'Kazakhstan', 'CODE-AUDA'),
  ('b0000000-0000-0000-0000-00000000000b', 'Company B', 'Kazakhstan', 'CODE-AUDB');

insert into auth.users (id, email) values
  ('a1000000-0000-0000-0000-000000000001', 'director-a@test.local'),
  ('a2000000-0000-0000-0000-000000000002', 'manager-a@test.local'),
  ('b1000000-0000-0000-0000-000000000001', 'director-b@test.local');

update profiles set company_id = 'a0000000-0000-0000-0000-00000000000a', status = 'active'
  where id = 'a1000000-0000-0000-0000-000000000001';
update profiles set company_id = 'a0000000-0000-0000-0000-00000000000a', status = 'active'
  where id = 'a2000000-0000-0000-0000-000000000002';
update profiles set company_id = 'b0000000-0000-0000-0000-00000000000b', status = 'active'
  where id = 'b1000000-0000-0000-0000-000000000001';

insert into user_roles (profile_id, role_id) values
  ('a1000000-0000-0000-0000-000000000001', (select id from roles where key = 'director')),
  ('a2000000-0000-0000-0000-000000000002', (select id from roles where key = 'manager')),
  ('b1000000-0000-0000-0000-000000000001', (select id from roles where key = 'director'));

insert into audit_logs (company_id, actor_id, action, entity_type, entity_id) values
  ('a0000000-0000-0000-0000-00000000000a', 'a1000000-0000-0000-0000-000000000001', 'company_created', 'companies', 'a0000000-0000-0000-0000-00000000000a'),
  ('a0000000-0000-0000-0000-00000000000a', 'a1000000-0000-0000-0000-000000000001', 'join_request_approved', 'company_join_requests', gen_random_uuid()),
  ('b0000000-0000-0000-0000-00000000000b', 'b1000000-0000-0000-0000-000000000001', 'company_created', 'companies', 'b0000000-0000-0000-0000-00000000000b');

set local role authenticated;

set local "request.jwt.claims" to '{"sub": "a1000000-0000-0000-0000-000000000001", "role": "authenticated"}';

select is(
  (select modules from get_audit_log_filters()),
  array['companies', 'company_join_requests'],
  'requirement: modules dropdown reflects exactly Company A''s own entity_types'
);

select is(
  (select actions from get_audit_log_filters()),
  array['company_created', 'join_request_approved'],
  'requirement: actions dropdown reflects exactly Company A''s own actions'
);

select is(
  (select array_length(modules, 1) from get_audit_log_filters()),
  2,
  'requirement: Company B''s "company_created" row never inflates Company A''s distinct count'
);

set local "request.jwt.claims" to '{"sub": "a2000000-0000-0000-0000-000000000002", "role": "authenticated"}';

select throws_ok(
  $$select get_audit_log_filters()$$,
  '42501',
  null,
  'requirement: a non-director employee cannot call get_audit_log_filters()'
);

set local "request.jwt.claims" to '{"sub": "b1000000-0000-0000-0000-000000000001", "role": "authenticated"}';

select is(
  (select modules from get_audit_log_filters()),
  array['companies'],
  'requirement: Company B''s director sees only Company B''s own module'
);

select * from finish();
rollback;
