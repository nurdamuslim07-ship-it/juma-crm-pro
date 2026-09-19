-- Fixes a critical, currently-live production bug found during the
-- production-readiness audit: `create-employee` (the Edge Function
-- that is the ONLY way to add an employee) has never been updated
-- for multi-tenancy. It fails outright today — `employees.company_id`
-- is `not null` with no default (20260713000024), and the function's
-- insert never sets it, so every employee-creation attempt fails a
-- NOT NULL violation and rolls back the just-created auth account.
--
-- Even fixing that insert alone would not be enough: the new
-- employee's `profiles.company_id`/`status` also need to move from
-- the trigger-created `null`/`'pending'` default
-- (`handle_new_auth_user()`, 20260713000002) to the director's own
-- company/`'active'` — otherwise the new employee could log in but
-- would land on the "create or join a company" onboarding screen
-- instead of the company they were just invited into.
-- `restrict_profile_self_update()` (20260713000036) blocks exactly
-- that column pair unless `app.bypass_profile_guard` is set within
-- the same transaction — which no client (including a service_role
-- REST call, which still passes through this trigger; BYPASSRLS does
-- not bypass triggers) can do without going through a SECURITY
-- DEFINER function. Hence this new RPC, following the exact same
-- shape as `create_company_and_owner()`/`request_to_join_company()`.
--
-- Deliberately callable by `authenticated`, not just service_role:
-- authorization is enforced inside the function (`auth_is_director()`
-- + `auth_company_id()` resolved from the CALLER's own session, never
-- a client-supplied parameter), matching this project's "company_id
-- is never client-supplied" rule. The Edge Function calls this via
-- its `callerClient` (scoped to the calling director's own JWT), not
-- `adminClient` (service_role has no `auth.uid()`, so `auth_is_director()`/
-- `auth_company_id()` would resolve to nothing useful through it).
create or replace function provision_employee_profile(p_profile_id uuid)
returns uuid
language plpgsql
security definer
set search_path = 'public'
as $$
declare
  v_company_id uuid;
begin
  if not auth_is_director() then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  v_company_id := auth_company_id();
  if v_company_id is null then
    raise exception 'Компания анықталмады' using errcode = '23514';
  end if;

  if not exists (select 1 from profiles where id = p_profile_id) then
    raise exception 'Профиль табылмады' using errcode = 'P0002';
  end if;

  perform set_config('app.bypass_profile_guard', 'on', true);
  update profiles
  set company_id = v_company_id, status = 'active'
  where id = p_profile_id;

  return v_company_id;
end;
$$;

grant execute on function provision_employee_profile(uuid) to authenticated;
