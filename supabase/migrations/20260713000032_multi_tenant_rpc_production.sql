-- Multi-tenant SaaS conversion — Stage 1d, part 6: production RPCs.
--
-- These are SECURITY DEFINER and joined across orders/order_assignments/
-- material_reservations/inventory_balances/profiles with no company
-- filter before this patch. `get_order_production_detail()` is patched
-- separately in 20260713000034 (its live definition was superseded by
-- 20260713000022_purchases_module.sql, not this file).

create or replace function get_production_queue(
  p_stage_id uuid default null,
  p_master_id uuid default null,
  p_search text default null
)
returns table (
  order_id uuid,
  order_number text,
  product_type text,
  client_name text,
  stage_id uuid,
  stage_key text,
  stage_name_kk text,
  stage_sort_order int,
  percent_complete smallint,
  master_id uuid,
  master_name text,
  materials_sufficient boolean,
  photos_count bigint,
  planned_completion_date date,
  updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_company_id uuid := auth_company_id();
  v_read boolean := auth_has_permission('production.read');
  v_scope_all boolean := v_read and (
    auth_is_director() or auth_has_role('workshop_manager') or auth_has_role('manager')
  );
  v_scope_assigned boolean := v_read and not v_scope_all;
  v_default_stage_id uuid;
begin
  if not v_read then
    return;
  end if;

  select id into v_default_stage_id
  from production_stages where company_id = v_company_id order by sort_order limit 1;

  return query
    select
      o.id,
      o.order_number,
      o.product_type,
      c.name,
      coalesce(ps.id, v_default_stage_id),
      coalesce(ps.key, (select key from production_stages where id = v_default_stage_id)),
      coalesce(ps.name_kk, (select name_kk from production_stages where id = v_default_stage_id)),
      coalesce(ps.sort_order, 1),
      coalesce(opp.percent_complete, 0),
      m.profile_id,
      m.full_name,
      not exists (
        select 1 from material_reservations mr
        where mr.order_id = o.id
          and mr.quantity > coalesce((
            select sum(ib.quantity - ib.reserved_quantity)
            from inventory_balances ib where ib.material_id = mr.material_id
          ), 0)
      ),
      (select count(*) from order_photos op where op.order_id = o.id and op.kind = 'production'),
      o.planned_completion_date,
      coalesce(opp.updated_at, o.updated_at)
    from orders o
    join clients c on c.id = o.client_id
    left join order_production_progress opp on opp.order_id = o.id
    left join production_stages ps on ps.id = opp.current_stage_id
    left join lateral (
      select oa.profile_id, p.full_name
      from order_assignments oa
      join profiles p on p.id = oa.profile_id
      where oa.order_id = o.id and oa.role = 'master'
      order by oa.assigned_at desc
      limit 1
    ) m on true
    where o.deleted_at is null
      and o.company_id = v_company_id
      and o.status = 'in_progress'
      and (
        v_scope_all
        or (
          v_scope_assigned and (
            o.responsible_employee_id = auth.uid()
            or exists (
              select 1 from order_assignments oa2
              where oa2.order_id = o.id and oa2.profile_id = auth.uid()
            )
          )
        )
      )
      and (p_stage_id is null or coalesce(ps.id, v_default_stage_id) = p_stage_id)
      and (p_master_id is null or m.profile_id = p_master_id)
      and (
        p_search is null or p_search = '' or
        o.order_number ilike '%' || p_search || '%' or
        o.product_type ilike '%' || p_search || '%' or
        c.name ilike '%' || p_search || '%'
      )
    order by coalesce(ps.sort_order, 1), o.planned_completion_date nulls last;
end;
$$;

-- Requirement: "Drag & Drop Kanban" — the RPC the Kanban board's drop
-- handler calls. Both p_order_id and p_stage_id are verified against
-- the caller's own company before the upsert.
create or replace function move_order_to_stage(
  p_order_id uuid,
  p_stage_id uuid,
  p_comment text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_company_id uuid := auth_company_id();
begin
  if not auth_has_permission('production.write') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  if not exists (select 1 from orders where id = p_order_id and company_id = v_company_id) then
    raise exception 'Тапсырыс табылмады' using errcode = 'P0002';
  end if;

  if not exists (
    select 1 from production_stages where id = p_stage_id and company_id = v_company_id
  ) then
    raise exception 'Кезең табылмады' using errcode = 'P0002';
  end if;

  insert into order_production_progress (order_id, company_id, current_stage_id)
  values (p_order_id, v_company_id, p_stage_id)
  on conflict (order_id) do update set current_stage_id = excluded.current_stage_id;

  if p_comment is not null then
    update production_stage_history set comment = p_comment
    where order_id = p_order_id and company_id = v_company_id
    order by changed_at desc
    limit 1;
  end if;
end;
$$;

-- Requirement: "Әр тапсырысқа жауапты шебер" — director/workshop_manager/
-- manager only. Both p_order_id and p_master_id are verified against
-- the caller's own company.
create or replace function set_order_master(p_order_id uuid, p_master_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_company_id uuid := auth_company_id();
begin
  if not (
    auth_is_director() or auth_has_role('workshop_manager') or auth_has_role('manager')
  ) then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  if not exists (select 1 from orders where id = p_order_id and company_id = v_company_id) then
    raise exception 'Тапсырыс табылмады' using errcode = 'P0002';
  end if;

  if not exists (select 1 from profiles where id = p_master_id and company_id = v_company_id) then
    raise exception 'Шебер табылмады' using errcode = 'P0002';
  end if;

  delete from order_assignments
  where order_id = p_order_id and role = 'master';

  insert into order_assignments (order_id, company_id, profile_id, role, assigned_at)
  values (p_order_id, v_company_id, p_master_id, 'master', now());
end;
$$;

-- Backs the master-assignment picker — (user_id, full_name) for
-- active master-role employees in the caller's own company.
create or replace function get_masters()
returns table (user_id uuid, full_name text)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not (
    auth_is_director() or auth_has_role('workshop_manager') or auth_has_role('manager')
  ) then
    return;
  end if;

  return query
    select p.id, p.full_name
    from profiles p
    join user_roles ur on ur.profile_id = p.id
    join roles r on r.id = ur.role_id
    where r.key = 'master' and p.is_active and p.company_id = auth_company_id()
    order by p.full_name;
end;
$$;

-- Requirement: "Уақыт журналдары" — a master starts a timer when
-- beginning work on an order+stage. p_order_id/p_stage_id are verified
-- against the caller's own company.
create or replace function start_time_log(p_order_id uuid, p_stage_id uuid default null)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_company_id uuid := auth_company_id();
  v_id uuid;
begin
  if not auth_has_permission('production.write') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  if not exists (select 1 from orders where id = p_order_id and company_id = v_company_id) then
    raise exception 'Тапсырыс табылмады' using errcode = 'P0002';
  end if;

  if p_stage_id is not null and not exists (
    select 1 from production_stages where id = p_stage_id and company_id = v_company_id
  ) then
    raise exception 'Кезең табылмады' using errcode = 'P0002';
  end if;

  if exists (
    select 1 from production_time_logs
    where employee_id = auth.uid() and ended_at is null
  ) then
    raise exception 'Сізде әлі тоқтатылмаған уақыт журналы бар' using errcode = '23514';
  end if;

  insert into production_time_logs (company_id, order_id, stage_id, employee_id)
  values (v_company_id, p_order_id, p_stage_id, auth.uid())
  returning id into v_id;

  return v_id;
end;
$$;

create or replace function stop_time_log(p_log_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not auth_has_permission('production.write') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  update production_time_logs set ended_at = now()
  where id = p_log_id
    and company_id = auth_company_id()
    and ended_at is null
    and (employee_id = auth.uid() or auth_is_director() or auth_has_role('workshop_manager'));

  if not found then
    raise exception 'Уақыт журналы табылмады' using errcode = 'P0002';
  end if;
end;
$$;
