-- Step 1 of the multi-company account architecture: the real
-- many-to-many membership source of truth.
--
-- Today `profiles.company_id`/`status` is a single nullable column
-- pair — structurally one company per profile, enforced by the table
-- shape itself (profiles.id is the primary key, 1:1 with
-- auth.users.id). This migration does NOT touch that column or
-- anything that reads it. It only adds a new, currently-unread table
-- that will become the source of truth for "which companies does
-- this profile belong to" in a later, separate migration — this step
-- is purely additive and changes no existing behavior:
--
--   - profiles.company_id is not renamed yet (that is Step 2).
--   - user_roles is not modified (Step 8 retires it).
--   - auth_company_id()/auth_has_role()/auth_has_permission() are not
--     modified (Steps 3-4).
--   - no existing RLS policy is modified.
--   - nothing in the Flutter app reads this table yet.
--
-- Backfill: every profile that already has a company gets exactly
-- one membership row mirroring it, so the eventual cutover in later
-- steps has real data to read from day one.
create table company_memberships (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles(id) on delete cascade,
  company_id uuid not null references companies(id) on delete cascade,
  status profile_status not null default 'pending',
  joined_at timestamptz not null default now(),
  invited_by uuid references profiles(id) on delete set null,
  created_at timestamptz not null default now(),
  constraint company_memberships_profile_company_unique
    unique (profile_id, company_id)
);

create index company_memberships_profile_id_idx
  on company_memberships(profile_id);

create index company_memberships_company_id_idx
  on company_memberships(company_id);

create index company_memberships_active_lookup_idx
  on company_memberships(profile_id, company_id, status);

-- The explicit `grant select` below is required for the RLS policy
-- created further down to be reachable at all: this project's tables
-- have never received baseline DML grants for `authenticated` by
-- default, because every migration in this project runs as the
-- `postgres` role, and this project's `pg_default_acl` only
-- auto-grants `SELECT/INSERT/UPDATE/DELETE` to `authenticated` for
-- tables created by `supabase_admin` — `postgres`-created tables
-- (i.e. every table in this schema, including this new one) get only
-- `TRUNCATE/REFERENCES/TRIGGER/MAINTAIN` by default, never SELECT.
-- Without this line, company_memberships_select_own would be silent
-- dead code, same as every pre-existing table in this schema
-- currently is — a separate, pre-existing, schema-wide defect,
-- intentionally NOT fixed here. This grant is scoped to exactly the
-- one new table this migration introduces and does not touch any
-- other table's grants. Granted before RLS is even enabled, so the
-- privilege is in place before there is any policy to be blocked by
-- its absence.
--
-- `revoke insert, update, delete` is a no-op today (nothing ever
-- grants those by default either), kept only as explicit,
-- future-proof documentation that direct writes are never intended.
grant select on company_memberships to authenticated;
revoke insert, update, delete on company_memberships from authenticated;

alter table company_memberships enable row level security;

-- Read-only for now: a profile can see only its own membership rows.
-- No insert/update/delete policy exists — every future write goes
-- through a SECURITY DEFINER RPC (Steps 5-8), never a raw client
-- PATCH/POST, same defense-in-depth pattern already used for
-- employees/partners.
create policy company_memberships_select_own
  on company_memberships for select
  using (profile_id = auth.uid());

-- joined_at is `now()` (the backfill's own run time), not
-- `profiles.created_at` — the profile's account-creation timestamp is
-- not the same moment as when it joined its company, and conflating
-- the two would fabricate a join date this table has no real record
-- of.
insert into company_memberships (profile_id, company_id, status, joined_at, invited_by, created_at)
select p.id, p.company_id, p.status, now(), null, now()
from profiles p
where p.company_id is not null
  and not exists (
    select 1 from company_memberships cm
    where cm.profile_id = p.id and cm.company_id = p.company_id
  );
