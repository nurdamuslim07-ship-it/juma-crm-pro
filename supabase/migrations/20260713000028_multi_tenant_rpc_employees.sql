-- Multi-tenant SaaS conversion — Stage 1d, part 3: employees RPCs.
--
-- get_employees()/update_employee()/soft_delete_employee() are
-- SECURITY DEFINER and `employees` has ALL direct table grants revoked
-- (see 20260713000017's header) — before this patch, any director
-- could list/edit/delete ANY company's employees via these RPCs,
-- since neither the base-case (own row) nor the broad-case query
-- filtered by company at all.

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
  v_company_id uuid := auth_company_id();
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
      where e.deleted_at is null and e.company_id = v_company_id and e.user_id = auth.uid();
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
      and e.company_id = v_company_id
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
  v_company_id uuid := auth_company_id();
  v_role_id uuid;
begin
  if not auth_is_director() then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  if not exists (
    select 1 from employees where user_id = p_user_id and company_id = v_company_id
  ) then
    raise exception 'Қызметкер табылмады' using errcode = 'P0002';
  end if;

  update profiles set full_name = p_full_name, phone = p_phone
  where id = p_user_id and company_id = v_company_id;

  update employees set
    hire_date = p_hire_date,
    salary_type = p_salary_type,
    base_salary_tiyn = p_base_salary_tiyn,
    bonus_percent = p_bonus_percent,
    notes = p_notes
  where user_id = p_user_id and company_id = v_company_id;

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
  update employees set deleted_at = now()
  where user_id = p_user_id and company_id = auth_company_id();
end;
$$;
