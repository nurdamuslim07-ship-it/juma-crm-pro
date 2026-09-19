-- Multi-tenant SaaS conversion — Stage 1d, part 5: analytics RPCs.
--
-- get_analytics_summary()/get_employee_kpis()/get_top_clients() are
-- SECURITY DEFINER and aggregate across orders/clients/employees/
-- active_payments with no company filter at all before this patch —
-- every KPI/turnover figure was computed across every tenant combined.

create or replace function get_analytics_summary(
  p_start date,
  p_end date
)
returns table (
  turnover_tiyn bigint,
  orders_count bigint,
  orders_by_status jsonb,
  installed_count bigint,
  new_clients_count bigint,
  avg_order_amount_tiyn bigint,
  payments_received_tiyn bigint,
  remaining_debt_tiyn bigint,
  payment_method_stats jsonb
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_company_id uuid := auth_company_id();
  v_sales boolean := auth_has_permission('analytics.read_sales');
  v_financial boolean := auth_has_permission('analytics.read_financial');
begin
  if not auth_is_active() then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  return query
    select
      case when v_sales then (
        select coalesce(sum(o.total_amount_tiyn), 0) from orders o
        where o.deleted_at is null and o.company_id = v_company_id
          and o.created_at::date between p_start and p_end
      ) end,
      case when v_sales then (
        select count(*) from orders o
        where o.deleted_at is null and o.company_id = v_company_id
          and o.created_at::date between p_start and p_end
      ) end,
      case when v_sales then (
        select jsonb_object_agg(s.status, s.cnt) from (
          select o.status, count(*) as cnt from orders o
          where o.deleted_at is null and o.company_id = v_company_id
            and o.created_at::date between p_start and p_end
          group by o.status
        ) s
      ) end,
      case when v_sales then (
        select count(*) from orders o
        where o.deleted_at is null and o.company_id = v_company_id
          and o.status = 'installed'
          and o.installation_date between p_start and p_end
      ) end,
      case when v_sales then (
        select count(*) from clients c
        where c.deleted_at is null and c.company_id = v_company_id
          and c.created_at::date between p_start and p_end
      ) end,
      case when v_sales then (
        select round(avg(o.total_amount_tiyn))::bigint from orders o
        where o.deleted_at is null and o.company_id = v_company_id
          and o.created_at::date between p_start and p_end
      ) end,
      case when v_financial then (
        select coalesce(sum(ap.amount_tiyn), 0) from active_payments ap
        where ap.company_id = v_company_id and ap.paid_at between p_start and p_end
      ) end,
      -- Remaining debt is a current snapshot, not period-bounded — same
      -- convention as the Dashboard module's "Клиент қарызы" tile.
      case when v_financial then (
        select greatest(
          coalesce(sum(o.total_amount_tiyn), 0) - coalesce((
            select sum(ap.amount_tiyn) from active_payments ap
            join orders o2 on o2.id = ap.order_id
            where o2.deleted_at is null and o2.company_id = v_company_id
          ), 0),
          0
        )
        from orders o where o.deleted_at is null and o.company_id = v_company_id
      ) end,
      case when v_financial then (
        select jsonb_object_agg(m.method_key, jsonb_build_object(
          'count', m.cnt, 'amount_tiyn', m.amount_tiyn
        )) from (
          select pm.key as method_key, count(*) as cnt, sum(ap.amount_tiyn) as amount_tiyn
          from active_payments ap
          join payment_methods pm on pm.id = ap.method_id
          where ap.company_id = v_company_id and ap.paid_at between p_start and p_end
          group by pm.key
        ) m
      ) end;
end;
$$;

-- Per-employee KPI — self-only unless the caller holds
-- analytics.read_all_kpi (director/manager); the payments-recorded
-- figures are additionally gated per-row by analytics.read_financial
-- OR being that row's own employee.
create or replace function get_employee_kpis(
  p_start date,
  p_end date,
  p_employee_id uuid default null
)
returns table (
  employee_id uuid,
  full_name text,
  role_key role_key,
  orders_assigned_count bigint,
  orders_completed_count bigint,
  payments_recorded_count bigint,
  payments_recorded_amount_tiyn bigint
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_company_id uuid := auth_company_id();
  v_all boolean := auth_has_permission('analytics.read_all_kpi');
  v_financial boolean := auth_has_permission('analytics.read_financial');
  v_target uuid := case when v_all then p_employee_id else auth.uid() end;
begin
  if not auth_is_active() then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  return query
    select
      e.user_id,
      p.full_name,
      r.role_key,
      coalesce((
        select count(distinct o.id) from orders o
        left join order_assignments oa on oa.order_id = o.id and oa.profile_id = e.user_id
        where o.deleted_at is null and o.company_id = v_company_id
          and o.created_at::date between p_start and p_end
          and (o.responsible_employee_id = e.user_id or oa.profile_id = e.user_id)
      ), 0),
      coalesce((
        select count(distinct o.id) from orders o
        left join order_assignments oa on oa.order_id = o.id and oa.profile_id = e.user_id
        where o.deleted_at is null and o.company_id = v_company_id
          and o.status = 'installed'
          and o.installation_date between p_start and p_end
          and (o.responsible_employee_id = e.user_id or oa.profile_id = e.user_id)
      ), 0),
      case when v_financial or e.user_id = auth.uid() then coalesce((
        select count(*) from active_payments ap
        where ap.company_id = v_company_id
          and ap.recorded_by = e.user_id and ap.paid_at between p_start and p_end
      ), 0) end,
      case when v_financial or e.user_id = auth.uid() then coalesce((
        select sum(ap.amount_tiyn) from active_payments ap
        where ap.company_id = v_company_id
          and ap.recorded_by = e.user_id and ap.paid_at between p_start and p_end
      ), 0) end
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
      and (v_target is null or e.user_id = v_target)
    order by p.full_name;
end;
$$;

-- "Ең көп тапсырыс беретін клиенттер" — director/manager only
-- (analytics.read_sales); returns an empty set for anyone else.
create or replace function get_top_clients(
  p_start date,
  p_end date,
  p_limit int default 10
)
returns table (
  client_id uuid,
  client_name text,
  orders_count bigint,
  total_amount_tiyn bigint
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_company_id uuid := auth_company_id();
begin
  if not auth_is_active() then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  if not auth_has_permission('analytics.read_sales') then
    return;
  end if;

  return query
    select c.id, c.name, count(o.id), coalesce(sum(o.total_amount_tiyn), 0)
    from clients c
    join orders o on o.client_id = c.id
    where c.deleted_at is null
      and c.company_id = v_company_id
      and o.deleted_at is null
      and o.company_id = v_company_id
      and o.created_at::date between p_start and p_end
    group by c.id, c.name
    order by coalesce(sum(o.total_amount_tiyn), 0) desc
    limit greatest(p_limit, 0);
end;
$$;
