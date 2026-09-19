-- pgTAP tests for Step 1 of the multi-company architecture
-- (20260713000042: the company_memberships table + backfill). Run
-- with `supabase test db` — like the rest of this schema, this has
-- not been executed against a live database in this environment (no
-- local Docker Postgres available this session — see
-- supabase/README.md).
--
-- Self-contained: 20260713000042 includes its own `grant select on
-- company_memberships to authenticated` (see that migration's header
-- comment for why it's needed even for a brand-new table), so the
-- `set local role authenticated` select below is expected to succeed
-- on its own, without depending on any other migration. The
-- schema-wide version of this same grants gap, affecting every
-- pre-existing table, is a separate, deliberately postponed fix — not
-- part of this file's scope.
--
-- Scope: this migration is purely additive (no existing table, RLS
-- policy, or helper function changes), so this file only proves the
-- new table's own shape/constraints/RLS — it does NOT re-run the
-- existing multi-tenant isolation suites, since nothing they cover
-- has changed.
--
-- Deliberately NOT covered here: the one-time backfill's output. A
-- pgTAP file runs after all migrations have already applied once
-- against a fresh (empty) `profiles` table, so by the time any test
-- transaction starts, the real backfill has already run against zero
-- rows — there is nothing left to observe, and anything this file
-- inserted itself to check against would just be testing its own
-- fixture, not the migration. Backfill correctness is verified
-- separately: a read-only query run directly against staging/
-- production immediately after the migration is actually applied
-- there, comparing real profiles to the real resulting membership
-- rows.

begin;
select plan(13);

-- ---------- shape ----------

select has_table('public', 'company_memberships', 'company_memberships table exists');
select has_column('public', 'company_memberships', 'id', 'has id column');
select has_column('public', 'company_memberships', 'profile_id', 'has profile_id column');
select has_column('public', 'company_memberships', 'company_id', 'has company_id column');
select has_column('public', 'company_memberships', 'status', 'has status column');
select has_column('public', 'company_memberships', 'joined_at', 'has joined_at column');
select has_column('public', 'company_memberships', 'invited_by', 'has invited_by column');
select has_column('public', 'company_memberships', 'created_at', 'has created_at column');

select ok(
  (
    select count(*) = 1
    from pg_indexes
    where schemaname = 'public'
      and tablename = 'company_memberships'
      and indexname = 'company_memberships_active_lookup_idx'
  ),
  'has the (profile_id, company_id, status) lookup index'
);

-- ---------- fixtures ----------

insert into companies (id, name, country, code) values
  ('c0000000-0000-0000-0000-00000000000a', 'Company A', 'Kazakhstan', 'CODE-CMA'),
  ('c0000000-0000-0000-0000-00000000000b', 'Company B', 'Kazakhstan', 'CODE-CMB');

insert into auth.users (id, email) values
  ('d1000000-0000-0000-0000-000000000001', 'director-a@test.local'),
  ('d2000000-0000-0000-0000-000000000002', 'director-b@test.local');
-- profiles rows are created automatically by handle_new_auth_user().

select set_config('app.bypass_profile_guard', 'on', true);
update profiles set company_id = 'c0000000-0000-0000-0000-00000000000a', status = 'active'
  where id = 'd1000000-0000-0000-0000-000000000001';
update profiles set company_id = 'c0000000-0000-0000-0000-00000000000b', status = 'active'
  where id = 'd2000000-0000-0000-0000-000000000002';

-- Director A holds memberships in BOTH companies — proves this table
-- can represent what profiles.company_id structurally never could.
insert into company_memberships (profile_id, company_id, status, invited_by) values
  ('d1000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-00000000000a', 'active', null),
  ('d1000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-00000000000b', 'pending', 'd2000000-0000-0000-0000-000000000002'),
  ('d2000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-00000000000b', 'active', null);

-- ---------- unique (profile_id, company_id) ----------

select throws_ok(
  $$insert into company_memberships (profile_id, company_id, status)
    values ('d1000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-00000000000a', 'active')$$,
  '23505',
  null,
  'requirement: a profile cannot hold two membership rows for the same company'
);

-- ---------- invited_by: on delete set null (not cascade) ----------

delete from auth.users where id = 'd2000000-0000-0000-0000-000000000002';

select is(
  (select invited_by from company_memberships
   where profile_id = 'd1000000-0000-0000-0000-000000000001'
     and company_id = 'c0000000-0000-0000-0000-00000000000b'),
  null,
  'requirement: deleting the inviter profile sets invited_by to null, and does NOT delete the membership row it is attached to'
);

select is(
  (select count(*)::int from company_memberships
   where profile_id = 'd1000000-0000-0000-0000-000000000001'),
  2,
  'sanity: Director A''s own two membership rows survived the inviter''s deletion'
);

-- ---------- RLS: a profile sees only its own membership rows ----------

set local role authenticated;
set local "request.jwt.claims" to '{"sub": "d1000000-0000-0000-0000-000000000001", "role": "authenticated"}';

select is(
  (select count(*)::int from company_memberships),
  2,
  'requirement: Director A sees exactly their own 2 membership rows, never any other profile''s'
);

select * from finish();
rollback;
