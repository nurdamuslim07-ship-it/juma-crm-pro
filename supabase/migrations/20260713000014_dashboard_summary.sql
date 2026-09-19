-- Dashboard aggregate RPC — a single round-trip for the KPI tiles
-- described in the master spec's role-specific dashboards
-- (director/manager/workshop/employee/accountant).
--
-- SECURITY INVOKER (not DEFINER): every subquery runs under the
-- calling user's own RLS policies, so e.g. a role without
-- orders.read_financial simply sees 0 rows in the orders subqueries
-- (coalesce → 0) rather than the function needing its own separate
-- permission check — the same DB-level enforcement as every other
-- table, per ROLES_AND_PERMISSIONS.md, not a special case.
create function dashboard_summary()
returns table (
  active_orders_count bigint,
  delayed_orders_count bigint,
  completed_this_month_count bigint,
  total_contract_amount_tiyn bigint,
  payments_received_tiyn bigint,
  expenses_tiyn bigint,
  low_stock_materials_count bigint,
  upcoming_deliveries_count bigint,
  my_open_tasks_count bigint,
  my_today_tasks_count bigint
)
language sql
stable
security invoker
set search_path = public
as $$
  select
    -- 'installed' is the terminal status of the owner's 5-stage
    -- workflow (see 20260713000001_extensions_and_enums.sql) — active
    -- means "not yet installed".
    (select count(*) from orders
      where status != 'installed' and deleted_at is null),
    (select count(*) from orders
      where planned_completion_date < current_date
        and status != 'installed'
        and deleted_at is null),
    (select count(*) from orders
      where status = 'installed'
        and updated_at >= date_trunc('month', current_date)
        and deleted_at is null),
    (select coalesce(sum(total_amount_tiyn), 0) from orders where deleted_at is null),
    (select coalesce(sum(amount_tiyn), 0) from payments where status = 'confirmed'),
    (select coalesce(sum(amount_tiyn), 0) from expenses where approval_status = 'approved'),
    (select count(*) from materials m
      join inventory_balances ib on ib.material_id = m.id
      where ib.quantity <= m.min_quantity),
    (select count(*) from deliveries
      where status = 'scheduled' and scheduled_at >= now()),
    (select count(*) from tasks
      where assigned_to = auth.uid() and status != 'done'),
    (select count(*) from tasks
      where assigned_to = auth.uid() and status != 'done'
        and deadline::date = current_date);
$$;
