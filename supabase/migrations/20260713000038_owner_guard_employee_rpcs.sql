-- Guard against accidentally stripping a company's only `owner`.
--
-- update_employee() (20260713000028) unconditionally replaces the
-- target's user_roles row, and soft_delete_employee() (same file) can
-- remove an owner from the company entirely — neither checks whether
-- the target is the company's sole `owner` before doing so. Both get
-- the identical guard here, `create or replace` over the existing
-- bodies (this project's established pattern for redefining an
-- already-migrated function rather than editing the historical
-- migration file it first appeared in).

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

  if p_role_key <> 'owner' and exists (
    select 1 from user_roles ur join roles r on r.id = ur.role_id
    where ur.profile_id = p_user_id and r.key = 'owner'
  ) then
    if (
      select count(*) from user_roles ur
      join roles r on r.id = ur.role_id
      join profiles p on p.id = ur.profile_id
      where r.key = 'owner' and p.company_id = v_company_id
    ) <= 1 then
      raise exception 'Компанияның жалғыз иесінің рөлін өзгерту мүмкін емес' using errcode = '23514';
    end if;
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
declare
  v_company_id uuid := auth_company_id();
begin
  if not auth_is_director() then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  if exists (
    select 1 from user_roles ur join roles r on r.id = ur.role_id
    where ur.profile_id = p_user_id and r.key = 'owner'
  ) and (
    select count(*) from user_roles ur
    join roles r on r.id = ur.role_id
    join profiles p on p.id = ur.profile_id
    where r.key = 'owner' and p.company_id = v_company_id
  ) <= 1 then
    raise exception 'Компанияның жалғыз иесін жою мүмкін емес' using errcode = '23514';
  end if;

  update employees set deleted_at = now()
  where user_id = p_user_id and company_id = v_company_id;
end;
$$;
