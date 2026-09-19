-- Purchases module (Закуп/Сатып алу) — see Purchases module
-- requirements. Full automation of the supplier purchasing process,
-- built entirely on top of the Partners/Warehouse/Production modules
-- already committed — no new architecture, only new tables + RPCs
-- that call into existing ones.
--
-- Table-naming reconciliation: the requirement's `purchase_orders` name
-- collides with a Phase-0 scaffold table of the same name
-- (20260713000007_warehouse.sql) that was never wired into any RPC or
-- Flutter code (confirmed by grep — only referenced by its own RLS
-- policies) and has an incompatible shape for this module (one
-- material per order, tied to the legacy `suppliers` table rather
-- than `partners`, no financial header fields at all). It — plus its
-- companion `purchase_requests` table and the `purchase_status` enum —
-- is dropped and replaced below rather than extended, exactly as
-- `inventory_holds`/`inventory_batches` were added fresh in the
-- Warehouse module instead of shoehorning new concepts into
-- ill-fitting Phase-0 tables. `purchase_order_items`/`supplier_invoices`/
-- `supplier_payments` are genuinely new. The legacy `suppliers`/
-- `supplier_debts` tables (from 20260713000006_finance.sql) are left
-- untouched — out of scope, and `partners` already superseded them for
-- every module built so far.
drop policy if exists "purchase_orders_rw" on purchase_orders;
drop policy if exists "purchase_requests_approve" on purchase_requests;
drop policy if exists "purchase_requests_insert" on purchase_requests;
drop policy if exists "purchase_requests_select" on purchase_requests;
drop table if exists purchase_orders;
drop table if exists purchase_requests;
drop type if exists purchase_status;

-- Status workflow: draft (Purchase Order құру/Өңдеу — items and header
-- freely editable) -> approved (Бекіту) -> delivered (Жеткізілді —
-- supplier has shipped/dropped off the goods) -> received (Қабылдау —
-- warehouse has counted and accepted them; this is the step that
-- writes to inventory_batches/inventory_transactions/inventory_balances
-- and creates the supplier_invoice). rejected/cancelled are terminal
-- exits before received.
create type purchase_order_status as enum (
  'draft', 'approved', 'rejected', 'delivered', 'received', 'cancelled'
);

create type supplier_invoice_status as enum ('unpaid', 'partial', 'paid');

create table purchase_orders (
  id uuid primary key default gen_random_uuid(),
  order_number text not null unique,
  supplier_partner_id uuid not null references partners (id),
  status purchase_order_status not null default 'draft',
  responsible_employee_id uuid references profiles (id),
  expected_delivery_date date,
  -- Money as integer minor units (tiyn), never floating point, per
  -- CLAUDE.md. total_amount_tiyn is derived (subtotal + delivery +
  -- vat - discount) and kept in sync by triggers below, not
  -- app-computed, so it can never drift from its line items.
  delivery_cost_tiyn bigint not null default 0 check (delivery_cost_tiyn >= 0),
  vat_tiyn bigint not null default 0 check (vat_tiyn >= 0),
  discount_tiyn bigint not null default 0 check (discount_tiyn >= 0),
  subtotal_tiyn bigint not null default 0,
  total_amount_tiyn bigint not null default 0,
  comment text,
  rejection_reason text,
  created_by uuid references profiles (id),
  approved_by uuid references profiles (id),
  approved_at timestamptz,
  received_by uuid references profiles (id),
  received_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index purchase_orders_supplier_partner_id_idx on purchase_orders (supplier_partner_id);
create index purchase_orders_status_idx on purchase_orders (status);

create table purchase_order_items (
  id uuid primary key default gen_random_uuid(),
  purchase_order_id uuid not null references purchase_orders (id) on delete cascade,
  material_id uuid not null references materials (id),
  quantity numeric not null check (quantity > 0),
  -- Denormalized from materials.unit at order time — a material's
  -- unit shouldn't silently reinterpret an already-placed order's
  -- quantity if it's ever edited later.
  unit text not null,
  unit_price_tiyn bigint not null check (unit_price_tiyn >= 0),
  total_price_tiyn bigint not null default 0,
  location_id uuid references warehouse_locations (id),
  -- Filled in by receive_purchase_order() once accepted — the batch
  -- this line item became in inventory_batches, for traceability.
  batch_id uuid references inventory_batches (id),
  created_at timestamptz not null default now()
);

create index purchase_order_items_purchase_order_id_idx on purchase_order_items (purchase_order_id);
create index purchase_order_items_material_id_idx on purchase_order_items (material_id);

create table supplier_invoices (
  id uuid primary key default gen_random_uuid(),
  invoice_number text not null,
  purchase_order_id uuid references purchase_orders (id),
  partner_id uuid not null references partners (id),
  amount_tiyn bigint not null check (amount_tiyn > 0),
  status supplier_invoice_status not null default 'unpaid',
  issued_at date not null default current_date,
  due_date date,
  created_by uuid references profiles (id),
  created_at timestamptz not null default now()
);

create index supplier_invoices_partner_id_idx on supplier_invoices (partner_id);
create index supplier_invoices_purchase_order_id_idx on supplier_invoices (purchase_order_id);

-- Insert-only / reversal-not-delete, same convention as `payments`
-- (see payment_status reused directly below — 'pending'/'confirmed'/
-- 'reversed' already fits supplier payments with no new enum needed).
create table supplier_payments (
  id uuid primary key default gen_random_uuid(),
  partner_id uuid not null references partners (id),
  -- Null = a general advance ("Аванс") not tied to one invoice yet.
  supplier_invoice_id uuid references supplier_invoices (id),
  amount_tiyn bigint not null check (amount_tiyn > 0),
  method_id uuid references payment_methods (id),
  cashbox_id uuid references cashboxes (id),
  bank_account_id uuid references bank_accounts (id),
  paid_at date not null default current_date,
  recorded_by uuid references profiles (id),
  status payment_status not null default 'confirmed',
  reversal_of uuid references supplier_payments (id),
  idempotency_key text not null unique,
  comment text,
  created_at timestamptz not null default now()
);

create index supplier_payments_partner_id_idx on supplier_payments (partner_id);
create index supplier_payments_supplier_invoice_id_idx on supplier_payments (supplier_invoice_id);

-- Mirrors active_payments (20260713000016_payments_module.sql) — the
-- one place "how much has actually been paid" is defined, so a
-- reversal (a new row, never a delete/update of the original) is
-- never double-counted.
create view active_supplier_payments
  with (security_invoker = true) as
  select sp.*
  from supplier_payments sp
  where sp.status = 'confirmed'
    and not exists (
      select 1 from supplier_payments r where r.reversal_of = sp.id
    );

create trigger purchase_orders_set_updated_at
  before update on purchase_orders
  for each row execute function set_updated_at();

-- Keeps purchase_orders.total_amount_tiyn always equal to
-- subtotal + delivery + vat - discount — recomputed from NEW's own
-- columns on every insert/update, so it can never be set
-- inconsistently by a partial update.
create function sync_purchase_order_total()
returns trigger
language plpgsql
as $$
begin
  NEW.total_amount_tiyn := NEW.subtotal_tiyn + NEW.delivery_cost_tiyn
    + NEW.vat_tiyn - NEW.discount_tiyn;
  return NEW;
end;
$$;

create trigger purchase_orders_sync_total
  before insert or update on purchase_orders
  for each row execute function sync_purchase_order_total();

create function sync_purchase_order_item_total()
returns trigger
language plpgsql
as $$
begin
  NEW.total_price_tiyn := round(NEW.quantity * NEW.unit_price_tiyn);
  return NEW;
end;
$$;

create trigger purchase_order_items_sync_total
  before insert or update on purchase_order_items
  for each row execute function sync_purchase_order_item_total();

-- Rolls a line-item change up into the parent's subtotal, which in
-- turn re-fires purchase_orders_sync_total above (an UPDATE on
-- purchase_orders) to keep total_amount_tiyn correct too — one
-- consistent chain instead of two places computing the same number.
create function recalc_purchase_order_subtotal()
returns trigger
language plpgsql
as $$
declare
  v_po_id uuid := coalesce(NEW.purchase_order_id, OLD.purchase_order_id);
begin
  update purchase_orders
  set subtotal_tiyn = coalesce(
    (select sum(total_price_tiyn) from purchase_order_items where purchase_order_id = v_po_id), 0
  )
  where id = v_po_id;
  return null;
end;
$$;

create trigger purchase_order_items_recalc_subtotal
  after insert or update or delete on purchase_order_items
  for each row execute function recalc_purchase_order_subtotal();

alter table purchase_orders enable row level security;
alter table purchase_order_items enable row level security;
alter table supplier_invoices enable row level security;
alter table supplier_payments enable row level security;

-- Defense-in-depth only, same coarse-gate convention as the Warehouse
-- module (not the Partners/Employees full-revoke pattern) — nothing
-- in these four tables needs column-level redaction within the
-- purchases domain itself; the RPCs below exist to bypass `partners`'
-- own lockdown for joins, and to enforce the approve/receive/pay role
-- split the plain read/write policies below can't express.
create policy "purchase_orders_select" on purchase_orders
  for select using (auth_is_active() and auth_has_permission('purchases.read'));
create policy "purchase_orders_write" on purchase_orders
  for all using (auth_is_active() and auth_has_permission('purchases.write'))
  with check (auth_is_active() and auth_has_permission('purchases.write'));

create policy "purchase_order_items_select" on purchase_order_items
  for select using (auth_is_active() and auth_has_permission('purchases.read'));
create policy "purchase_order_items_write" on purchase_order_items
  for all using (auth_is_active() and auth_has_permission('purchases.write'))
  with check (auth_is_active() and auth_has_permission('purchases.write'));

create policy "supplier_invoices_select" on supplier_invoices
  for select using (auth_is_active() and auth_has_permission('purchases.read'));
create policy "supplier_invoices_write" on supplier_invoices
  for all using (auth_is_active() and auth_has_permission('purchases.write'))
  with check (auth_is_active() and auth_has_permission('purchases.write'));

create policy "supplier_payments_select" on supplier_payments
  for select using (auth_is_active() and auth_has_permission('purchases.read'));
create policy "supplier_payments_write" on supplier_payments
  for all using (auth_is_active() and auth_has_permission('purchases.pay'))
  with check (auth_is_active() and auth_has_permission('purchases.pay'));

-- Requirement: "Material Picker" — Manager holds purchases.write but
-- not warehouse.read (materials management stays the storekeeper/
-- purchaser/director's job per the Warehouse module's role design),
-- so picking a material while drafting a PO would otherwise be
-- impossible for Manager. Superseding get_materials() (rather than
-- adding a near-duplicate RPC) to also accept purchases.read/.write
-- is the smallest change that closes this gap — no other caller of
-- get_materials() is affected since the added clause is strictly
-- broader (an OR), never narrower.
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
    where (p_category_id is null or m.category_id = p_category_id)
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

-- Requirement: "Purchase Orders" list screen. SECURITY DEFINER to join
-- `partners` for the supplier's display name (its own grants are fully
-- revoked — see 20260713000018_partners_module.sql). Read-side
-- redaction (empty result), not an exception, for a caller with no
-- purchases.read — same convention as get_production_queue().
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
    where (p_status is null or po.status = p_status)
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

-- Requirement: "Purchase Detail" screen. A direct single-order fetch
-- with no purchases.read raises instead of returning empty — viewing
-- one specific PO you have no business seeing is a blocked action,
-- not a benign empty list (same split as get_order_production_detail()
-- vs get_production_queue()).
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
    where po.id = p_id;

  if not found then
    raise exception 'Тапсырыс табылмады' using errcode = 'P0002';
  end if;
end;
$$;

-- Requirement: "Purchase Order құру" — creates the header and its
-- items in one call via jsonb_to_recordset(), same pattern as
-- Warehouse's issue_materials(p_items jsonb).
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
  v_id uuid;
  v_item record;
begin
  if not auth_has_permission('purchases.write') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  insert into purchase_orders (
    order_number, supplier_partner_id, responsible_employee_id,
    expected_delivery_date, delivery_cost_tiyn, vat_tiyn, discount_tiyn,
    comment, created_by
  ) values (
    p_order_number, p_supplier_partner_id, p_responsible_employee_id,
    p_expected_delivery_date, p_delivery_cost_tiyn, p_vat_tiyn, p_discount_tiyn,
    p_comment, auth.uid()
  ) returning id into v_id;

  for v_item in
    select * from jsonb_to_recordset(p_items) as x(
      material_id uuid, quantity numeric, unit text,
      unit_price_tiyn bigint, location_id uuid
    )
  loop
    insert into purchase_order_items (
      purchase_order_id, material_id, quantity, unit, unit_price_tiyn, location_id
    ) values (
      v_id, v_item.material_id, v_item.quantity, v_item.unit,
      v_item.unit_price_tiyn, v_item.location_id
    );
  end loop;

  return v_id;
end;
$$;

-- Requirement: "Өңдеу" — replaces the header + wholesale-replaces the
-- item list. Draft-only: once approved/further along, the PO is a
-- record of what was actually ordered/received and must not be
-- silently rewritten (cancel + recreate is the correct path instead).
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
  v_status purchase_order_status;
  v_item record;
begin
  if not auth_has_permission('purchases.write') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  select status into v_status from purchase_orders where id = p_id;
  if not found then
    raise exception 'Тапсырыс табылмады' using errcode = 'P0002';
  end if;
  if v_status <> 'draft' then
    raise exception 'Тек жоба (draft) күйіндегі тапсырысты өңдеуге болады' using errcode = '42501';
  end if;

  update purchase_orders set
    supplier_partner_id = p_supplier_partner_id,
    responsible_employee_id = p_responsible_employee_id,
    expected_delivery_date = p_expected_delivery_date,
    delivery_cost_tiyn = p_delivery_cost_tiyn,
    vat_tiyn = p_vat_tiyn,
    discount_tiyn = p_discount_tiyn,
    comment = p_comment
  where id = p_id;

  delete from purchase_order_items where purchase_order_id = p_id;

  for v_item in
    select * from jsonb_to_recordset(p_items) as x(
      material_id uuid, quantity numeric, unit text,
      unit_price_tiyn bigint, location_id uuid
    )
  loop
    insert into purchase_order_items (
      purchase_order_id, material_id, quantity, unit, unit_price_tiyn, location_id
    ) values (
      p_id, v_item.material_id, v_item.quantity, v_item.unit,
      v_item.unit_price_tiyn, v_item.location_id
    );
  end loop;
end;
$$;

-- Requirement: "Бекіту".
create or replace function approve_purchase_order(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_status purchase_order_status;
begin
  if not auth_has_permission('purchases.approve') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  select status into v_status from purchase_orders where id = p_id;
  if not found then
    raise exception 'Тапсырыс табылмады' using errcode = 'P0002';
  end if;
  if v_status <> 'draft' then
    raise exception 'Тек жоба (draft) тапсырысты бекітуге болады' using errcode = '23514';
  end if;

  update purchase_orders
  set status = 'approved', approved_by = auth.uid(), approved_at = now()
  where id = p_id;
end;
$$;

-- Requirement: "Бас тарту" — from draft or approved (before delivery).
create or replace function reject_purchase_order(p_id uuid, p_reason text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_status purchase_order_status;
begin
  if not auth_has_permission('purchases.approve') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  select status into v_status from purchase_orders where id = p_id;
  if not found then
    raise exception 'Тапсырыс табылмады' using errcode = 'P0002';
  end if;
  if v_status not in ('draft', 'approved') then
    raise exception 'Бұл тапсырыстан бас тартуға болмайды' using errcode = '23514';
  end if;

  update purchase_orders
  set status = 'rejected', rejection_reason = p_reason
  where id = p_id;
end;
$$;

-- Requirement: "Жеткізілді" — the supplier has shipped/dropped the
-- goods off; a logistics-tracking step distinct from the warehouse's
-- own physical acceptance (see receive_purchase_order() below), so it
-- shares purchases.approve rather than purchases.receive.
create or replace function mark_purchase_order_delivered(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_status purchase_order_status;
begin
  if not auth_has_permission('purchases.approve') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  select status into v_status from purchase_orders where id = p_id;
  if not found then
    raise exception 'Тапсырыс табылмады' using errcode = 'P0002';
  end if;
  if v_status <> 'approved' then
    raise exception 'Тек бекітілген тапсырысты жеткізілді деп белгілеуге болады' using errcode = '23514';
  end if;

  update purchase_orders set status = 'delivered' where id = p_id;
end;
$$;

-- Requirement: "Бас тарту" also covers cancelling an in-flight order —
-- draft owners (purchases.write) may cancel their own not-yet-approved
-- draft; anything further along needs purchases.approve, same
-- authority as reject/deliver.
create or replace function cancel_purchase_order(p_id uuid, p_reason text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_status purchase_order_status;
begin
  select status into v_status from purchase_orders where id = p_id;
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
  where id = p_id;
end;
$$;

-- Requirement: "Қабылдау" + full Warehouse/Production integration.
--
-- Rather than reimplementing receiving logic, this calls the
-- Warehouse module's own receive_materials() once per line item —
-- the exact function a storekeeper already uses for "Келіп түсу" —
-- so "Автоматты inventory_transactions жазу" / "inventory_batches
-- жасау" / "Қойма қалдығын көбейту" are satisfied by construction,
-- with zero duplicated bookkeeping logic. receive_materials() itself
-- re-checks warehouse.write internally (defense in depth); every role
-- granted purchases.receive here (director, purchaser, warehouse) was
-- already given warehouse.write by the Warehouse module's seed data,
-- so this never fails on that inner check.
--
-- "Reservation жабылған кезде автоматты қабылдау" / "materials_sufficient
-- автоматты жаңарсын": no extra step is needed here at all —
-- get_production_queue()/get_order_production_detail() (unchanged,
-- 20260713000020_production_module.sql) compute materials_sufficient
-- live from inventory_balances on every call, so the moment this
-- function increases a material's balance, Production's own
-- already-committed query reflects it on its very next read.
--
-- Also creates the supplier_invoice for the PO's total and increments
-- the supplier's partners.balance_tiyn by that amount (our debt to
-- them just went up) — the first write to what that column's own doc
-- comment calls out as "PARTNER_BALANCES үшін кейін кеңейтуге ыңғайлы
-- архитектура", now realized as this module's ledger.
create or replace function receive_purchase_order(p_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
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
    from purchase_orders where id = p_id;
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
  where id = p_id;

  insert into supplier_invoices (
    invoice_number, purchase_order_id, partner_id, amount_tiyn, created_by
  ) values (
    v_order_number, p_id, v_supplier_partner_id, v_total_amount_tiyn, auth.uid()
  ) returning id into v_invoice_id;

  update partners set balance_tiyn = balance_tiyn + v_total_amount_tiyn
  where id = v_supplier_partner_id;

  return v_invoice_id;
end;
$$;

-- Requirement: Production integration — "Production күтіп тұрған
-- материалдарды көрсету". Anyone who can see either side of this
-- (production.read for the shop floor, purchases.read for
-- procurement) may see it; empty for neither, same read-side
-- redaction convention used throughout.
create or replace function get_pending_purchase_quantities()
returns table (material_id uuid, pending_quantity numeric)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not (auth_has_permission('production.read') or auth_has_permission('purchases.read')) then
    return;
  end if;

  return query
    select poi.material_id, sum(poi.quantity)
    from purchase_order_items poi
    join purchase_orders po on po.id = poi.purchase_order_id
    where po.status in ('approved', 'delivered')
    group by poi.material_id;
end;
$$;

-- Requirement: Partners integration — "Supplier карточкасынан:
-- Invoices көру". SECURITY DEFINER: financial amounts, same
-- sensitivity tier as partners.read_financial, but gated on
-- purchases.read too since Purchaser (who has no partners.read_financial)
-- still needs to see a supplier's own invoice history while working a PO.
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
    where si.partner_id = p_partner_id
    order by si.issued_at desc;
end;
$$;

-- Requirement: Partners integration — "Supplier карточкасынан:
-- Payments көру" + Purchase Detail's own payment history.
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
    where sp.partner_id = p_partner_id
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
  select amount_tiyn into v_amount from supplier_invoices where id = p_invoice_id;
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

-- Requirement: "Жеткізушіге төлем" — idempotent, same pattern as
-- record_payment() (20260713000016_payments_module.sql). No
-- overpayment guard (unlike order payments): paying more than the
-- linked invoice's amount is exactly "Аванс" (an advance), which the
-- requirement explicitly calls out as a valid, expected case — it
-- simply pushes partners.balance_tiyn negative per that column's own
-- sign convention.
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
  v_existing record;
  v_payment supplier_payments;
begin
  if not auth_has_permission('purchases.pay') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  select * into v_existing from idempotency_keys where key = p_idempotency_key;
  if found then
    return jsonb_populate_record(null::supplier_payments, v_existing.response -> 'payment');
  end if;

  insert into supplier_payments (
    partner_id, supplier_invoice_id, amount_tiyn, method_id, cashbox_id,
    bank_account_id, paid_at, recorded_by, status, idempotency_key, comment
  ) values (
    p_partner_id, p_supplier_invoice_id, p_amount_tiyn, p_method_id, p_cashbox_id,
    p_bank_account_id, p_paid_at, auth.uid(), 'confirmed', p_idempotency_key, p_comment
  )
  returning * into v_payment;

  insert into idempotency_keys (key, response)
  values (p_idempotency_key, jsonb_build_object('payment', to_jsonb(v_payment)));

  update partners set balance_tiyn = balance_tiyn - p_amount_tiyn
  where id = p_partner_id;

  if p_supplier_invoice_id is not null then
    perform recalc_supplier_invoice_status(p_supplier_invoice_id);
  end if;

  return v_payment;
end;
$$;

-- Requirement: "Төлем тарихы" implies reversal must be possible
-- without editing/deleting history — same insert-only pattern as
-- reverse_payment().
create or replace function reverse_supplier_payment(p_payment_id uuid, p_reason text)
returns supplier_payments
language plpgsql
security definer
set search_path = public
as $$
declare
  v_original supplier_payments;
  v_reversal supplier_payments;
begin
  if not auth_has_permission('purchases.pay') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  select * into v_original from supplier_payments where id = p_payment_id;
  if not found then
    raise exception 'Төлем табылмады' using errcode = 'P0002';
  end if;

  insert into supplier_payments (
    partner_id, supplier_invoice_id, amount_tiyn, method_id, cashbox_id,
    bank_account_id, recorded_by, status, reversal_of, idempotency_key, comment
  ) values (
    v_original.partner_id, v_original.supplier_invoice_id, v_original.amount_tiyn,
    v_original.method_id, v_original.cashbox_id, v_original.bank_account_id,
    auth.uid(), 'reversed', p_payment_id, 'reversal-' || p_payment_id::text, p_reason
  )
  returning * into v_reversal;

  update partners set balance_tiyn = balance_tiyn + v_original.amount_tiyn
  where id = v_original.partner_id;

  if v_original.supplier_invoice_id is not null then
    perform recalc_supplier_invoice_status(v_original.supplier_invoice_id);
  end if;

  return v_reversal;
end;
$$;

-- Requirement: "Purchase Analytics" — Айлық сатып алу / Ең көп сатып
-- алынған материалдар / Орташа сатып алу бағасы / Қарыз / Аванс /
-- Жеткізуші рейтингі (built from partners.trust_rating, already
-- collected by the Partners module, plus this module's own on-time
-- delivery rate).
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
begin
  if not auth_has_permission('purchases.read') then
    return;
  end if;

  return query
    select
      (
        select coalesce(sum(total_amount_tiyn), 0) from purchase_orders
        where status = 'received' and received_at >= date_trunc('month', current_date)
      ),
      (
        select coalesce(sum(balance_tiyn), 0) from partners
        where balance_tiyn > 0 and deleted_at is null
      ),
      (
        select coalesce(sum(-balance_tiyn), 0) from partners
        where balance_tiyn < 0 and deleted_at is null
      ),
      (
        select coalesce(avg(unit_price_tiyn), 0) from purchase_order_items poi
        join purchase_orders po on po.id = poi.purchase_order_id
        where po.status = 'received'
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
          where po.status = 'received'
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
          where p.deleted_at is null
          group by p.id
          order by count(po.id) desc
          limit 10
        ) sup
      ), '[]'::jsonb);
end;
$$;

-- Requirement: Production integration — "Production күтіп тұрған
-- материалдарды көрсету". Supersedes
-- get_order_production_detail() (20260713000020_production_module.sql)
-- to add material_id into the materials jsonb array — the ONLY change;
-- every filter/security/join stays byte-for-byte identical. Without
-- this, the Flutter MaterialAvailabilitySection widget (which shows
-- this array) has no key to look `get_pending_purchase_quantities()`
-- up by, since the original jsonb only ever carried material_name/
-- unit/reserved_quantity/available_quantity/is_sufficient.
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

  select id into v_default_stage_id from production_stages order by sort_order limit 1;

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
    where o.id = p_order_id and o.deleted_at is null;
end;
$$;
