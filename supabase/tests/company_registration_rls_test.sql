-- pgTAP tests for the company registration/join/approval module
-- (20260713000036-38) and the self-update-guard security fix it
-- depends on. Run with `supabase test db` — like the rest of this
-- schema, this has not been executed against a live database in this
-- environment (no Postgres/Supabase CLI available — see
-- supabase/README.md).
--
-- Companies A/B are pre-existing (director fixtures, mirrors every
-- other multi-tenant test file); Company C exists solely to exercise
-- the "sole owner" guard in isolation from A/B's director-only roles.
-- Every other actor (join requester, invitees, the fresh
-- create-company signup) is a brand-new `auth.users` row with no
-- company — exactly `handle_new_auth_user()`'s own starting state
-- (company_id null, status 'pending'), so no fixture assignment is
-- needed for them at all.

begin;
select plan(29);

-- ---------- fixtures: companies A/B/C + their directors/owner ----------
select set_config('app.bypass_profile_guard', 'on', true);

insert into companies (id, name, country, code) values
  ('a0000000-0000-0000-0000-00000000000a', 'Company A', 'Kazakhstan', 'CODE-AAAA'),
  ('b0000000-0000-0000-0000-00000000000b', 'Company B', 'Kazakhstan', 'CODE-BBBB'),
  ('c0000000-0000-0000-0000-00000000000c', 'Company C', 'Kazakhstan', 'CODE-CCCC');

insert into auth.users (id, email) values
  ('a1000000-0000-0000-0000-000000000001', 'director-a@test.local'),
  ('b1000000-0000-0000-0000-000000000001', 'director-b@test.local'),
  ('c1000000-0000-0000-0000-000000000001', 'owner-c@test.local'),
  ('d1000000-0000-0000-0000-000000000001', 'newco@test.local'),
  ('e1000000-0000-0000-0000-000000000001', 'joiner@test.local'),
  ('f1000000-0000-0000-0000-000000000001', 'invitee-ok@test.local'),
  ('f2000000-0000-0000-0000-000000000002', 'invitee-reuse@test.local'),
  ('f3000000-0000-0000-0000-000000000003', 'invitee-expired@test.local'),
  ('f4000000-0000-0000-0000-000000000004', 'invitee-revoked@test.local');
-- profiles rows are created automatically by handle_new_auth_user() —
-- every one of them starts company_id null, status 'pending'.

update profiles set company_id = 'a0000000-0000-0000-0000-00000000000a', status = 'active'
  where id = 'a1000000-0000-0000-0000-000000000001';
update profiles set company_id = 'b0000000-0000-0000-0000-00000000000b', status = 'active'
  where id = 'b1000000-0000-0000-0000-000000000001';
update profiles set company_id = 'c0000000-0000-0000-0000-00000000000c', status = 'active'
  where id = 'c1000000-0000-0000-0000-000000000001';

insert into user_roles (profile_id, role_id) values
  ('a1000000-0000-0000-0000-000000000001', (select id from roles where key = 'director')),
  ('b1000000-0000-0000-0000-000000000001', (select id from roles where key = 'director')),
  ('c1000000-0000-0000-0000-000000000001', (select id from roles where key = 'owner'));

insert into employees (id, company_id, user_id, email, salary_type) values
  ('e1000000-0000-0000-0000-00000000000a', 'a0000000-0000-0000-0000-00000000000a', 'a1000000-0000-0000-0000-000000000001', 'director-a@test.local', 'fixed'),
  ('e1000000-0000-0000-0000-00000000000b', 'b0000000-0000-0000-0000-00000000000b', 'b1000000-0000-0000-0000-000000000001', 'director-b@test.local', 'fixed'),
  ('e1000000-0000-0000-0000-00000000000c', 'c0000000-0000-0000-0000-00000000000c', 'c1000000-0000-0000-0000-000000000001', 'owner-c@test.local', 'fixed');

insert into clients (id, company_id, name, phone) values
  ('cc000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-00000000000a', 'Client A', '+77010000001');

-- company_invitations has all direct grants revoked (same
-- defense-in-depth pattern as employees/partners) — these two rows
-- must be inserted now, as the migration-owner/superuser session,
-- same reason employees_rls_test.sql/partners_rls_test.sql seed
-- those two tables before switching role below; there is no "switch
-- back to superuser" partway through this file, matching every other
-- multi-tenant test in this suite.
insert into company_invitations (id, company_id, code, role_key, created_by, max_uses, expires_at)
values ('11110000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-00000000000a', 'EXPIRED1', 'viewer', 'a1000000-0000-0000-0000-000000000001', 1, now() - interval '1 hour');
insert into company_invitations (id, company_id, code, role_key, created_by, max_uses, revoked_at)
values ('22220000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-00000000000a', 'REVOKED1', 'viewer', 'a1000000-0000-0000-0000-000000000001', 1, now());

select set_config('app.bypass_profile_guard', 'off', true);

-- ==================== self-update guard (Stage 1e core) ====================
set local role authenticated;
set local "request.jwt.claims" to '{"sub": "a1000000-0000-0000-0000-000000000001", "role": "authenticated"}';

select throws_ok(
  $$update profiles set company_id = 'b0000000-0000-0000-0000-00000000000b' where id = 'a1000000-0000-0000-0000-000000000001'$$,
  '42501',
  null,
  'requirement: a client cannot PATCH their own profiles.company_id directly'
);

select throws_ok(
  $$update profiles set status = 'active' where id = 'a1000000-0000-0000-0000-000000000001'$$,
  '42501',
  null,
  'requirement: a client cannot PATCH their own profiles.status directly (even to a no-op value)'
);

update profiles set phone = '+77011234567' where id = 'a1000000-0000-0000-0000-000000000001';
select is(
  (select phone from profiles where id = 'a1000000-0000-0000-0000-000000000001'),
  '+77011234567',
  'regression: self-updating an unrelated column (phone) still works after the guard'
);

-- ==================== create_company_and_owner() ====================
set local "request.jwt.claims" to '{"sub": "d1000000-0000-0000-0000-000000000001", "role": "authenticated"}';

select isnt(
  (select create_company_and_owner('New Co', '+77012223344', 'new@co.kz', 'Almaty', null, null)),
  null,
  'create_company_and_owner() returns a new company id'
);

select is(
  (select status::text from profiles where id = 'd1000000-0000-0000-0000-000000000001'),
  'active',
  'create_company_and_owner() activates the creating profile immediately'
);

select is(
  (select r.key::text from user_roles ur join roles r on r.id = ur.role_id
   where ur.profile_id = 'd1000000-0000-0000-0000-000000000001'),
  'owner',
  'create_company_and_owner() assigns the owner role'
);

select throws_ok(
  $$select create_company_and_owner('Second Co')$$,
  '23514',
  null,
  'create_company_and_owner() refuses a caller who already belongs to a company'
);

-- ==================== request_to_join_company() + isolation ====================
set local "request.jwt.claims" to '{"sub": "e1000000-0000-0000-0000-000000000001", "role": "authenticated"}';

select isnt(
  (select request_to_join_company('CODE-AAAA', 'assistant', 'Please let me in')),
  null,
  'request_to_join_company() creates a pending request'
);

select is(
  (select status::text from profiles where id = 'e1000000-0000-0000-0000-000000000001'),
  'pending',
  'requester''s own profile is pending immediately, ahead of approval'
);

select throws_ok(
  $$select request_to_join_company('CODE-BBBB', 'assistant')$$,
  '23514',
  null,
  'requirement: duplicate-pending-request is blocked while one is already outstanding'
);

select is(
  (select count(*)::int from clients),
  0,
  'requirement: a pending user sees zero rows of Company A''s business data (auth_is_active() gate)'
);

set local "request.jwt.claims" to '{"sub": "a1000000-0000-0000-0000-000000000001", "role": "authenticated"}';

select is(
  (select count(*)::int from get_pending_company_requests()),
  1,
  'requirement: Director A sees exactly the 1 pending request for their own company'
);

set local "request.jwt.claims" to '{"sub": "b1000000-0000-0000-0000-000000000001", "role": "authenticated"}';

select is(
  (select count(*)::int from get_pending_company_requests()),
  0,
  'requirement: Director B sees NOTHING of Company A''s pending requests (cross-company isolation)'
);

select throws_ok(
  format(
    $$select approve_company_join_request('%s')$$,
    (select id from company_join_requests where profile_id = 'e1000000-0000-0000-0000-000000000001')
  ),
  'P0002',
  null,
  'requirement: Director B cannot approve Company A''s join request'
);

set local "request.jwt.claims" to '{"sub": "a1000000-0000-0000-0000-000000000001", "role": "authenticated"}';

select lives_ok(
  format(
    $$select approve_company_join_request('%s')$$,
    (select id from company_join_requests where profile_id = 'e1000000-0000-0000-0000-000000000001')
  ),
  'Director A can approve Company A''s own join request'
);

select is(
  (select status::text from profiles where id = 'e1000000-0000-0000-0000-000000000001'),
  'active',
  'approval activates the requester''s membership'
);

select is(
  (select r.key::text from user_roles ur join roles r on r.id = ur.role_id
   where ur.profile_id = 'e1000000-0000-0000-0000-000000000001'),
  'assistant',
  'approval assigns the requested role'
);

set local "request.jwt.claims" to '{"sub": "e1000000-0000-0000-0000-000000000001", "role": "authenticated"}';

select is(
  (select status from get_my_join_requests() limit 1),
  'approved',
  'the requester''s own history shows the request as approved'
);

-- ==================== reject + retry ====================
set local "request.jwt.claims" to '{"sub": "f1000000-0000-0000-0000-000000000001", "role": "authenticated"}';
select request_to_join_company('CODE-BBBB', 'viewer');

set local "request.jwt.claims" to '{"sub": "b1000000-0000-0000-0000-000000000001", "role": "authenticated"}';
select reject_company_join_request(
  (select id from company_join_requests where profile_id = 'f1000000-0000-0000-0000-000000000001'),
  'Толық емес ақпарат'
);

select is(
  (select status::text from profiles where id = 'f1000000-0000-0000-0000-000000000001'),
  'rejected',
  'rejection marks the profile status rejected'
);

set local "request.jwt.claims" to '{"sub": "f1000000-0000-0000-0000-000000000001", "role": "authenticated"}';
select lives_ok(
  $$select request_to_join_company('CODE-AAAA', 'viewer')$$,
  'a rejected user can re-request (a different company, in this case)'
);

-- ==================== withdraw ====================
select lives_ok(
  format(
    $$select withdraw_company_join_request('%s')$$,
    (select id from company_join_requests where profile_id = 'f1000000-0000-0000-0000-000000000001' and status = 'pending')
  ),
  'the requester can withdraw their own pending request'
);

select is(
  (select company_id from profiles where id = 'f1000000-0000-0000-0000-000000000001'),
  null,
  'withdrawing resets company_id back to null, same as a fresh signup'
);

-- ==================== invitations ====================
set local "request.jwt.claims" to '{"sub": "a1000000-0000-0000-0000-000000000001", "role": "authenticated"}';

-- create_company_invitation()'s code is random — looked up by its
-- distinguishing attributes below rather than captured, since plain
-- pgTAP/SQL has no client-side variable to stash a return value in
-- (no `\gset`-style meta-command is used anywhere else in this test
-- suite, so this stays consistent with that).
select create_company_invitation('manager', 1, 168);

set local "request.jwt.claims" to '{"sub": "f2000000-0000-0000-0000-000000000002", "role": "authenticated"}';

select lives_ok(
  format(
    $$select accept_company_invitation('%s')$$,
    (select code from company_invitations
     where company_id = 'a0000000-0000-0000-0000-00000000000a' and role_key = 'manager')
  ),
  'accept_company_invitation() with a valid single-use code activates membership immediately'
);

select is(
  (select r.key::text from user_roles ur join roles r on r.id = ur.role_id
   where ur.profile_id = 'f2000000-0000-0000-0000-000000000002'),
  'manager',
  'invitation acceptance assigns the invitation''s role, with no separate approval step'
);

set local "request.jwt.claims" to '{"sub": "f3000000-0000-0000-0000-000000000003", "role": "authenticated"}';

select throws_ok(
  format(
    $$select accept_company_invitation('%s')$$,
    (select code from company_invitations
     where company_id = 'a0000000-0000-0000-0000-00000000000a' and role_key = 'manager')
  ),
  'P0002',
  null,
  'requirement: a single-use invitation cannot be redeemed a second time'
);

select throws_ok(
  $$select accept_company_invitation('EXPIRED1')$$,
  'P0002',
  null,
  'requirement: an expired invitation is rejected'
);

set local "request.jwt.claims" to '{"sub": "f4000000-0000-0000-0000-000000000004", "role": "authenticated"}';

select throws_ok(
  $$select accept_company_invitation('REVOKED1')$$,
  'P0002',
  null,
  'requirement: a revoked invitation is rejected'
);

-- ==================== owner-cannot-be-accidentally-removed ====================
set local "request.jwt.claims" to '{"sub": "c1000000-0000-0000-0000-000000000001", "role": "authenticated"}';

select throws_ok(
  $$select update_employee('c1000000-0000-0000-0000-000000000001', 'Owner C', '+77010000000', 'manager')$$,
  '23514',
  null,
  'requirement: update_employee() cannot demote a company''s sole owner'
);

select throws_ok(
  $$select soft_delete_employee('c1000000-0000-0000-0000-000000000001')$$,
  '23514',
  null,
  'requirement: soft_delete_employee() cannot remove a company''s sole owner'
);

select * from finish();
rollback;
