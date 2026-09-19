-- Completes the fix started in 20260713000051 (get_analytics_summary).
-- The same bug — `sum(bigint_column)` returns `numeric` in Postgres,
-- but PL/pgSQL's `RETURN QUERY SELECT ...` requires an EXACT type
-- match against the function's declared RETURNS TABLE columns
-- (unlike a plain `LANGUAGE sql` function, which gets an implicit
-- coercion at the function-call boundary — this is why
-- `dashboard_summary()`, also LANGUAGE sql with the identical
-- uncast-sum pattern, was never actually broken) — was found, on
-- review of every SECURITY DEFINER function's return-type
-- declaration against its query body, in two more Analytics-screen
-- RPCs and one Purchases-screen RPC still live in production:
--
--   - get_top_clients(): total_amount_tiyn bigint <- uncast sum()
--   - get_employee_kpis(): payments_recorded_amount_tiyn bigint <- uncast sum()
--   - get_purchase_analytics(): monthly_purchases_tiyn / total_debt_tiyn /
--     total_advance_tiyn, all bigint <- uncast sum()
--
-- All three were confirmed broken live (42804 "structure of query
-- does not match function result type") before this migration. Fixed
-- identically to 20260713000051: add `::bigint` to each broken
-- expression, no other logic changed. `get_purchase_analytics()`'s
-- `avg_unit_price_tiyn numeric` and `get_warehouse_summary()`'s
-- `total_inventory_value_tiyn bigint` (which already has its own
-- `::bigint` cast) were re-checked and are correct as-is.
create or replace function get_top_clients(p_start date, p_end date, p_limit integer default 10)
returns table (
  client_id uuid,
  client_name text,
  orders_count bigint,
  total_amount_tiyn bigint
)
language plpgsql
stable security definer
set search_path to 'public'
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
    select c.id, c.name, count(o.id), coalesce(sum(o.total_amount_tiyn), 0)::bigint
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

create or replace function get_employee_kpis(
  p_start date, p_end date, p_employee_id uuid default null
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
stable security definer
set search_path to 'public'
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
      ), 0)::bigint end
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

create or replace function get_purchase_analytics()
returns table (
  monthly_purchases_tiyn bigint,
  total_debt_tiyn bigint,
  total_advance_tiyn bigint,
  avg_unit_price_tiyn numeric,
  top_materials jsonb,
  supplier_ratings jsonb
)
language plpgsql
stable security definer
set search_path to 'public'
as $$
declare
  v_company_id uuid := auth_company_id();
begin
  if not auth_has_permission('purchases.read') then
    return;
  end if;

  return query
    select
      (
        select coalesce(sum(total_amount_tiyn), 0)::bigint from purchase_orders
        where status = 'received' and received_at >= date_trunc('month', current_date)
          and company_id = v_company_id
      ),
      (
        select coalesce(sum(balance_tiyn), 0)::bigint from partners
        where balance_tiyn > 0 and deleted_at is null and company_id = v_company_id
      ),
      (
        select coalesce(sum(-balance_tiyn), 0)::bigint from partners
        where balance_tiyn < 0 and deleted_at is null and company_id = v_company_id
      ),
      (
        select coalesce(avg(unit_price_tiyn), 0) from purchase_order_items poi
        join purchase_orders po on po.id = poi.purchase_order_id
        where po.status = 'received' and po.company_id = v_company_id
      ),
      coalesce((
        select jsonb_agg(row_to_json(top))
        from (
          select mat.name as material_name,
            sum(poi.quantity) as total_quantity,
            sum(poi.total_price_tiyn) as total_spent_tiyn
          from purchase_order_items poi
          join purchase_orders po on po.id = poi.purchase_order_id
          join materials mat on mat.id = poi.material_id
          where po.status = 'received' and po.company_id = v_company_id
          group by mat.name
          order by sum(poi.total_price_tiyn) desc
          limit 10
        ) top
      ), '[]'::jsonb),
      coalesce((
        select jsonb_agg(row_to_json(sup))
        from (
          select p.id as partner_id, p.display_name, p.trust_rating,
            count(po.id) as total_orders,
            count(po.id) filter (
              where po.received_at is not null
                and po.expected_delivery_date is not null
                and po.received_at::date <= po.expected_delivery_date
            )::numeric / nullif(count(po.id) filter (where po.received_at is not null), 0) as on_time_rate
          from partners p
          join purchase_orders po on po.supplier_partner_id = p.id
          where p.deleted_at is null and p.company_id = v_company_id
          group by p.id
          order by count(po.id) desc
          limit 10
        ) sup
      ), '[]'::jsonb);
end;
$$;
