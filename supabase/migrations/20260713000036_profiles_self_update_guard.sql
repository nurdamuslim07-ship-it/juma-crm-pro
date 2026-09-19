-- Multi-tenant SaaS conversion — Stage 1e: close the last open gap in
-- the whole conversion.
--
-- `profiles_update_own` (20260713000012) is still `for update using
-- (auth.uid() = id) with check (auth.uid() = id)` — no column
-- restriction at the RLS layer. The only column guard,
-- `restrict_profile_self_update()` (20260713000017), predates
-- `company_id`/`status` (added 6 migrations later in 20260713000023)
-- and only ever knew about `full_name`/`is_active`/`telegram_user_id`.
-- Net effect today: ANY authenticated user can issue a raw PostgREST
-- `PATCH /profiles?id=eq.<self>` setting `company_id` to an arbitrary
-- company and `status` to `'active'`, walking straight past every
-- onboarding RPC this stage's next migration builds. This is the same
-- "company_id is never client-supplied" rule Stage 1a/1d established,
-- just via a different vector (a direct table PATCH instead of an RPC
-- parameter) — closing it is this migration's only job.
--
-- Fix: `company_id`/`status` become guarded columns too, but
-- unconditionally — even for directors, since nothing about being a
-- director legitimizes self-granting membership in a different
-- company via a raw PATCH. The only way past the guard is a
-- transaction-local GUC flag (`app.bypass_profile_guard`) that a
-- trusted SECURITY DEFINER RPC sets immediately before its own
-- `update profiles` statement — `set_config(..., true)` scopes it to
-- the current transaction only, so it can never leak across
-- requests. The company-registration module (next migration) is the
-- only code that ever sets this flag.

create or replace function restrict_profile_self_update()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if (
    NEW.company_id is distinct from OLD.company_id
    or NEW.status is distinct from OLD.status
  ) and coalesce(current_setting('app.bypass_profile_guard', true), 'off') <> 'on' then
    raise exception 'company_id/status тек серверлік RPC арқылы өзгереді' using errcode = '42501';
  end if;

  if auth_is_director() then
    return NEW;
  end if;
  if NEW.full_name is distinct from OLD.full_name
    or NEW.is_active is distinct from OLD.is_active
    or NEW.telegram_user_id is distinct from OLD.telegram_user_id then
    raise exception 'Тек телефон нөмірі мен аватарды өзгерте аласыз' using errcode = '42501';
  end if;
  return NEW;
end;
$$;
