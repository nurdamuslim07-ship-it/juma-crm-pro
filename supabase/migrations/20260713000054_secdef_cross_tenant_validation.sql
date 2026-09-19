-- Priority 7: full review of all 73 SECURITY DEFINER functions for
-- cross-tenant entity-id validation (every company_id/employee_id/
-- partner_id/supplier_id/order_id/payment_id parameter must be
-- verified against auth_company_id() before use). Confirmed the vast
-- majority already do this correctly (move_order_to_stage,
-- set_order_master, start_time_log, create_hold, issue_materials,
-- reserve_material_for_order, add_partner_document, etc. — all
-- validate every entity id they accept). Seven gaps were found and
-- are fixed here, each with `create or replace function` preserving
-- every other line of existing logic unchanged.
--
-- 1. record_payment(): p_order_id/p_client_id were already validated
--    (20260713000027); p_method_id/p_cashbox_id/p_bank_account_id
--    were not. A caller could reference another company's payment
--    method/cashbox/bank account id on their own payment row — the
--    row itself stays correctly company-scoped, but any future join
--    without its own re-check would leak the other company's method/
--    cashbox/bank-account name.
-- 2. record_expense(): p_order_id/p_category_id were already
--    validated; p_supplier_id/p_method_id were not. Same risk shape.
-- 3. record_supplier_payment(): p_partner_id/p_supplier_invoice_id
--    were already validated; p_method_id/p_cashbox_id/p_bank_account_id
--    were not. Same risk shape.
-- 4. receive_materials(): p_material_id/p_location_id were already
--    validated; p_supplier_partner_id (optional) was not.
-- 5/6. create_purchase_order() / update_purchase_order():
--    p_supplier_partner_id and each item's material_id were already
--    validated; p_responsible_employee_id and each item's location_id
--    were not.
-- 7. provision_employee_profile(): only checked that the target
--    profile exists at all — not that it is *unclaimed*
--    (company_id is null). Called directly (not only via the
--    create-employee Edge Function's own freshly-created user), a
--    director could pass ANY existing profile id — including one
--    already belonging to a different company — and this would
--    silently reassign that real account into the caller's own
--    company with status='active'. This is the most serious of the
--    seven: a genuine account-hijack path, not just a data-reference
--    leak. Fixed by requiring the target profile's company_id to
--    already be null (i.e. a fresh signup awaiting provisioning,
--    which is the only case this function is designed for).

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

  if not exists (
    select 1 from payment_methods where id = p_method_id and company_id = v_company_id
  ) then
    raise exception 'Төлем әдісі табылмады' using errcode = 'P0002';
  end if;

  if p_cashbox_id is not null and not exists (
    select 1 from cashboxes where id = p_cashbox_id and company_id = v_company_id
  ) then
    raise exception 'Кассa табылмады' using errcode = 'P0002';
  end if;

  if p_bank_account_id is not null and not exists (
    select 1 from bank_accounts where id = p_bank_account_id and company_id = v_company_id
  ) then
    raise exception 'Банк шоты табылмады' using errcode = 'P0002';
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

  if p_supplier_id is not null and not exists (
    select 1 from partners where id = p_supplier_id and company_id = v_company_id
  ) then
    raise exception 'Жеткізуші табылмады' using errcode = 'P0002';
  end if;

  if p_method_id is not null and not exists (
    select 1 from payment_methods where id = p_method_id and company_id = v_company_id
  ) then
    raise exception 'Төлем әдісі табылмады' using errcode = 'P0002';
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

create or replace function record_supplier_payment(
  p_idempotency_key text,
  p_partner_id uuid,
  p_amount_tiyn bigint,
  p_method_id uuid,
  p_supplier_invoice_id uuid default null,
  p_cashbox_id uuid default null,
  p_bank_account_id uuid default null,
  p_paid_at date default current_date,
  p_comment text default null
)
returns supplier_payments
language plpgsql
security definer
set search_path = public
as $$
declare
  v_company_id uuid := auth_company_id();
  v_existing record;
  v_payment supplier_payments;
begin
  if not auth_has_permission('purchases.pay') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  select * into v_existing from idempotency_keys
  where key = p_idempotency_key and company_id = v_company_id;
  if found then
    return jsonb_populate_record(null::supplier_payments, v_existing.response -> 'payment');
  end if;

  if not exists (select 1 from partners where id = p_partner_id and company_id = v_company_id) then
    raise exception 'Серіктес табылмады' using errcode = 'P0002';
  end if;

  if p_supplier_invoice_id is not null and not exists (
    select 1 from supplier_invoices where id = p_supplier_invoice_id and company_id = v_company_id
  ) then
    raise exception 'Шот-фактура табылмады' using errcode = 'P0002';
  end if;

  if not exists (
    select 1 from payment_methods where id = p_method_id and company_id = v_company_id
  ) then
    raise exception 'Төлем әдісі табылмады' using errcode = 'P0002';
  end if;

  if p_cashbox_id is not null and not exists (
    select 1 from cashboxes where id = p_cashbox_id and company_id = v_company_id
  ) then
    raise exception 'Кассa табылмады' using errcode = 'P0002';
  end if;

  if p_bank_account_id is not null and not exists (
    select 1 from bank_accounts where id = p_bank_account_id and company_id = v_company_id
  ) then
    raise exception 'Банк шоты табылмады' using errcode = 'P0002';
  end if;

  insert into supplier_payments (
    company_id, partner_id, supplier_invoice_id, amount_tiyn, method_id, cashbox_id,
    bank_account_id, paid_at, recorded_by, status, idempotency_key, comment
  ) values (
    v_company_id, p_partner_id, p_supplier_invoice_id, p_amount_tiyn, p_method_id, p_cashbox_id,
    p_bank_account_id, p_paid_at, auth.uid(), 'confirmed', p_idempotency_key, p_comment
  )
  returning * into v_payment;

  insert into idempotency_keys (key, company_id, response)
  values (p_idempotency_key, v_company_id, jsonb_build_object('payment', to_jsonb(v_payment)));

  update partners set balance_tiyn = balance_tiyn - p_amount_tiyn
  where id = p_partner_id and company_id = v_company_id;

  if p_supplier_invoice_id is not null then
    perform recalc_supplier_invoice_status(p_supplier_invoice_id);
  end if;

  return v_payment;
end;
$$;

create or replace function receive_materials(
  p_material_id uuid,
  p_location_id uuid,
  p_quantity numeric,
  p_cost_per_unit_tiyn bigint default 0,
  p_batch_number text default null,
  p_supplier_partner_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_company_id uuid := auth_company_id();
  v_batch_id uuid;
begin
  if not auth_has_permission('warehouse.write') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;
  if p_quantity <= 0 then
    raise exception 'Мөлшер оң сан болуы керек' using errcode = '23514';
  end if;

  if not exists (
    select 1 from materials where id = p_material_id and company_id = v_company_id
  ) then
    raise exception 'Материал табылмады' using errcode = 'P0002';
  end if;

  if not exists (
    select 1 from warehouse_locations where id = p_location_id and company_id = v_company_id
  ) then
    raise exception 'Қойма орны табылмады' using errcode = 'P0002';
  end if;

  if p_supplier_partner_id is not null and not exists (
    select 1 from partners where id = p_supplier_partner_id and company_id = v_company_id
  ) then
    raise exception 'Жеткізуші табылмады' using errcode = 'P0002';
  end if;

  insert into inventory_batches (
    company_id, material_id, location_id, batch_number, quantity_received,
    quantity_remaining, cost_per_unit_tiyn, supplier_partner_id, created_by
  ) values (
    v_company_id, p_material_id, p_location_id, p_batch_number, p_quantity,
    p_quantity, p_cost_per_unit_tiyn, p_supplier_partner_id, auth.uid()
  ) returning id into v_batch_id;

  insert into inventory_transactions (
    company_id, material_id, location_id, delta_quantity, kind, performed_by
  )
  values (v_company_id, p_material_id, p_location_id, p_quantity, 'receive', auth.uid());

  insert into inventory_balances (company_id, material_id, location_id, quantity, reserved_quantity)
  values (v_company_id, p_material_id, p_location_id, p_quantity, 0)
  on conflict (material_id, location_id)
    do update set quantity = inventory_balances.quantity + excluded.quantity;

  return v_batch_id;
end;
$$;

create or replace function create_purchase_order(
  p_order_number text,
  p_supplier_partner_id uuid,
  p_items jsonb,
  p_responsible_employee_id uuid default null,
  p_expected_delivery_date date default null,
  p_delivery_cost_tiyn bigint default 0,
  p_vat_tiyn bigint default 0,
  p_discount_tiyn bigint default 0,
  p_comment text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_company_id uuid := auth_company_id();
  v_id uuid;
  v_item record;
begin
  if not auth_has_permission('purchases.write') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  if not exists (
    select 1 from partners where id = p_supplier_partner_id and company_id = v_company_id
  ) then
    raise exception 'Жеткізуші табылмады' using errcode = 'P0002';
  end if;

  if p_responsible_employee_id is not null and not exists (
    select 1 from profiles where id = p_responsible_employee_id and company_id = v_company_id
  ) then
    raise exception 'Жауапты қызметкер табылмады' using errcode = 'P0002';
  end if;

  insert into purchase_orders (
    company_id, order_number, supplier_partner_id, responsible_employee_id,
    expected_delivery_date, delivery_cost_tiyn, vat_tiyn, discount_tiyn,
    comment, created_by
  ) values (
    v_company_id, p_order_number, p_supplier_partner_id, p_responsible_employee_id,
    p_expected_delivery_date, p_delivery_cost_tiyn, p_vat_tiyn, p_discount_tiyn,
    p_comment, auth.uid()
  ) returning id into v_id;

  for v_item in
    select * from jsonb_to_recordset(p_items) as x(
      material_id uuid, quantity numeric, unit text,
      unit_price_tiyn bigint, location_id uuid
    )
  loop
    if not exists (
      select 1 from materials where id = v_item.material_id and company_id = v_company_id
    ) then
      raise exception 'Материал табылмады' using errcode = 'P0002';
    end if;

    if v_item.location_id is not null and not exists (
      select 1 from warehouse_locations where id = v_item.location_id and company_id = v_company_id
    ) then
      raise exception 'Қойма орны табылмады' using errcode = 'P0002';
    end if;

    insert into purchase_order_items (
      company_id, purchase_order_id, material_id, quantity, unit, unit_price_tiyn, location_id
    ) values (
      v_company_id, v_id, v_item.material_id, v_item.quantity, v_item.unit,
      v_item.unit_price_tiyn, v_item.location_id
    );
  end loop;

  return v_id;
end;
$$;

create or replace function update_purchase_order(
  p_id uuid,
  p_supplier_partner_id uuid,
  p_items jsonb,
  p_responsible_employee_id uuid default null,
  p_expected_delivery_date date default null,
  p_delivery_cost_tiyn bigint default 0,
  p_vat_tiyn bigint default 0,
  p_discount_tiyn bigint default 0,
  p_comment text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_company_id uuid := auth_company_id();
  v_status purchase_order_status;
  v_item record;
begin
  if not auth_has_permission('purchases.write') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  select status into v_status from purchase_orders where id = p_id and company_id = v_company_id;
  if not found then
    raise exception 'Тапсырыс табылмады' using errcode = 'P0002';
  end if;
  if v_status <> 'draft' then
    raise exception 'Тек жоба (draft) күйіндегі тапсырысты өңдеуге болады' using errcode = '42501';
  end if;

  if not exists (
    select 1 from partners where id = p_supplier_partner_id and company_id = v_company_id
  ) then
    raise exception 'Жеткізуші табылмады' using errcode = 'P0002';
  end if;

  if p_responsible_employee_id is not null and not exists (
    select 1 from profiles where id = p_responsible_employee_id and company_id = v_company_id
  ) then
    raise exception 'Жауапты қызметкер табылмады' using errcode = 'P0002';
  end if;

  update purchase_orders set
    supplier_partner_id = p_supplier_partner_id,
    responsible_employee_id = p_responsible_employee_id,
    expected_delivery_date = p_expected_delivery_date,
    delivery_cost_tiyn = p_delivery_cost_tiyn,
    vat_tiyn = p_vat_tiyn,
    discount_tiyn = p_discount_tiyn,
    comment = p_comment
  where id = p_id and company_id = v_company_id;

  delete from purchase_order_items where purchase_order_id = p_id;

  for v_item in
    select * from jsonb_to_recordset(p_items) as x(
      material_id uuid, quantity numeric, unit text,
      unit_price_tiyn bigint, location_id uuid
    )
  loop
    if not exists (
      select 1 from materials where id = v_item.material_id and company_id = v_company_id
    ) then
      raise exception 'Материал табылмады' using errcode = 'P0002';
    end if;

    if v_item.location_id is not null and not exists (
      select 1 from warehouse_locations where id = v_item.location_id and company_id = v_company_id
    ) then
      raise exception 'Қойма орны табылмады' using errcode = 'P0002';
    end if;

    insert into purchase_order_items (
      company_id, purchase_order_id, material_id, quantity, unit, unit_price_tiyn, location_id
    ) values (
      v_company_id, p_id, v_item.material_id, v_item.quantity, v_item.unit,
      v_item.unit_price_tiyn, v_item.location_id
    );
  end loop;
end;
$$;

create or replace function provision_employee_profile(p_profile_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_company_id uuid;
begin
  if not auth_is_director() then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  v_company_id := auth_company_id();
  if v_company_id is null then
    raise exception 'Компания анықталмады' using errcode = '23514';
  end if;

  if not exists (
    select 1 from profiles where id = p_profile_id and company_id is null
  ) then
    raise exception 'Профиль табылмады' using errcode = 'P0002';
  end if;

  perform set_config('app.bypass_profile_guard', 'on', true);
  update profiles
  set company_id = v_company_id, status = 'active'
  where id = p_profile_id;

  return v_company_id;
end;
$$;
