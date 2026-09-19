-- pgTAP tests proving the multi-tenant SaaS conversion's single most
-- important claim: a company can NEVER see or write another company's
-- data. Run with `supabase test db` (requires the pgtap extension,
-- which that command provisions automatically) — this has NOT been
-- executed against a live database in this environment (no
-- Postgres/Supabase CLI was available — see supabase/README.md), so
-- treat it as a specified-but-unverified test suite, same caveat as
-- every other pgTAP file in this project.
--
-- Scope note: `employees`/`partners`/`partner_documents` have ALL
-- direct table grants revoked from `authenticated` (defense-in-depth
-- pattern — see 20260713000017/20260713000018's own header comments),
-- so they cannot be exercised via a direct SQL statement the way
-- `clients`/`material_categories`/`companies` can here; their real
-- access path is `get_employees()`/`get_partners()` and friends, which
-- are SECURITY DEFINER and therefore bypass table RLS entirely. Those
-- functions are patched for company-scoping in a follow-up migration
-- (Stage 1d) — this suite will gain the equivalent employees/partners
-- cross-company assertions once that lands. Until then, a real (if
-- narrow) gap exists: those two RPCs currently return EVERY company's
-- rows, not just the caller's own.
--
-- Two companies, one director each. Director A must never see or
-- write Company B's companies/profiles/clients/material_categories
-- rows (and vice versa), and a forged `company_id` in an insert/role
-- assignment must be rejected, not just an omitted one.

begin;
select plan(20);

-- ---------- fixtures ----------
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

insert into clients (id, company_id, name, phone, created_by) values
  ('c1111111-0000-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0000-000000000001', 'Client A', '+77010000001', '11111111-1111-1111-1111-111111111111'),
  ('c2222222-0000-0000-0000-000000000002', 'bbbbbbbb-0000-0000-0000-000000000002', 'Client B', '+77010000002', '22222222-2222-2222-2222-222222222222');

insert into material_categories (id, company_id, key, name_kk) values
  ('m1111111-0000-0000-0000-000000000001', 'aaaaaaaa-0000-0000-0000-000000000001', 'category-a', 'Category A'),
  ('m2222222-0000-0000-0000-000000000002', 'bbbbbbbb-0000-0000-0000-000000000002', 'category-b', 'Category B');

-- ---------- as Director A ----------
set local role authenticated;
set local "request.jwt.claims" to '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}';

select is(
  (select count(*)::int from clients),
  1,
  'requirement: Director A sees exactly 1 client — their own company''s, never Company B''s'
);

select is(
  (select name from clients limit 1),
  'Client A',
  'requirement: the one client Director A sees is Company A''s own'
);

select is(
  (select count(*)::int from material_categories),
  1,
  'requirement: Director A sees exactly 1 material category — never Company B''s'
);

select is(
  (select count(*)::int from profiles where id = '22222222-2222-2222-2222-222222222222'),
  0,
  'requirement: Director A cannot see Director B''s profile row (cross-company colleague leak closed)'
);

select is(
  (select count(*)::int from user_roles where profile_id = '22222222-2222-2222-2222-222222222222'),
  0,
  'requirement: Director A cannot see Director B''s role assignment'
);

select throws_ok(
  $$insert into clients (company_id, name, phone, created_by) values ('bbbbbbbb-0000-0000-0000-000000000002', 'Forged', '+77010000009', '11111111-1111-1111-1111-111111111111')$$,
  '42501',
  null,
  'requirement: Director A cannot forge a client row tagged with Company B''s company_id'
);

-- clients has no REVOKE (only RLS), so an update targeting a row
-- outside the caller's company simply matches 0 rows — it does NOT
-- raise an error, unlike employees/partners' revoked-grants case (see
-- header note). The real assertion is the read-back immediately after.
update clients set name = 'Hijacked' where id = 'c2222222-0000-0000-0000-000000000002';

select is(
  (select name from clients where id = 'c2222222-0000-0000-0000-000000000002'),
  null,
  'requirement: Director A''s attempted update of Company B''s client affected nothing (row invisible, so also unreadable back)'
);

select throws_ok(
  $$insert into user_roles (profile_id, role_id) values ('22222222-2222-2222-2222-222222222222', (select id from roles where key = 'viewer'))$$,
  '42501',
  null,
  'requirement: Director A cannot assign a role to a profile outside their own company'
);

select is(
  (select count(*)::int from companies),
  1,
  'requirement: Director A sees exactly 1 company via companies_select_own — their own, never Company B''s'
);

select is(
  (select name from companies limit 1),
  'Company A',
  'requirement: the one company Director A sees is their own'
);

-- ---------- as Director B ----------
set local "request.jwt.claims" to '{"sub": "22222222-2222-2222-2222-222222222222", "role": "authenticated"}';

select is(
  (select count(*)::int from clients),
  1,
  'requirement: Director B sees exactly 1 client — their own, never Company A''s'
);

select is(
  (select name from clients limit 1),
  'Client B',
  'requirement: the one client Director B sees is Company B''s own'
);

select is(
  (select count(*)::int from material_categories),
  1,
  'requirement: Director B sees exactly 1 material category — never Company A''s'
);

select is(
  (select count(*)::int from profiles where id = '11111111-1111-1111-1111-111111111111'),
  0,
  'requirement: Director B cannot see Director A''s profile row'
);

select is(
  (select count(*)::int from companies),
  1,
  'requirement: Director B sees exactly 1 company — their own, never Company A''s'
);

select is(
  (select name from companies limit 1),
  'Company B',
  'requirement: the one company Director B sees is their own'
);

select is(
  auth_company_id(),
  'bbbbbbbb-0000-0000-0000-000000000002'::uuid,
  'sanity: auth_company_id() resolves to the caller''s own company'
);

-- ---------- as a caller with no resolvable company (e.g. mid-registration) ----------
set local "request.jwt.claims" to '{}';

select is(
  auth_company_id(),
  null,
  'sanity: a caller with no matching profile row has no resolvable company_id'
);

select is(
  (select count(*)::int from clients),
  0,
  'requirement: a caller with no resolvable company_id sees no clients anywhere'
);

select is(
  (select count(*)::int from companies),
  0,
  'requirement: same for companies — companies_select_own never matches a null auth_company_id()'
);

select * from finish();
rollback;
