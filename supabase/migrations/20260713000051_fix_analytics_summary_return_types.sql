-- Fixes the confirmed root cause of "Analytics screen is completely
-- broken": every call to get_analytics_summary() fails with
--   "structure of query does not match function result type"
--   "Returned type numeric does not match expected type bigint in column 1"
--
-- Root cause: `sum(bigint_column)` in Postgres returns `numeric`, not
-- `bigint` (the aggregate promotes to numeric to avoid overflow —
-- standard Postgres behaviour, not a bug in the column type itself).
-- The function's declared return type for 3 of its 9 columns is
-- `bigint`, but their query bodies were `coalesce(sum(...), 0)` with
-- no cast back to bigint:
--   - turnover_tiyn        <- coalesce(sum(o.total_amount_tiyn), 0)
--   - payments_received_tiyn <- coalesce(sum(ap.amount_tiyn), 0)
--   - remaining_debt_tiyn  <- greatest(coalesce(sum(...),0) - coalesce(sum(...),0), 0)
-- A 4th money column, avg_order_amount_tiyn, already does this
-- correctly (`round(avg(...))::bigint`) — proving the cast is the
-- established, correct pattern in this same function, just missed on
-- the other three. This migration adds the same `::bigint` cast to
-- all three broken expressions. No business logic changes: the
-- numeric values themselves are unchanged (money stays exact,
-- tiyn-integer semantics preserved per CLAUDE.md — a cast from an
-- already-integral numeric, since tiyn sums are always whole numbers,
-- never introduces rounding), only the SQL type declaration now
-- matches what the query actually produces.
create or replace function get_analytics_summary(p_start date, p_end date)
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
stable security definer
set search_path to 'public'
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
        select coalesce(sum(o.total_amount_tiyn), 0)::bigint from orders o
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
        select coalesce(sum(ap.amount_tiyn), 0)::bigint from active_payments ap
        where ap.company_id = v_company_id and ap.paid_at between p_start and p_end
      ) end,
      case when v_financial then (
        select greatest(
          coalesce(sum(o.total_amount_tiyn), 0) - coalesce((
            select sum(ap.amount_tiyn) from active_payments ap
            join orders o2 on o2.id = ap.order_id
            where o2.deleted_at is null and o2.company_id = v_company_id
          ), 0),
          0
        )::bigint
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
