-- Idempotent write RPCs for payments/expenses — implements the
-- OFFLINE_PWA_PLAN.md design: the client always calls these functions
-- with a client-generated idempotency key (UUID) instead of inserting
-- into `payments`/`expenses` directly. A retried call with the same
-- key returns the original result instead of creating a duplicate row
-- — this is what prevents a flaky offline sync from double-charging a
-- client's debt (see RISK_REGISTER.md risk #4).
--
-- SECURITY DEFINER so the function can write to idempotency_keys (which
-- has no direct client policy) but every permission check below still
-- runs against the calling user via auth_has_permission()/auth.uid().

create function record_payment(
  p_idempotency_key text,
  p_order_id uuid,
  p_client_id uuid,
  p_amount_tiyn bigint,
  p_method_id uuid,
  p_cashbox_id uuid default null,
  p_bank_account_id uuid default null,
  p_comment text default null,
  p_created_offline_at timestamptz default null
)
returns payments
language plpgsql
security definer
set search_path = public
as $$
declare
  v_existing record;
  v_payment payments;
begin
  if not auth_is_active() or not auth_has_permission('payments.write') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  select * into v_existing from idempotency_keys where key = p_idempotency_key;
  if found then
    return jsonb_populate_record(null::payments, v_existing.response -> 'payment');
  end if;

  insert into payments (
    order_id, client_id, amount_tiyn, method_id, cashbox_id, bank_account_id,
    recorded_by, status, idempotency_key, comment, created_offline_at
  ) values (
    p_order_id, p_client_id, p_amount_tiyn, p_method_id, p_cashbox_id, p_bank_account_id,
    auth.uid(), 'pending', p_idempotency_key, p_comment, p_created_offline_at
  )
  returning * into v_payment;

  insert into idempotency_keys (key, response)
  values (p_idempotency_key, jsonb_build_object('payment', to_jsonb(v_payment)));

  return v_payment;
end;
$$;

create function record_expense(
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
  v_existing record;
  v_expense expenses;
begin
  if not auth_is_active() or not auth_has_permission('expenses.write') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  select * into v_existing from idempotency_keys where key = p_idempotency_key;
  if found then
    return jsonb_populate_record(null::expenses, v_existing.response -> 'expense');
  end if;

  insert into expenses (
    order_id, category_id, amount_tiyn, supplier_id, method_id,
    recorded_by, idempotency_key, comment
  ) values (
    p_order_id, p_category_id, p_amount_tiyn, p_supplier_id, p_method_id,
    auth.uid(), p_idempotency_key, p_comment
  )
  returning * into v_expense;

  insert into idempotency_keys (key, response)
  values (p_idempotency_key, jsonb_build_object('expense', to_jsonb(v_expense)));

  return v_expense;
end;
$$;

-- Reversal is always a new row referencing the original (see
-- SECURITY_PLAN.md / DATABASE_SCHEMA.md "insert-only, reversal-not-delete").
create function reverse_payment(p_payment_id uuid, p_reason text)
returns payments
language plpgsql
security definer
set search_path = public
as $$
declare
  v_original payments;
  v_reversal payments;
begin
  if not auth_is_active() or not auth_has_permission('payments.write') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  select * into v_original from payments where id = p_payment_id;
  if not found then
    raise exception 'Төлем табылмады' using errcode = 'P0002';
  end if;

  insert into payments (
    order_id, client_id, amount_tiyn, method_id, cashbox_id, bank_account_id,
    recorded_by, status, reversal_of, idempotency_key, comment
  ) values (
    v_original.order_id, v_original.client_id, v_original.amount_tiyn,
    v_original.method_id, v_original.cashbox_id, v_original.bank_account_id,
    auth.uid(), 'reversed', p_payment_id,
    'reversal-' || p_payment_id::text, p_reason
  )
  returning * into v_reversal;

  return v_reversal;
end;
$$;
