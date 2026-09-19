-- pgTAP tests for Stage 3: Company Settings & Subscription Management
-- (20260713000039). Run with `supabase test db` — like the rest of
-- this schema, this has not been executed against a live database in
-- this environment (no Postgres/Supabase CLI available — see
-- supabase/README.md).
--
-- Companies A/B mirror the fixture shape used throughout every other
-- multi-tenant test file in this repo. Director A is `director`;
-- Manager A is a non-director employee of the SAME company, used to
-- prove update_company_settings() really is director/owner-only, not
-- just company-scoped.

begin;
select plan(15);

select set_config('app.bypass_profile_guard', 'on', true);

insert into companies (id, name, country, code) values
  ('a0000000-0000-0000-0000-00000000000a', 'Company A', 'Kazakhstan', 'CODE-STGA'),
  ('b0000000-0000-0000-0000-00000000000b', 'Company B', 'Kazakhstan', 'CODE-STGB');

insert into auth.users (id, email) values
  ('a1000000-0000-0000-0000-000000000001', 'director-a@test.local'),
  ('a2000000-0000-0000-0000-000000000002', 'manager-a@test.local'),
  ('b1000000-0000-0000-0000-000000000001', 'director-b@test.local');
-- profiles rows are created automatically by handle_new_auth_user().

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

insert into company_subscriptions (company_id, plan_key, status, started_at, expires_at)
values (
  'a0000000-0000-0000-0000-00000000000a', 'pro', 'active',
  now() - interval '10 days', now() + interval '20 days'
);

set local role authenticated;

-- ---------- update_company_settings() ----------
set local "request.jwt.claims" to '{"sub": "a1000000-0000-0000-0000-000000000001", "role": "authenticated"}';

select lives_ok(
  $$select update_company_settings(
    'JUMA Factory Renamed', null, '+77011234567', 'info@juma.kz', 'Almaty',
    '123456789012', 'https://juma.kz', 'Asia/Almaty', 'KZT', '09:00-18:00', 'Furniture factory'
  )$$,
  'requirement: director can update their own company settings'
);

select is(
  (select name from companies where id = 'a0000000-0000-0000-0000-00000000000a'),
  'JUMA Factory Renamed',
  'requirement: the update actually persisted'
);

select is(
  (select website from companies where id = 'a0000000-0000-0000-0000-00000000000a'),
  'https://juma.kz',
  'requirement: new settings columns (website) persisted'
);

select is(
  (select name from companies where id = 'b0000000-0000-0000-0000-00000000000b'),
  'Company B',
  'requirement: Company B is untouched by Company A director''s update'
);

select throws_ok(
  $$select update_company_settings('Should not be allowed to rename')$$,
  '23514',
  null,
  'requirement: a blank-ish/invalid name is rejected'
);

set local "request.jwt.claims" to '{"sub": "a2000000-0000-0000-0000-000000000002", "role": "authenticated"}';

select throws_ok(
  $$select update_company_settings('Manager Should Not Be Able To Do This')$$,
  '42501',
  null,
  'requirement: a non-director employee of the SAME company cannot update settings'
);

select is(
  (select name from companies where id = 'a0000000-0000-0000-0000-00000000000a'),
  'JUMA Factory Renamed',
  'requirement: the manager''s rejected attempt did not change anything'
);

-- ---------- get_company_subscription_info() ----------
select is(
  (select plan_key from get_company_subscription_info()),
  'pro',
  'requirement: subscription info reflects Company A''s actual plan'
);

select is(
  (select active_users from get_company_subscription_info()),
  2::bigint,
  'requirement: active_users counts exactly Company A''s 2 active profiles'
);

select is(
  (select remaining_days >= 19 and remaining_days <= 20 from get_company_subscription_info()),
  true,
  'requirement: remaining_days is computed from expires_at, not a stale/frozen value'
);

set local "request.jwt.claims" to '{"sub": "b1000000-0000-0000-0000-000000000001", "role": "authenticated"}';

select is(
  (select plan_key from get_company_subscription_info()),
  'free',
  'requirement: Company B (no company_subscriptions row) falls back to companies.subscription_plan'
);

select is(
  (select active_users from get_company_subscription_info()),
  1::bigint,
  'requirement: Director A''s employee count never leaks into Director B''s own company view'
);

-- ---------- get_subscription_plans() ----------
select is(
  (select count(*)::int from get_subscription_plans()),
  5,
  'requirement: catalog has exactly free/start/pro/business/enterprise'
);

select is(
  (select key from get_subscription_plans() order by price_tiyn asc nulls last limit 1),
  'free',
  'requirement: free (0 tiyn) sorts first, distinct from enterprise''s null "custom pricing"'
);

select is(
  (select key from get_subscription_plans() order by price_tiyn asc nulls last
   offset 4 limit 1),
  'enterprise',
  'requirement: enterprise (null price_tiyn = custom pricing) sorts last, not tied with free'
);

select * from finish();
rollback;
