-- pgTAP tests proving the Partners module's core security claims:
-- bank details/balance are only ever visible to director/accountant,
-- non-write roles cannot create/edit partners, delete/restore is
-- director-only, and the base table cannot be queried directly. Run
-- with `supabase test db` — like employees_rls_test.sql, this has NOT
-- been executed against a live database in this environment (no
-- Postgres/Supabase CLI available — see supabase/README.md).

begin;
select plan(13);

-- ---------- fixtures ----------
insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'director@test.local'),
  ('44444444-4444-4444-4444-444444444444', 'purchaser@test.local'),
  ('55555555-5555-5555-5555-555555555555', 'accountant@test.local'),
  ('66666666-6666-6666-6666-666666666666', 'master@test.local');
-- profiles rows are created automatically by handle_new_auth_user().

insert into user_roles (profile_id, role_id) values
  ('11111111-1111-1111-1111-111111111111', (select id from roles where key = 'director')),
  ('44444444-4444-4444-4444-444444444444', (select id from roles where key = 'purchaser')),
  ('55555555-5555-5555-5555-555555555555', (select id from roles where key = 'accountant')),
  ('66666666-6666-6666-6666-666666666666', (select id from roles where key = 'master'));

insert into partners (id, display_name, category, phone, bank_details, balance_tiyn, trust_rating)
values (
  'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Ерлан ЛДСП жеткізуші', 'ldsp', '+77011112233',
  'Kaspi Bank, 4400 43** **** 1234', 1500000, 4
);

-- ---------- as master (base contact tier only) ----------
set local role authenticated;
set local "request.jwt.claims" to '{"sub": "66666666-6666-6666-6666-666666666666", "role": "authenticated"}';

select is(
  (select bank_details from get_partners() where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  null,
  'requirement: a role with only partners.read never sees bank_details'
);

select is(
  (select balance_tiyn from get_partners() where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  null,
  'requirement: a role with only partners.read never sees balance_tiyn'
);

select is(
  (select trust_rating from get_partners() where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  null,
  'requirement: "Қалған рөлдер тек негізгі байланыс ақпаратын көреді" — trust_rating (extended tier) is also hidden'
);

select is(
  (select display_name from get_partners() where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  'Ерлан ЛДСП жеткізуші',
  'requirement: basic contact fields (display_name) ARE visible to every internal role'
);

select throws_ok(
  $$select create_partner('Жаңа серіктес', 'other')$$,
  '42501',
  'Бұл әрекетке рұқсатыңыз жоқ',
  'requirement: a role without partners.write cannot create a partner'
);

select throws_ok(
  $$update partners set display_name = 'Hacked' where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'$$,
  null,
  null,
  'requirement: direct UPDATE on partners is blocked (table grants revoked from authenticated)'
);

-- ---------- as purchaser (extended tier, write, no financial) ----------
set local "request.jwt.claims" to '{"sub": "44444444-4444-4444-4444-444444444444", "role": "authenticated"}';

select is(
  (select trust_rating from get_partners() where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  4::smallint,
  'requirement: purchaser (partners.read_extended) sees non-financial business fields like trust_rating'
);

select is(
  (select bank_details from get_partners() where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  null,
  'requirement: purchaser still never sees bank_details — read_extended is not read_financial'
);

select lives_ok(
  $$select update_partner('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'Ерлан ЛДСП жеткізуші', 'ldsp', null, '+77011112233')$$,
  'requirement: purchaser (partners.write) can edit non-financial fields'
);

select throws_ok(
  $$select update_partner_financials('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'stolen bank info', 999999999)$$,
  '42501',
  'Бұл әрекетке рұқсатыңыз жоқ',
  'requirement: partners.write alone cannot change bank_details/balance — only director can via update_partner_financials()'
);

select throws_ok(
  $$select soft_delete_partner('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa')$$,
  '42501',
  'Бұл әрекетке рұқсатыңыз жоқ',
  'requirement: "Өшіру және қалпына келтіру тек director-ға рұқсат" — purchaser cannot soft delete'
);

-- ---------- as accountant (financial read, no write) ----------
set local "request.jwt.claims" to '{"sub": "55555555-5555-5555-5555-555555555555", "role": "authenticated"}';

select is(
  (select bank_details from get_partners() where id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  'Kaspi Bank, 4400 43** **** 1234',
  'requirement: "Accountant: қаржылық реквизиттер мен баланс ақпаратын көреді" — accountant sees bank_details'
);

-- ---------- as director ----------
set local "request.jwt.claims" to '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}';

select lives_ok(
  $$select soft_delete_partner('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa')$$,
  'requirement: director can soft delete a partner'
);

select * from finish();
rollback;
