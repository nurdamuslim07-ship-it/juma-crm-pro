-- Employees module — see Employees module requirements. Salary/bonus
-- data is materially more sensitive than anything modeled so far
-- (payments are transactional records; this is personal compensation
-- data), and the requirements explicitly demand proof that a
-- non-director cannot read or write it. A view-based column hide
-- (the orders_public / active_payments pattern used elsewhere) only
-- restricts what the *provided* query returns — it can't stop a
-- client from querying the base table directly, since Postgres RLS
-- is row-level, not column-level. So for this table specifically:
-- ALL direct table privileges are revoked from `authenticated`/`anon`
-- (PostgREST refuses the request before RLS is even evaluated), and
-- every read/write goes through a SECURITY DEFINER RPC that decides
-- column visibility in Postgres, not in Dart.

create type salary_type as enum ('fixed', 'percentage');

create table employees (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references profiles (id) on delete cascade,
  -- Denormalized from auth.users at creation time by the
  -- create-employee Edge Function (see supabase/functions/create-employee) —
  -- auth.users itself is not directly queryable via PostgREST/RLS.
  email text not null,
  hire_date date,
  salary_type salary_type not null default 'fixed',
  base_salary_tiyn bigint not null default 0 check (base_salary_tiyn >= 0),
  bonus_percent numeric not null default 0 check (bonus_percent between 0 and 100),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  -- Soft delete (requirement #6) — deliberately independent of
  -- profiles.is_active (requirement #5's temporary deactivation):
  -- deleting the HR record and deactivating login access are
  -- different actions with different consequences, per the
  -- requirement "Soft delete және active status бөлек жұмыс істесін".
  deleted_at timestamptz
);

create index employees_user_id_idx on employees (user_id);

create trigger employees_set_updated_at
  before update on employees
  for each row execute function set_updated_at();

alter table employees enable row level security;

-- Defense-in-depth only — see this file's header comment. The real
-- gate is the REVOKE below; these policies matter only if grants are
-- ever restored, so they encode the same rule the RPCs enforce rather
-- than being relied upon directly by the app.
create policy "employees_select_definer_only" on employees
  for select using (
    deleted_at is null and (
      auth_has_permission('employees.read_financial')
      or auth_has_permission('employees.read')
      or user_id = auth.uid()
    )
  );

create policy "employees_write_director_only" on employees
  for all using (auth_is_director()) with check (auth_is_director());

revoke all on employees from authenticated, anon;
-- SECURITY DEFINER functions below still work: they execute as the
-- function owner (not `authenticated`), which is unaffected by this
-- revoke — the same pattern relied on by record_payment() etc.

-- Requirement: "Қолданушы өз профилінің телефон нөмірі мен аватарын
-- ғана өзгерте алады" / "Рөлді қолданушы өзі өзгерте алмайды" —
-- profiles itself keeps its existing broad self-update RLS policy
-- (profiles_update_own, from 20260713000012_rls_policies.sql), which
-- has no column granularity. This trigger adds that granularity:
-- a director may change anything (their own row or someone else's,
-- via update_employee() below); anyone else may only touch
-- phone/avatar_url on their own row.
create function restrict_profile_self_update()
returns trigger
language plpgsql
set search_path = public
as $$
begin
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

create trigger profiles_restrict_self_update
  before update on profiles
  for each row execute function restrict_profile_self_update();

-- Returns every employee the caller is allowed to see, with
-- salary_type/base_salary_tiyn/bonus_percent set to NULL for anyone
-- without employees.read_financial (director) — this is the actual
-- enforcement of "Жалақы және бонус ақпаратын тек директор көре
-- алады", not a UI convention. A caller with neither
-- employees.read_financial nor employees.read (i.e. every
-- non-director/manager role) only ever gets their own row back
-- ("Қалған рөлдер тек өз профилін көре алады"), with salary columns
-- NULL even for themselves — nobody but the director sees salary,
-- including the employee it belongs to.
create or replace function get_employees(
  p_search text default null,
  p_role_filter role_key default null,
  p_active_filter boolean default null,
  p_user_id uuid default null
)
returns table (
  id uuid,
  user_id uuid,
  full_name text,
  phone text,
  email text,
  avatar_url text,
  is_active boolean,
  hire_date date,
  salary_type salary_type,
  base_salary_tiyn bigint,
  bonus_percent numeric,
  notes text,
  role_key role_key,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_financial boolean := auth_has_permission('employees.read_financial');
  v_broad boolean := auth_has_permission('employees.read');
begin
  if not auth_is_active() then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  if not v_financial and not v_broad then
    return query
      select
        e.id, e.user_id, p.full_name, p.phone, e.email, p.avatar_url, p.is_active,
        e.hire_date, null::salary_type, null::bigint, null::numeric, e.notes,
        r.role_key, e.created_at
      from employees e
      join profiles p on p.id = e.user_id
      left join lateral (
        select rl.key as role_key
        from user_roles ur join roles rl on rl.id = ur.role_id
        where ur.profile_id = e.user_id
        order by ur.assigned_at
        limit 1
      ) r on true
      where e.deleted_at is null and e.user_id = auth.uid();
    return;
  end if;

  return query
    select
      e.id, e.user_id, p.full_name, p.phone, e.email, p.avatar_url, p.is_active,
      e.hire_date,
      case when v_financial then e.salary_type end,
      case when v_financial then e.base_salary_tiyn end,
      case when v_financial then e.bonus_percent end,
      e.notes, r.role_key, e.created_at
    from employees e
    join profiles p on p.id = e.user_id
    left join lateral (
      select rl.key as role_key
      from user_roles ur join roles rl on rl.id = ur.role_id
      where ur.profile_id = e.user_id
      order by ur.assigned_at
      limit 1
    ) r on true
    where e.deleted_at is null
      and (p_user_id is null or e.user_id = p_user_id)
      and (
        p_search is null or p_search = '' or
        p.full_name ilike '%' || p_search || '%' or
        e.email ilike '%' || p_search || '%' or
        p.phone ilike '%' || p_search || '%'
      )
      and (p_role_filter is null or r.role_key = p_role_filter)
      and (p_active_filter is null or p.is_active = p_active_filter)
    order by p.full_name;
end;
$$;

-- Director-only edit of an existing employee's HR fields, profile
-- fields, and role (requirement: create/edit/delete restricted to
-- director; role reassignment also director-only). Replaces the
-- employee's user_roles row(s) with exactly p_role_key — this module
-- treats one employee as having one role, even though user_roles
-- itself supports many-to-many.
create or replace function update_employee(
  p_user_id uuid,
  p_full_name text,
  p_phone text,
  p_role_key role_key,
  p_hire_date date default null,
  p_salary_type salary_type default 'fixed',
  p_base_salary_tiyn bigint default 0,
  p_bonus_percent numeric default 0,
  p_notes text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_role_id uuid;
begin
  if not auth_is_director() then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  update profiles set full_name = p_full_name, phone = p_phone where id = p_user_id;

  update employees set
    hire_date = p_hire_date,
    salary_type = p_salary_type,
    base_salary_tiyn = p_base_salary_tiyn,
    bonus_percent = p_bonus_percent,
    notes = p_notes
  where user_id = p_user_id;

  select id into v_role_id from roles where key = p_role_key;
  if v_role_id is not null then
    delete from user_roles where profile_id = p_user_id;
    insert into user_roles (profile_id, role_id, assigned_by)
    values (p_user_id, v_role_id, auth.uid());
  end if;
end;
$$;

create or replace function soft_delete_employee(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not auth_is_director() then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;
  update employees set deleted_at = now() where user_id = p_user_id;
end;
$$;

-- Requirement: "Аватарды Supabase Storage-қа жүктеу" — public read
-- (avatars are shown throughout the UI, unlike payment receipts),
-- self-service upload restricted to the caller's own folder
-- (avatars/{user_id}/...), plus a director bypass so the director can
-- set an avatar for someone else (e.g. right after creating them).
insert into storage.buckets (id, name, public)
values ('avatars', 'avatars', true)
on conflict (id) do nothing;

create policy "avatars_read_public"
  on storage.objects for select
  using (bucket_id = 'avatars');

create policy "avatars_upload_own"
  on storage.objects for insert
  with check (
    bucket_id = 'avatars' and auth_is_active()
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "avatars_update_own"
  on storage.objects for update
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "avatars_director_manage"
  on storage.objects for all
  using (bucket_id = 'avatars' and auth_is_director())
  with check (bucket_id = 'avatars' and auth_is_director());
