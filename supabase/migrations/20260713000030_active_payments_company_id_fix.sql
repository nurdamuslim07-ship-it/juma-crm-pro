-- Corrective migration — active_payments company_id fix.
--
-- active_payments (20260713000016_payments_module.sql) was originally
-- defined as `select p.*`, which Postgres expanded to the 19 columns
-- `payments` had at that time. 20260713000024_multi_tenant_company_id_columns.sql
-- later added `payments.company_id`, but a view's exposed columns do
-- not retroactively track an ALTER TABLE ADD COLUMN on its underlying
-- table — active_payments was never recreated, so it still does not
-- expose company_id. 20260713000031_multi_tenant_rpc_analytics.sql
-- (get_analytics_summary()/get_employee_kpis()) depends on
-- active_payments.company_id existing; without this fix those two
-- functions would compile but fail at first call with "column
-- ap.company_id does not exist".
--
-- This recreates the view with an explicit column list — the same 19
-- columns, in the same order, with the exact same filter logic — plus
-- company_id appended as the final column. CREATE OR REPLACE VIEW
-- allows appending columns at the end without breaking column
-- compatibility, so the view's OID, grants, and ownership are all
-- preserved automatically; no other object needs to change.
create or replace view active_payments
  with (security_invoker = true) as
  select
    p.id, p.order_id, p.client_id, p.amount_tiyn, p.method_id, p.cashbox_id,
    p.bank_account_id, p.paid_at, p.recorded_by, p.confirmed_by, p.confirmed_at,
    p.status, p.reversal_of, p.idempotency_key, p.comment, p.receipt_url,
    p.created_offline_at, p.created_at, p.deleted_at, p.company_id
  from payments p
  where p.status = 'confirmed'
    and p.deleted_at is null
    and not exists (
      select 1 from payments r where r.reversal_of = p.id
    );
