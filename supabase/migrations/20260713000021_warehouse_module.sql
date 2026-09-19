-- Warehouse module — see Warehouse module requirements. Builds on the
-- warehouse schema already in place since
-- 20260713000007_warehouse.sql/20260713000012_rls_policies.sql
-- (materials, material_categories, warehouses, warehouse_locations,
-- inventory_balances, inventory_transactions, purchase_requests/
-- purchase_orders) rather than duplicating it under the requirement's
-- literal table names:
--   "inventory"             -> already `inventory_balances`
--   "warehouse_locations"   -> already exists verbatim
--   "inventory_transactions"-> already exists verbatim
-- "inventory_reservations" splits into two concepts the requirement
-- itself distinguishes ("Резерв" vs "Production резерві"):
--   - order-tied reservations -> already `material_reservations`
--     (created by the Production module's requirements; this
--     migration adds `location_id` to it so a release can credit back
--     the right location's reserved_quantity, and wraps it in
--     reserve_material_for_order()/release_order_reservation() so
--     inventory_balances.reserved_quantity — previously never
--     touched by anything — actually stays in sync).
--   - generic, non-order holds -> new `inventory_holds` below.
-- `inventory_batches` ("Партиялар") is genuinely new.
--
-- Production integration: get_production_queue()/
-- get_order_production_detail() (20260713000020_production_module.sql)
-- already compute `materials_sufficient` by reading
-- material_reservations + inventory_balances live on every call — now
-- that reserve_material_for_order()/release_order_reservation() keep
-- reserved_quantity honest, that existing logic becomes correct
-- automatically. No changes to the Production migration were needed.

alter table materials add column barcode text unique;
alter table materials add column preferred_partner_id uuid references partners (id);
alter table material_reservations add column location_id uuid references warehouse_locations (id);

create table inventory_batches (
  id uuid primary key default gen_random_uuid(),
  material_id uuid not null references materials (id),
  location_id uuid not null references warehouse_locations (id),
  batch_number text,
  quantity_received numeric not null check (quantity_received > 0),
  quantity_remaining numeric not null check (quantity_remaining >= 0),
  cost_per_unit_tiyn bigint not null default 0 check (cost_per_unit_tiyn >= 0),
  supplier_partner_id uuid references partners (id),
  received_at timestamptz not null default now(),
  created_by uuid references profiles (id)
);

create index inventory_batches_material_id_idx on inventory_batches (material_id);
create index inventory_batches_location_id_idx on inventory_batches (location_id);

-- Requirement: "Резерв" — a generic, non-order hold (quality
-- inspection, damaged-goods set-aside, a walk-in customer inquiry),
-- distinct from "Production резерві" (material_reservations, always
-- order-tied). Both increment the same inventory_balances.reserved_quantity.
create table inventory_holds (
  id uuid primary key default gen_random_uuid(),
  material_id uuid not null references materials (id),
  location_id uuid not null references warehouse_locations (id),
  quantity numeric not null check (quantity > 0),
  reason text,
  created_by uuid references profiles (id),
  created_at timestamptz not null default now(),
  released_at timestamptz
);

create index inventory_holds_material_id_idx on inventory_holds (material_id);

alter table inventory_batches enable row level security;
alter table inventory_holds enable row level security;

-- Same convention as every other warehouse-domain table (see
-- 20260713000012_rls_policies.sql): warehouse.read to see, .write to
-- change. Defense-in-depth only — the RPCs below are the real path.
create policy "inventory_batches_select" on inventory_batches
  for select using (auth_is_active() and auth_has_permission('warehouse.read'));

create policy "inventory_batches_write" on inventory_batches
  for all using (auth_is_active() and auth_has_permission('warehouse.write'))
  with check (auth_is_active() and auth_has_permission('warehouse.write'));

create policy "inventory_holds_select" on inventory_holds
  for select using (auth_is_active() and auth_has_permission('warehouse.read'));

create policy "inventory_holds_write" on inventory_holds
  for all using (auth_is_active() and auth_has_permission('warehouse.write'))
  with check (auth_is_active() and auth_has_permission('warehouse.write'));

-- Requirement: "Қойма қалдығы" — per-material stock summary across
-- all locations, plus the low-stock flag ("Минималды қалдық" /
-- "Автоматты ескерту"). SECURITY DEFINER (unlike dashboard_summary()'s
-- INVOKER pattern) because it joins to `partners` for the preferred
-- supplier's contact details ("Жеткізушімен байланыс") — that table's
-- base grants are fully revoked (see 20260713000018_partners_module.sql),
-- so an invoker join would fail for everyone; only display_name/phone/
-- whatsapp_phone (the "basic" tier every internal role with
-- partners.read can already see via get_partners() — bank_details/
-- balance/trust_rating stay tier-gated there and are never selected
-- here) are exposed. Read-side redaction, not an exception, for a
-- caller with no warehouse.read at all — same convention as
-- get_production_queue().
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
  if not auth_has_permission('warehouse.read') then
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

-- Requirement: "Barcode" — resolves a scanned/typed barcode straight
-- to a material id (used by both the barcode scanner and, via the
-- same decode step, a QR code — see warehouse_qr.dart on the Flutter
-- side). Null for no match or no warehouse.read, never an exception —
-- a scan that doesn't resolve is just "not found", not a permission error.
create or replace function get_material_id_by_barcode(p_barcode text)
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select m.id from materials m
  where m.barcode = p_barcode and auth_has_permission('warehouse.read')
  limit 1;
$$;

-- Requirement: "Қойма аналитикасы".
create or replace function get_warehouse_summary()
returns table (
  materials_count bigint,
  low_stock_count bigint,
  total_inventory_value_tiyn bigint,
  category_breakdown jsonb
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not auth_has_permission('warehouse.read') then
    return;
  end if;

  return query
    select
      (select count(*) from materials),
      (
        select count(*) from (
          select m.id, coalesce(sum(ib.quantity - ib.reserved_quantity), 0) as avail
          from materials m
          left join inventory_balances ib on ib.material_id = m.id
          group by m.id, m.min_quantity
          having coalesce(sum(ib.quantity - ib.reserved_quantity), 0) < m.min_quantity
        ) low
      ),
      (
        select coalesce(sum(ib.quantity * m.cost_per_unit_tiyn), 0)::bigint
        from inventory_balances ib
        join materials m on m.id = ib.material_id
      ),
      (
        select coalesce(jsonb_object_agg(mc.name_kk, cnt), '{}'::jsonb) from (
          select mc.name_kk, count(*) as cnt
          from materials m
          join material_categories mc on mc.id = m.category_id
          group by mc.name_kk
        ) mc(name_kk, cnt)
      );
end;
$$;

-- Requirement: "Келіп түсу" — records a new batch and increases the
-- material's balance at the given location in one step.
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
  v_batch_id uuid;
begin
  if not auth_has_permission('warehouse.write') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;
  if p_quantity <= 0 then
    raise exception 'Мөлшер оң сан болуы керек' using errcode = '23514';
  end if;

  insert into inventory_batches (
    material_id, location_id, batch_number, quantity_received,
    quantity_remaining, cost_per_unit_tiyn, supplier_partner_id, created_by
  ) values (
    p_material_id, p_location_id, p_batch_number, p_quantity,
    p_quantity, p_cost_per_unit_tiyn, p_supplier_partner_id, auth.uid()
  ) returning id into v_batch_id;

  insert into inventory_transactions (material_id, location_id, delta_quantity, kind, performed_by)
  values (p_material_id, p_location_id, p_quantity, 'receive', auth.uid());

  insert into inventory_balances (material_id, location_id, quantity, reserved_quantity)
  values (p_material_id, p_location_id, p_quantity, 0)
  on conflict (material_id, location_id)
    do update set quantity = inventory_balances.quantity + excluded.quantity;

  return v_batch_id;
end;
$$;

-- Requirement: "Шығыс" + "Себетке шығару" — issues one or more
-- materials in a single transaction (the Flutter "cart" checkout
-- confirms a list of {material_id, location_id, quantity} at once).
-- Consumes the oldest batches first (FIFO) for traceability, but does
-- not require sufficient stock to succeed — same "warn, don't block"
-- philosophy as Production's materials_sufficient flag; a physical
-- shortage is a real-world fact the system should record, not hide
-- behind a blocked transaction.
create or replace function issue_materials(p_items jsonb, p_order_id uuid default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_item record;
  v_remaining numeric;
  v_batch record;
  v_take numeric;
begin
  if not auth_has_permission('warehouse.write') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  for v_item in
    select * from jsonb_to_recordset(p_items)
      as x(material_id uuid, location_id uuid, quantity numeric)
  loop
    if v_item.quantity <= 0 then
      raise exception 'Мөлшер оң сан болуы керек' using errcode = '23514';
    end if;

    insert into inventory_transactions (material_id, location_id, delta_quantity, kind, order_id, performed_by)
    values (v_item.material_id, v_item.location_id, -v_item.quantity, 'issue', p_order_id, auth.uid());

    update inventory_balances
    set quantity = quantity - v_item.quantity
    where material_id = v_item.material_id and location_id = v_item.location_id;

    v_remaining := v_item.quantity;
    for v_batch in
      select id, quantity_remaining from inventory_batches
      where material_id = v_item.material_id
        and location_id = v_item.location_id
        and quantity_remaining > 0
      order by received_at asc
    loop
      exit when v_remaining <= 0;
      v_take := least(v_remaining, v_batch.quantity_remaining);
      update inventory_batches set quantity_remaining = quantity_remaining - v_take
      where id = v_batch.id;
      v_remaining := v_remaining - v_take;
    end loop;
  end loop;
end;
$$;

-- Requirement: "Production резерві" — auto-picks the location with
-- the most available stock when p_location_id is omitted. Always
-- succeeds (even over-reserving past available stock, same "warn not
-- block" reasoning as issue_materials()) — Production's own
-- materials_sufficient flag is what surfaces the shortage.
create or replace function reserve_material_for_order(
  p_order_id uuid,
  p_material_id uuid,
  p_quantity numeric,
  p_location_id uuid default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_reservation_id uuid;
  v_location_id uuid;
begin
  if not auth_has_permission('warehouse.write') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;
  if p_quantity <= 0 then
    raise exception 'Мөлшер оң сан болуы керек' using errcode = '23514';
  end if;

  v_location_id := p_location_id;
  if v_location_id is null then
    select location_id into v_location_id from inventory_balances
    where material_id = p_material_id
    order by (quantity - reserved_quantity) desc
    limit 1;
  end if;

  insert into material_reservations (order_id, material_id, quantity, location_id)
  values (p_order_id, p_material_id, p_quantity, v_location_id)
  returning id into v_reservation_id;

  if v_location_id is not null then
    update inventory_balances
    set reserved_quantity = reserved_quantity + p_quantity
    where material_id = p_material_id and location_id = v_location_id;
  end if;

  return v_reservation_id;
end;
$$;

create or replace function release_order_reservation(p_reservation_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_reservation material_reservations;
begin
  if not auth_has_permission('warehouse.write') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  select * into v_reservation from material_reservations where id = p_reservation_id;
  if not found then
    raise exception 'Резерв табылмады' using errcode = 'P0002';
  end if;

  if v_reservation.location_id is not null then
    update inventory_balances
    set reserved_quantity = greatest(reserved_quantity - v_reservation.quantity, 0)
    where material_id = v_reservation.material_id and location_id = v_reservation.location_id;
  end if;

  delete from material_reservations where id = p_reservation_id;
end;
$$;

-- Requirement: "Резерв" — a generic, non-order hold.
create or replace function create_hold(
  p_material_id uuid,
  p_location_id uuid,
  p_quantity numeric,
  p_reason text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_hold_id uuid;
begin
  if not auth_has_permission('warehouse.write') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;
  if p_quantity <= 0 then
    raise exception 'Мөлшер оң сан болуы керек' using errcode = '23514';
  end if;

  insert into inventory_holds (material_id, location_id, quantity, reason, created_by)
  values (p_material_id, p_location_id, p_quantity, p_reason, auth.uid())
  returning id into v_hold_id;

  update inventory_balances
  set reserved_quantity = reserved_quantity + p_quantity
  where material_id = p_material_id and location_id = p_location_id;

  return v_hold_id;
end;
$$;

create or replace function release_hold(p_hold_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_hold inventory_holds;
begin
  if not auth_has_permission('warehouse.write') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  select * into v_hold from inventory_holds where id = p_hold_id and released_at is null;
  if not found then
    raise exception 'Резерв табылмады' using errcode = 'P0002';
  end if;

  update inventory_holds set released_at = now() where id = p_hold_id;

  update inventory_balances
  set reserved_quantity = greatest(reserved_quantity - v_hold.quantity, 0)
  where material_id = v_hold.material_id and location_id = v_hold.location_id;
end;
$$;
