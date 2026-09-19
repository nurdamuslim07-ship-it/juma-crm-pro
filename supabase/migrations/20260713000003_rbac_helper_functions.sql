-- RLS helper functions — SECURITY DEFINER so they can read
-- user_roles/role_permissions regardless of the calling user's own
-- row-level access (avoids RLS-recursion issues), per
-- ROLES_AND_PERMISSIONS.md's "three-layer enforcement": these are what
-- every table's policy in 20260713000012_rls_policies.sql is built on.
-- This is the actual, non-bypassable authorization boundary — unlike
-- the legacy web app's UI-only role checks (SECURITY_PLAN.md finding #6).

create function auth_has_permission(permission_key text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from user_roles ur
    join role_permissions rp on rp.role_id = ur.role_id
    join permissions p on p.id = rp.permission_id
    where ur.profile_id = auth.uid()
      and p.key = permission_key
  );
$$;

create function auth_has_role(role_key_param role_key)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from user_roles ur
    join roles r on r.id = ur.role_id
    where ur.profile_id = auth.uid()
      and r.key = role_key_param
  );
$$;

create function auth_is_director()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select auth_has_role('director'::role_key);
$$;

create function auth_is_active()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select is_active from profiles where id = auth.uid()),
    false
  );
$$;
