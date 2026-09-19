-- Multi-tenant SaaS conversion — Stage 1d, part 8: purchases RPCs +
-- the two functions this module itself superseded (`get_materials()`,
-- `get_order_production_detail()`) — patched here since this file's
-- `create or replace` is the one currently live, not the earlier
-- Warehouse/Production module versions.

create or replace function get_materials(
  p_category_id uuid default null,
  p_search text default null,
  p_low_stock_only boolean default false
)
returns table (
  material_id uuid,
  name text,
  category_id uuid,
  category_key text,
  category_name_kk text,
  unit text,
  min_quantity numeric,
  cost_per_unit_tiyn bigint,
  barcode text,
  total_quantity numeric,
  total_reserved numeric,
  available_quantity numeric,
  is_low_stock boolean,
  preferred_partner_id uuid,
  preferred_partner_name text,
  preferred_partner_phone text,
  preferred_partner_whatsapp text
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_company_id uuid := auth_company_id();
begin
  if not (
    auth_has_permission('warehouse.read')
    or auth_has_permission('purchases.read')
    or auth_has_permission('purchases.write')
  ) then
    return;
  end if;

  return query
    select
      m.id,
      m.name,
      m.category_id,
      mc.key,
      mc.name_kk,
      m.unit,
      m.min_quantity,
      m.cost_per_unit_tiyn,
      m.barcode,
      coalesce(sum(ib.quantity), 0),
      coalesce(sum(ib.reserved_quantity), 0),
      coalesce(sum(ib.quantity - ib.reserved_quantity), 0),
      coalesce(sum(ib.quantity - ib.reserved_quantity), 0) < m.min_quantity,
      m.preferred_partner_id,
      p.display_name,
      p.phone,
      p.whatsapp_phone
    from materials m
    left join material_categories mc on mc.id = m.category_id
    left join inventory_balances ib on ib.material_id = m.id
    left join partners p on p.id = m.preferred_partner_id
    where m.company_id = v_company_id
      and (p_category_id is null or m.category_id = p_category_id)
      and (
        p_search is null or p_search = '' or
        m.name ilike '%' || p_search || '%' or
        m.barcode = p_search
      )
    group by m.id, mc.key, mc.name_kk, p.display_name, p.phone, p.whatsapp_phone
    having (
      not p_low_stock_only
      or coalesce(sum(ib.quantity - ib.reserved_quantity), 0) < m.min_quantity
    )
    order by m.name;
end;
$$;

create or replace function get_purchase_orders(
  p_status purchase_order_status default null,
  p_supplier_partner_id uuid default null,
  p_search text default null,
  p_limit int default 50,
  p_offset int default 0
)
returns table (
  id uuid,
  order_number text,
  supplier_partner_id uuid,
  supplier_name text,
  status purchase_order_status,
  responsible_employee_id uuid,
  responsible_employee_name text,
  expected_delivery_date date,
  items_count bigint,
  total_amount_tiyn bigint,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_company_id uuid := auth_company_id();
begin
  if not auth_has_permission('purchases.read') then
    return;
  end if;

  return query
    select
      po.id, po.order_number, po.supplier_partner_id, p.display_name,
      po.status, po.responsible_employee_id, e.full_name,
      po.expected_delivery_date,
      (select count(*) from purchase_order_items poi where poi.purchase_order_id = po.id),
      po.total_amount_tiyn, po.created_at
    from purchase_orders po
    join partners p on p.id = po.supplier_partner_id
    left join profiles e on e.id = po.responsible_employee_id
    where po.company_id = v_company_id
      and (p_status is null or po.status = p_status)
      and (p_supplier_partner_id is null or po.supplier_partner_id = p_supplier_partner_id)
      and (
        p_search is null or p_search = '' or
        po.order_number ilike '%' || p_search || '%' or
        p.display_name ilike '%' || p_search || '%'
      )
    order by po.created_at desc
    limit greatest(p_limit, 0)
    offset greatest(p_offset, 0);
end;
$$;

create or replace function get_purchase_order_detail(p_id uuid)
returns table (
  id uuid,
  order_number text,
  supplier_partner_id uuid,
  supplier_name text,
  supplier_phone text,
  status purchase_order_status,
  responsible_employee_id uuid,
  responsible_employee_name text,
  expected_delivery_date date,
  delivery_cost_tiyn bigint,
  vat_tiyn bigint,
  discount_tiyn bigint,
  subtotal_tiyn bigint,
  total_amount_tiyn bigint,
  comment text,
  rejection_reason text,
  created_at timestamptz,
  approved_at timestamptz,
  received_at timestamptz,
  items jsonb
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not auth_has_permission('purchases.read') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  return query
    select
      po.id, po.order_number, po.supplier_partner_id, p.display_name, p.phone,
      po.status, po.responsible_employee_id, e.full_name,
      po.expected_delivery_date, po.delivery_cost_tiyn, po.vat_tiyn,
      po.discount_tiyn, po.subtotal_tiyn, po.total_amount_tiyn,
      po.comment, po.rejection_reason, po.created_at, po.approved_at, po.received_at,
      coalesce((
        select jsonb_agg(jsonb_build_object(
          'item_id', poi.id,
          'material_id', poi.material_id,
          'material_name', mat.name,
          'quantity', poi.quantity,
          'unit', poi.unit,
          'unit_price_tiyn', poi.unit_price_tiyn,
          'total_price_tiyn', poi.total_price_tiyn,
          'location_id', poi.location_id,
          'location_name', wl.name,
          'batch_id', poi.batch_id
        ) order by mat.name)
        from purchase_order_items poi
        join materials mat on mat.id = poi.material_id
        left join warehouse_locations wl on wl.id = poi.location_id
        where poi.purchase_order_id = po.id
      ), '[]'::jsonb)
    from purchase_orders po
    join partners p on p.id = po.supplier_partner_id
    left join profiles e on e.id = po.responsible_employee_id
    where po.id = p_id and po.company_id = auth_company_id();

  if not found then
    raise exception 'Тапсырыс табылмады' using errcode = 'P0002';
  end if;
end;
$$;

-- Requirement: "Purchase Order құру". p_supplier_partner_id and every
-- item's material_id/location_id are verified against the caller's
-- own company before the insert.
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

-- Requirement: "Өңдеу" — draft-only. p_id/p_supplier_partner_id and
-- every item's material_id are verified against the caller's own
-- company.
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

    insert into purchase_order_items (
      company_id, purchase_order_id, material_id, quantity, unit, unit_price_tiyn, location_id
    ) values (
      v_company_id, p_id, v_item.material_id, v_item.quantity, v_item.unit,
      v_item.unit_price_tiyn, v_item.location_id
    );
  end loop;
end;
$$;

create or replace function approve_purchase_order(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_company_id uuid := auth_company_id();
  v_status purchase_order_status;
begin
  if not auth_has_permission('purchases.approve') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  select status into v_status from purchase_orders where id = p_id and company_id = v_company_id;
  if not found then
    raise exception 'Тапсырыс табылмады' using errcode = 'P0002';
  end if;
  if v_status <> 'draft' then
    raise exception 'Тек жоба (draft) тапсырысты бекітуге болады' using errcode = '23514';
  end if;

  update purchase_orders
  set status = 'approved', approved_by = auth.uid(), approved_at = now()
  where id = p_id and company_id = v_company_id;
end;
$$;

create or replace function reject_purchase_order(p_id uuid, p_reason text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_company_id uuid := auth_company_id();
  v_status purchase_order_status;
begin
  if not auth_has_permission('purchases.approve') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  select status into v_status from purchase_orders where id = p_id and company_id = v_company_id;
  if not found then
    raise exception 'Тапсырыс табылмады' using errcode = 'P0002';
  end if;
  if v_status not in ('draft', 'approved') then
    raise exception 'Бұл тапсырыстан бас тартуға болмайды' using errcode = '23514';
  end if;

  update purchase_orders
  set status = 'rejected', rejection_reason = p_reason
  where id = p_id and company_id = v_company_id;
end;
$$;

create or replace function mark_purchase_order_delivered(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_company_id uuid := auth_company_id();
  v_status purchase_order_status;
begin
  if not auth_has_permission('purchases.approve') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  select status into v_status from purchase_orders where id = p_id and company_id = v_company_id;
  if not found then
    raise exception 'Тапсырыс табылмады' using errcode = 'P0002';
  end if;
  if v_status <> 'approved' then
    raise exception 'Тек бекітілген тапсырысты жеткізілді деп белгілеуге болады' using errcode = '23514';
  end if;

  update purchase_orders set status = 'delivered' where id = p_id and company_id = v_company_id;
end;
$$;

create or replace function cancel_purchase_order(p_id uuid, p_reason text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_company_id uuid := auth_company_id();
  v_status purchase_order_status;
begin
  select status into v_status from purchase_orders where id = p_id and company_id = v_company_id;
  if not found then
    raise exception 'Тапсырыс табылмады' using errcode = 'P0002';
  end if;
  if v_status = 'received' or v_status = 'cancelled' or v_status = 'rejected' then
    raise exception 'Бұл тапсырысты бас тартуға болмайды' using errcode = '23514';
  end if;

  if v_status = 'draft' then
    if not auth_has_permission('purchases.write') then
      raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
    end if;
  else
    if not auth_has_permission('purchases.approve') then
      raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
    end if;
  end if;

  update purchase_orders
  set status = 'cancelled', rejection_reason = p_reason
  where id = p_id and company_id = v_company_id;
end;
$$;

create or replace function receive_purchase_order(p_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_company_id uuid := auth_company_id();
  v_status purchase_order_status;
  v_supplier_partner_id uuid;
  v_order_number text;
  v_total_amount_tiyn bigint;
  v_item record;
  v_batch_id uuid;
  v_invoice_id uuid;
begin
  if not auth_has_permission('purchases.receive') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  select status, supplier_partner_id, order_number, total_amount_tiyn
    into v_status, v_supplier_partner_id, v_order_number, v_total_amount_tiyn
    from purchase_orders where id = p_id and company_id = v_company_id;
  if not found then
    raise exception 'Тапсырыс табылмады' using errcode = 'P0002';
  end if;
  if v_status <> 'delivered' then
    raise exception 'Тек жеткізілген тапсырысты қабылдауға болады' using errcode = '23514';
  end if;

  for v_item in
    select id, material_id, location_id, quantity, unit_price_tiyn
    from purchase_order_items where purchase_order_id = p_id
  loop
    if v_item.location_id is null then
      raise exception 'Әр материалға қойма орны көрсетілуі керек' using errcode = '23514';
    end if;

    v_batch_id := receive_materials(
      p_material_id => v_item.material_id,
      p_location_id => v_item.location_id,
      p_quantity => v_item.quantity,
      p_cost_per_unit_tiyn => v_item.unit_price_tiyn,
      p_batch_number => v_order_number,
      p_supplier_partner_id => v_supplier_partner_id
    );

    update purchase_order_items set batch_id = v_batch_id where id = v_item.id;
  end loop;

  update purchase_orders
  set status = 'received', received_by = auth.uid(), received_at = now()
  where id = p_id and company_id = v_company_id;

  insert into supplier_invoices (
    company_id, invoice_number, purchase_order_id, partner_id, amount_tiyn, created_by
  ) values (
    v_company_id, v_order_number, p_id, v_supplier_partner_id, v_total_amount_tiyn, auth.uid()
  ) returning id into v_invoice_id;

  update partners set balance_tiyn = balance_tiyn + v_total_amount_tiyn
  where id = v_supplier_partner_id and company_id = v_company_id;

  return v_invoice_id;
end;
$$;

create or replace function get_pending_purchase_quantities()
returns table (material_id uuid, pending_quantity numeric)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_company_id uuid := auth_company_id();
begin
  if not (auth_has_permission('production.read') or auth_has_permission('purchases.read')) then
    return;
  end if;

  return query
    select poi.material_id, sum(poi.quantity)
    from purchase_order_items poi
    join purchase_orders po on po.id = poi.purchase_order_id
    where po.status in ('approved', 'delivered') and po.company_id = v_company_id
    group by poi.material_id;
end;
$$;

create or replace function get_supplier_invoices(p_partner_id uuid)
returns table (
  id uuid,
  invoice_number text,
  purchase_order_id uuid,
  purchase_order_number text,
  amount_tiyn bigint,
  status supplier_invoice_status,
  issued_at date,
  due_date date,
  paid_amount_tiyn bigint
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_company_id uuid := auth_company_id();
begin
  if not (auth_has_permission('purchases.read') or auth_has_permission('partners.read_financial')) then
    return;
  end if;

  return query
    select
      si.id, si.invoice_number, si.purchase_order_id, po.order_number,
      si.amount_tiyn, si.status, si.issued_at, si.due_date,
      coalesce((
        select sum(asp.amount_tiyn) from active_supplier_payments asp
        where asp.supplier_invoice_id = si.id
      ), 0)
    from supplier_invoices si
    left join purchase_orders po on po.id = si.purchase_order_id
    where si.partner_id = p_partner_id and si.company_id = v_company_id
    order by si.issued_at desc;
end;
$$;

create or replace function get_supplier_payments(p_partner_id uuid)
returns table (
  id uuid,
  supplier_invoice_id uuid,
  invoice_number text,
  amount_tiyn bigint,
  method_key text,
  method_name_kk text,
  paid_at date,
  status payment_status,
  reversal_of uuid,
  comment text,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_company_id uuid := auth_company_id();
begin
  if not (auth_has_permission('purchases.read') or auth_has_permission('partners.read_financial')) then
    return;
  end if;

  return query
    select
      sp.id, sp.supplier_invoice_id, si.invoice_number, sp.amount_tiyn,
      pm.key, pm.name_kk, sp.paid_at, sp.status, sp.reversal_of, sp.comment, sp.created_at
    from supplier_payments sp
    left join supplier_invoices si on si.id = sp.supplier_invoice_id
    left join payment_methods pm on pm.id = sp.method_id
    where sp.partner_id = p_partner_id and sp.company_id = v_company_id
    order by sp.created_at desc;
end;
$$;

create or replace function recalc_supplier_invoice_status(p_invoice_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_amount bigint;
  v_paid bigint;
begin
  select amount_tiyn into v_amount from supplier_invoices
  where id = p_invoice_id and company_id = auth_company_id();
  if not found then
    return;
  end if;

  select coalesce(sum(amount_tiyn), 0) into v_paid
  from active_supplier_payments where supplier_invoice_id = p_invoice_id;

  update supplier_invoices
  set status = case
    when v_paid >= v_amount then 'paid'
    when v_paid > 0 then 'partial'
    else 'unpaid'
  end
  where id = p_invoice_id;
end;
$$;

-- Requirement: "Жеткізушіге төлем" — idempotent. p_partner_id and
-- (when provided) p_supplier_invoice_id are verified against the
-- caller's own company before the insert.
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

create or replace function reverse_supplier_payment(p_payment_id uuid, p_reason text)
returns supplier_payments
language plpgsql
security definer
set search_path = public
as $$
declare
  v_company_id uuid := auth_company_id();
  v_original supplier_payments;
  v_reversal supplier_payments;
begin
  if not auth_has_permission('purchases.pay') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  select * into v_original from supplier_payments
  where id = p_payment_id and company_id = v_company_id;
  if not found then
    raise exception 'Төлем табылмады' using errcode = 'P0002';
  end if;

  insert into supplier_payments (
    company_id, partner_id, supplier_invoice_id, amount_tiyn, method_id, cashbox_id,
    bank_account_id, recorded_by, status, reversal_of, idempotency_key, comment
  ) values (
    v_company_id, v_original.partner_id, v_original.supplier_invoice_id, v_original.amount_tiyn,
    v_original.method_id, v_original.cashbox_id, v_original.bank_account_id,
    auth.uid(), 'reversed', p_payment_id, 'reversal-' || p_payment_id::text, p_reason
  )
  returning * into v_reversal;

  update partners set balance_tiyn = balance_tiyn + v_original.amount_tiyn
  where id = v_original.partner_id and company_id = v_company_id;

  if v_original.supplier_invoice_id is not null then
    perform recalc_supplier_invoice_status(v_original.supplier_invoice_id);
  end if;

  return v_reversal;
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
stable
security definer
set search_path = public
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
        select coalesce(sum(total_amount_tiyn), 0) from purchase_orders
        where status = 'received' and received_at >= date_trunc('month', current_date)
          and company_id = v_company_id
      ),
      (
        select coalesce(sum(balance_tiyn), 0) from partners
        where balance_tiyn > 0 and deleted_at is null and company_id = v_company_id
      ),
      (
        select coalesce(sum(-balance_tiyn), 0) from partners
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

-- Live (post-purchases-module) version of get_order_production_detail —
-- see 20260713000022's own header comment for why this superseded the
-- Production module's original (adds material_id into the materials
-- jsonb array; everything else identical).
create or replace function get_order_production_detail(p_order_id uuid)
returns table (
  order_id uuid,
  order_number text,
  product_type text,
  client_name text,
  address text,
  planned_completion_date date,
  stage_id uuid,
  stage_key text,
  stage_name_kk text,
  percent_complete smallint,
  master_id uuid,
  master_name text,
  materials jsonb,
  recent_photos jsonb,
  time_logs jsonb,
  stage_history jsonb
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
  v_assigned boolean;
  v_default_stage_id uuid;
begin
  if not v_read then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  if not v_scope_all then
    select exists (
      select 1 from orders o
      where o.id = p_order_id
        and o.company_id = v_company_id
        and (
          o.responsible_employee_id = auth.uid()
          or exists (
            select 1 from order_assignments oa
            where oa.order_id = o.id and oa.profile_id = auth.uid()
          )
        )
    ) into v_assigned;
    if not v_assigned then
      raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
    end if;
  end if;

  select id into v_default_stage_id
  from production_stages where company_id = v_company_id order by sort_order limit 1;

  return query
    select
      o.id,
      o.order_number,
      o.product_type,
      c.name,
      o.address,
      o.planned_completion_date,
      coalesce(ps.id, v_default_stage_id),
      coalesce(ps.key, (select key from production_stages where id = v_default_stage_id)),
      coalesce(ps.name_kk, (select name_kk from production_stages where id = v_default_stage_id)),
      coalesce(opp.percent_complete, 0),
      m.profile_id,
      m.full_name,
      coalesce((
        select jsonb_agg(jsonb_build_object(
          'material_id', mat.id,
          'material_name', mat.name,
          'unit', mat.unit,
          'reserved_quantity', mr.quantity,
          'available_quantity', coalesce((
            select sum(ib.quantity - ib.reserved_quantity)
            from inventory_balances ib where ib.material_id = mr.material_id
          ), 0),
          'is_sufficient', mr.quantity <= coalesce((
            select sum(ib.quantity - ib.reserved_quantity)
            from inventory_balances ib where ib.material_id = mr.material_id
          ), 0)
        ))
        from material_reservations mr
        join materials mat on mat.id = mr.material_id
        where mr.order_id = o.id
      ), '[]'::jsonb),
      coalesce((
        select jsonb_agg(jsonb_build_object(
          'id', op.id, 'storage_path', op.storage_path, 'uploaded_at', op.uploaded_at
        ) order by op.uploaded_at desc)
        from order_photos op
        where op.order_id = o.id and op.kind = 'production'
      ), '[]'::jsonb),
      coalesce((
        select jsonb_agg(jsonb_build_object(
          'id', tl.id,
          'employee_id', tl.employee_id,
          'employee_name', ep.full_name,
          'stage_name_kk', tls.name_kk,
          'started_at', tl.started_at,
          'ended_at', tl.ended_at
        ) order by tl.started_at desc)
        from production_time_logs tl
        join profiles ep on ep.id = tl.employee_id
        left join production_stages tls on tls.id = tl.stage_id
        where tl.order_id = o.id
      ), '[]'::jsonb),
      coalesce((
        select jsonb_agg(jsonb_build_object(
          'previous_stage_name', prev.name_kk,
          'new_stage_name', nxt.name_kk,
          'changed_by_name', cp.full_name,
          'changed_at', h.changed_at,
          'comment', h.comment
        ) order by h.changed_at desc)
        from production_stage_history h
        left join production_stages prev on prev.id = h.previous_stage_id
        left join production_stages nxt on nxt.id = h.new_stage_id
        left join profiles cp on cp.id = h.changed_by
        where h.order_id = o.id
      ), '[]'::jsonb)
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
    where o.id = p_order_id and o.company_id = v_company_id and o.deleted_at is null;
end;
$$;
