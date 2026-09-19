-- Multi-tenant SaaS conversion — Stage 1a: tenant core.
--
-- Every company using JUMA UI going forward is an isolated tenant.
-- This migration lays the foundation the rest of Stage 1 depends on:
-- the `companies` table itself, the `profiles.company_id`/`status`
-- columns that bind an identity to exactly one tenant (see the plan's
-- "one company per profile" decision — a user creates or joins
-- exactly one company at registration; no many-to-many membership
-- table is needed), and `auth_company_id()`, the single new helper
-- every later RLS policy/RPC will call.
--
-- Iron rule for the whole multi-tenant conversion, stated once here:
-- `company_id` is NEVER accepted as a client-supplied parameter in any
-- RPC, and NEVER compared against anything from the request body in
-- any policy — it is always derived server-side via `auth_company_id()`
-- (which itself only ever reads the caller's own `profiles` row).

create table companies (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  logo text,
  phone text,
  email text,
  country text,
  city text,
  address text,
  iin_bin text,
  subscription_plan text not null default 'free',
  subscription_status text not null default 'active',
  subscription_expires_at timestamptz,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger companies_set_updated_at
  before update on companies
  for each row execute function set_updated_at();

-- Registration-flow status (Stage 2 wires the RPCs that set this).
-- `pending` = signed up (own or invited), waiting on a director's
-- approve/reject decision; `active` = normal access; `rejected` =
-- director declined the join request; `suspended` = director-revoked
-- after having been active. `profiles.is_active` is kept unchanged for
-- backward compatibility (anything still reading it sees the same
-- value it always has for existing rows), but it is no longer the
-- access gate — see `auth_is_active()` below.
create type profile_status as enum ('pending', 'active', 'rejected', 'suspended');

alter table profiles
  add column company_id uuid references companies (id),
  add column status profile_status not null default 'pending';

-- New role tiers requested for the SaaS model. Additive only — every
-- existing role_key value is untouched, so nothing that already reads
-- role_key breaks (per "Backward compatibility сақталсын").
-- `owner` = the profile that created the company (see Stage 2's
-- `create_company_and_register_owner()`); distinct from `director` so
-- a company can eventually have hired directors who don't hold the
-- account-level owner capabilities (billing/subscription/company
-- settings — see Stage 6).
alter type role_key add value if not exists 'owner';
alter type role_key add value if not exists 'viewer';

-- The one new helper every later RLS policy/RPC in this conversion
-- calls. Deliberately as small and boring as `auth_is_active()` below
-- it mirrors — no join, no permission logic, just "what company does
-- the calling identity belong to."
create function auth_company_id()
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select company_id from profiles where id = auth.uid();
$$;

-- Redefine auth_is_director() so the new `owner` role (the profile
-- that created the company) inherits every director-only capability
-- gated directly on this function (not via a `permissions` row) —
-- `profiles_director_manage`, `employees_write_director_only`,
-- `partners_delete_director_only`, the various `*_delete_director`/
-- `*_write_director` policies, etc. `create or replace` is safe: for
-- every existing single-tenant user (no `owner` role assigned to
-- anyone yet), this is a no-op change in observed behavior.
create or replace function auth_is_director()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select auth_has_role('director'::role_key) or auth_has_role('owner'::role_key);
$$;

-- Redefine auth_is_active() to gate on the new tri/four-state `status`
-- instead of the old boolean — `create or replace` is safe here since
-- every existing profile is about to be backfilled to `status = 'active'`
-- below, so this is a no-op change in observed behavior for the
-- current single tenant.
create or replace function auth_is_active()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce((select status = 'active' from profiles where id = auth.uid()), false);
$$;

-- RLS is enabled here immediately, same as every other table in this
-- schema (see 20260713000012's header comment) — a company row is
-- readable only by its own members. No write policy yet: the initial
-- insert happens inside Stage 2's SECURITY DEFINER
-- `create_company_and_register_owner()` (which bypasses RLS by
-- design), and Stage 6 ("Company Settings") adds the owner/director
-- update policy once there's a UI that needs it. Placed after
-- `auth_company_id()` above, since the policy calls it.
alter table companies enable row level security;

create policy "companies_select_own" on companies
  for select using (id = auth_company_id());

-- ---------- backward-compatibility bridge ----------
-- Today's single tenant becomes tenant #1 ("Default") with zero
-- observable change for its existing users: every existing profile is
-- backfilled to this company and marked active. Stage 1b performs the
-- equivalent backfill for every other business table.
do $$
declare
  v_default_company_id uuid;
begin
  insert into companies (name, country, subscription_plan, subscription_status)
  values ('Default', 'Kazakhstan', 'enterprise', 'active')
  returning id into v_default_company_id;

  update profiles
  set company_id = v_default_company_id,
      status = 'active'
  where company_id is null;
end;
$$;
