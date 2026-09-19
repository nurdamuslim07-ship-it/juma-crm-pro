-- pgTAP tests proving the Employees module's core security claim:
-- a non-director cannot read or write salary/bonus, and cannot change
-- their own role. Run with `supabase test db` (requires the pgtap
-- extension, which that command provisions automatically) — this has
-- NOT been executed against a live database in this environment (no
-- Postgres/Supabase CLI was available — see supabase/README.md), so
-- treat it as a specified-but-unverified test suite; column names in
-- auth.users may need adjusting to match the exact Supabase project
-- version's schema if any INSERT below fails on NOT NULL constraints
-- this project's auth schema adds beyond the ones assumed here.

begin;
select plan(9);

-- ---------- fixtures ----------
insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'director@test.local'),
  ('22222222-2222-2222-2222-222222222222', 'measurer@test.local'),
  ('33333333-3333-3333-3333-333333333333', 'manager@test.local');
-- profiles rows are created automatically by handle_new_auth_user().

insert into user_roles (profile_id, role_id) values
  ('11111111-1111-1111-1111-111111111111', (select id from roles where key = 'director')),
  ('22222222-2222-2222-2222-222222222222', (select id from roles where key = 'measurer')),
  ('33333333-3333-3333-3333-333333333333', (select id from roles where key = 'manager'));

insert into employees (user_id, email, base_salary_tiyn, bonus_percent, salary_type)
values ('22222222-2222-2222-2222-222222222222', 'measurer@test.local', 50000000, 5, 'fixed');

-- ---------- as the measurer (non-director, non-manager) ----------
set local role authenticated;
set local "request.jwt.claims" to '{"sub": "22222222-2222-2222-2222-222222222222", "role": "authenticated"}';

select is(
  (select base_salary_tiyn from get_employees() where user_id = '22222222-2222-2222-2222-222222222222'),
  null,
  'requirement: a non-director/manager cannot see salary via get_employees(), not even their own'
);

select is(
  (select bonus_percent from get_employees() where user_id = '22222222-2222-2222-2222-222222222222'),
  null,
  'requirement: same for bonus_percent'
);

select is(
  (select count(*)::int from get_employees()),
  1,
  'requirement: "Қалған рөлдер тек өз профилін көре алады" — a measurer sees only their own row'
);

select throws_ok(
  $$select update_employee('22222222-2222-2222-2222-222222222222', 'Measurer', '+77010000000', 'director', null, 'fixed', 999999999, 50, null)$$,
  '42501',
  'Бұл әрекетке рұқсатыңыз жоқ',
  'requirement: a non-director cannot call update_employee — cannot self-promote to director or change their own salary'
);

select throws_ok(
  $$update employees set base_salary_tiyn = 999999999 where user_id = '22222222-2222-2222-2222-222222222222'$$,
  null,
  null,
  'requirement: direct UPDATE on employees is blocked (table grants revoked from authenticated)'
);

select throws_ok(
  $$update profiles set is_active = false where id = '22222222-2222-2222-2222-222222222222'$$,
  '42501',
  null,
  'a non-director cannot deactivate even their own account (is_active is director-only, per restrict_profile_self_update)'
);

-- Self-service: phone/avatar ARE allowed to change on one's own row.
select lives_ok(
  $$update profiles set phone = '+77011234567' where id = '22222222-2222-2222-2222-222222222222'$$,
  'requirement: a user may change their own phone number'
);

-- ---------- as the manager (broad read, no financial read) ----------
set local "request.jwt.claims" to '{"sub": "33333333-3333-3333-3333-333333333333", "role": "authenticated"}';

select is(
  (select base_salary_tiyn from get_employees() where user_id = '22222222-2222-2222-2222-222222222222'),
  null,
  'requirement: manager sees the employee list but never salary/bonus columns'
);

-- ---------- as the director ----------
set local "request.jwt.claims" to '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}';

select is(
  (select base_salary_tiyn from get_employees() where user_id = '22222222-2222-2222-2222-222222222222'),
  50000000,
  'requirement: only the director sees salary/bonus'
);

select * from finish();
rollback;
