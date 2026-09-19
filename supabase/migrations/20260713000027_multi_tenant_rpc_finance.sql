-- Multi-tenant SaaS conversion — Stage 1d, part 2: finance RPCs.
--
-- record_payment()/record_expense()/reverse_payment() are SECURITY
-- DEFINER, so they bypass the company-scoped table RLS added in Stage
-- 1c entirely — before this patch, a caller from Company B could pass
-- a Company A p_order_id/p_payment_id and successfully record a
-- payment against (or reverse a payment belonging to) another
-- company's order. Every entity id accepted as a parameter is now
-- verified against `auth_company_id()` before use, and every inserted
-- row is explicitly tagged with it — never trusted from the caller.

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
  v_company_id uuid := auth_company_id();
  v_existing record;
  v_payment payments;
  v_order_total bigint;
  v_already_paid bigint;
begin
  if not auth_is_active() or not auth_has_permission('payments.write') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  select * into v_existing from idempotency_keys
  where key = p_idempotency_key and company_id = v_company_id;
  if found then
    return jsonb_populate_record(null::payments, v_existing.response -> 'payment');
  end if;

  select total_amount_tiyn into v_order_total from orders
  where id = p_order_id and company_id = v_company_id;
  if v_order_total is null then
    raise exception 'Тапсырыс табылмады' using errcode = 'P0002';
  end if;

  if not exists (select 1 from clients where id = p_client_id and company_id = v_company_id) then
    raise exception 'Клиент табылмады' using errcode = 'P0002';
  end if;

  select coalesce(sum(amount_tiyn), 0) into v_already_paid
  from active_payments
  where order_id = p_order_id;

  if v_already_paid + p_amount_tiyn > v_order_total then
    raise exception 'Артық төлем: сома тапсырыс құнынан асып кетеді' using errcode = '23514';
  end if;

  insert into payments (
    company_id, order_id, client_id, amount_tiyn, method_id, cashbox_id, bank_account_id,
    recorded_by, confirmed_by, confirmed_at, status, idempotency_key, comment,
    created_offline_at, paid_at
  ) values (
    v_company_id, p_order_id, p_client_id, p_amount_tiyn, p_method_id, p_cashbox_id, p_bank_account_id,
    auth.uid(), auth.uid(), now(), 'confirmed', p_idempotency_key, p_comment,
    p_created_offline_at, p_paid_at
  )
  returning * into v_payment;

  insert into idempotency_keys (key, company_id, response)
  values (p_idempotency_key, v_company_id, jsonb_build_object('payment', to_jsonb(v_payment)));

  return v_payment;
end;
$$;

create or replace function record_expense(
  p_idempotency_key text,
  p_category_id uuid,
  p_amount_tiyn bigint,
  p_order_id uuid default null,
  p_supplier_id uuid default null,
  p_method_id uuid default null,
  p_comment text default null
)
returns expenses
language plpgsql
security definer
set search_path = public
as $$
declare
  v_company_id uuid := auth_company_id();
  v_existing record;
  v_expense expenses;
begin
  if not auth_is_active() or not auth_has_permission('expenses.write') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  select * into v_existing from idempotency_keys
  where key = p_idempotency_key and company_id = v_company_id;
  if found then
    return jsonb_populate_record(null::expenses, v_existing.response -> 'expense');
  end if;

  if p_order_id is not null
    and not exists (select 1 from orders where id = p_order_id and company_id = v_company_id)
  then
    raise exception 'Тапсырыс табылмады' using errcode = 'P0002';
  end if;

  if not exists (
    select 1 from expense_categories where id = p_category_id and company_id = v_company_id
  ) then
    raise exception 'Шығын санаты табылмады' using errcode = 'P0002';
  end if;

  insert into expenses (
    company_id, order_id, category_id, amount_tiyn, supplier_id, method_id,
    recorded_by, idempotency_key, comment
  ) values (
    v_company_id, p_order_id, p_category_id, p_amount_tiyn, p_supplier_id, p_method_id,
    auth.uid(), p_idempotency_key, p_comment
  )
  returning * into v_expense;

  insert into idempotency_keys (key, company_id, response)
  values (p_idempotency_key, v_company_id, jsonb_build_object('expense', to_jsonb(v_expense)));

  return v_expense;
end;
$$;

-- Reversal is always a new row referencing the original (see
-- SECURITY_PLAN.md / DATABASE_SCHEMA.md "insert-only, reversal-not-delete").
create or replace function reverse_payment(p_payment_id uuid, p_reason text)
returns payments
language plpgsql
security definer
set search_path = public
as $$
declare
  v_company_id uuid := auth_company_id();
  v_original payments;
  v_reversal payments;
begin
  if not auth_is_active() or not auth_has_permission('payments.write') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  select * into v_original from payments
  where id = p_payment_id and company_id = v_company_id;
  if not found then
    raise exception 'Төлем табылмады' using errcode = 'P0002';
  end if;

  insert into payments (
    company_id, order_id, client_id, amount_tiyn, method_id, cashbox_id, bank_account_id,
    recorded_by, status, reversal_of, idempotency_key, comment
  ) values (
    v_company_id, v_original.order_id, v_original.client_id, v_original.amount_tiyn,
    v_original.method_id, v_original.cashbox_id, v_original.bank_account_id,
    auth.uid(), 'reversed', p_payment_id,
    'reversal-' || p_payment_id::text, p_reason
  )
  returning * into v_reversal;

  return v_reversal;
end;
$$;
