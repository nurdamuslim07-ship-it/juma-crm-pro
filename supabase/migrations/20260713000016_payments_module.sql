-- Payments module — see Payments module requirements #9-#14.
--
-- Fixes a real gap in the original reverse_payment() design
-- (20260713000013_idempotent_finance_rpc.sql): reversing a payment
-- inserted a new row with status='reversed' but never touched the
-- ORIGINAL row's status, so a naive `sum(amount_tiyn) where
-- status = 'confirmed'` still counted the reversed payment — the
-- reversal never actually reduced the paid total. active_payments
-- below is the one place "how much has actually been paid on this
-- order" is defined; every other query (dashboard_summary(), the
-- Orders module's per-order paid amount, this module's own totals)
-- reads through it instead of re-deriving the same logic.
create view active_payments
  with (security_invoker = true) as
  select p.*
  from payments p
  where p.status = 'confirmed'
    and p.deleted_at is null
    and not exists (
      select 1 from payments r where r.reversal_of = p.id
    );

-- Replaces the version in 20260713000013_idempotent_finance_rpc.sql:
-- adds p_paid_at (requirement #4), records the payment as immediately
-- confirmed rather than pending (this module has no separate
-- confirm-later step — the person recording it is already permission-
-- gated by payments.write), and rejects the insert outright if it
-- would push the order's total paid past its contract amount
-- (requirement #12 "Артық төлемге жол бермеу").
create or replace function record_payment(
  p_idempotency_key text,
  p_order_id uuid,
  p_client_id uuid,
  p_amount_tiyn bigint,
  p_method_id uuid,
  p_cashbox_id uuid default null,
  p_bank_account_id uuid default null,
  p_comment text default null,
  p_created_offline_at timestamptz default null,
  p_paid_at date default current_date
)
returns payments
language plpgsql
security definer
set search_path = public
as $$
declare
  v_existing record;
  v_payment payments;
  v_order_total bigint;
  v_already_paid bigint;
begin
  if not auth_is_active() or not auth_has_permission('payments.write') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  select * into v_existing from idempotency_keys where key = p_idempotency_key;
  if found then
    return jsonb_populate_record(null::payments, v_existing.response -> 'payment');
  end if;

  select total_amount_tiyn into v_order_total from orders where id = p_order_id;
  if v_order_total is null then
    raise exception 'Тапсырыс табылмады' using errcode = 'P0002';
  end if;

  select coalesce(sum(amount_tiyn), 0) into v_already_paid
  from active_payments
  where order_id = p_order_id;

  if v_already_paid + p_amount_tiyn > v_order_total then
    raise exception 'Артық төлем: сома тапсырыс құнынан асып кетеді' using errcode = '23514';
  end if;

  insert into payments (
    order_id, client_id, amount_tiyn, method_id, cashbox_id, bank_account_id,
    recorded_by, confirmed_by, confirmed_at, status, idempotency_key, comment,
    created_offline_at, paid_at
  ) values (
    p_order_id, p_client_id, p_amount_tiyn, p_method_id, p_cashbox_id, p_bank_account_id,
    auth.uid(), auth.uid(), now(), 'confirmed', p_idempotency_key, p_comment,
    p_created_offline_at, p_paid_at
  )
  returning * into v_payment;

  insert into idempotency_keys (key, response)
  values (p_idempotency_key, jsonb_build_object('payment', to_jsonb(v_payment)));

  return v_payment;
end;
$$;

-- Requirement #13 "Төлемді өңдеу": limited-field edit. Amount, order,
-- client, and status are exactly the fields that must never change
-- after the fact (integrity of the paid total, and of
-- active_payments' reversal bookkeeping) — this trigger enforces that
-- regardless of what the payments_update RLS policy (see
-- 20260713000012_rls_policies.sql) allows at the row level. Only
-- method/paid_at/comment/receipt_url/deleted_at (soft delete) may
-- change via UPDATE.
create function prevent_payment_tamper()
returns trigger
language plpgsql
as $$
begin
  if NEW.amount_tiyn is distinct from OLD.amount_tiyn
    or NEW.order_id is distinct from OLD.order_id
    or NEW.client_id is distinct from OLD.client_id
    or NEW.status is distinct from OLD.status then
    raise exception 'Төлем сомасын немесе тапсырысын өзгертуге болмайды' using errcode = '42501';
  end if;
  return NEW;
end;
$$;

create trigger payments_prevent_tamper
  before update on payments
  for each row execute function prevent_payment_tamper();

-- Requirement #8 "Чек немесе файл тіркеуге дайын архитектура" — a real
-- (not stubbed) private Storage bucket for payment receipts, with RLS
-- on storage.objects mirroring the payments.read/payments.write
-- permission gate rather than being world-readable.
insert into storage.buckets (id, name, public)
values ('receipts', 'receipts', false)
on conflict (id) do nothing;

create policy "receipts_read_with_payments_permission"
  on storage.objects for select
  using (bucket_id = 'receipts' and auth_has_permission('payments.read'));

create policy "receipts_upload_with_payments_permission"
  on storage.objects for insert
  with check (bucket_id = 'receipts' and auth_has_permission('payments.write'));

create policy "receipts_delete_director"
  on storage.objects for delete
  using (bucket_id = 'receipts' and auth_is_director());

-- Supersedes the version in 20260713000014_dashboard_summary.sql —
-- the "payments received" KPI must read through active_payments too
-- (see this file's top comment), otherwise a reversed payment would
-- still inflate the director's dashboard total.
create or replace function dashboard_summary()
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
    (select coalesce(sum(amount_tiyn), 0) from active_payments),
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
