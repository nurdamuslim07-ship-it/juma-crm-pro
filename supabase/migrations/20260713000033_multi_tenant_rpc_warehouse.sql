-- Multi-tenant SaaS conversion — Stage 1d, part 7: warehouse RPCs.
--
-- These are SECURITY DEFINER and operate on materials/inventory_batches/
-- inventory_transactions/inventory_balances/material_reservations/
-- inventory_holds with no company filter before this patch — beyond
-- the security gap, several of these would now outright FAIL, since
-- Stage 1b made company_id NOT NULL on every one of those tables and
-- none of these INSERTs supplied it. `get_materials()` is patched
-- separately in 20260713000034 (its live definition was superseded by
-- 20260713000022_purchases_module.sql, not this file).

create or replace function get_material_id_by_barcode(p_barcode text)
returns uuid
language sql
stable
security definer
set search_path = public
as $$
  select m.id from materials m
  where m.barcode = p_barcode
    and m.company_id = auth_company_id()
    and auth_has_permission('warehouse.read')
  limit 1;
$$;

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
declare
  v_company_id uuid := auth_company_id();
begin
  if not auth_has_permission('warehouse.read') then
    return;
  end if;

  return query
    select
      (select count(*) from materials where company_id = v_company_id),
      (
        select count(*) from (
          select m.id, coalesce(sum(ib.quantity - ib.reserved_quantity), 0) as avail
          from materials m
          left join inventory_balances ib on ib.material_id = m.id
          where m.company_id = v_company_id
          group by m.id, m.min_quantity
          having coalesce(sum(ib.quantity - ib.reserved_quantity), 0) < m.min_quantity
        ) low
      ),
      (
        select coalesce(sum(ib.quantity * m.cost_per_unit_tiyn), 0)::bigint
        from inventory_balances ib
        join materials m on m.id = ib.material_id
        where m.company_id = v_company_id
      ),
      (
        select coalesce(jsonb_object_agg(mc.name_kk, cnt), '{}'::jsonb) from (
          select mc.name_kk, count(*) as cnt
          from materials m
          join material_categories mc on mc.id = m.category_id
          where m.company_id = v_company_id
          group by mc.name_kk
        ) mc(name_kk, cnt)
      );
end;
$$;

-- Requirement: "Келіп түсу" — records a new batch and increases the
-- material's balance at the given location in one step. Both
-- p_material_id and p_location_id are verified against the caller's
-- own company before use.
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

-- Requirement: "Шығыс" + "Себетке шығару" — issues one or more
-- materials in a single transaction. Every item's material_id/
-- location_id is verified against the caller's own company.
create or replace function issue_materials(p_items jsonb, p_order_id uuid default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_company_id uuid := auth_company_id();
  v_item record;
  v_remaining numeric;
  v_batch record;
  v_take numeric;
begin
  if not auth_has_permission('warehouse.write') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  if p_order_id is not null
    and not exists (select 1 from orders where id = p_order_id and company_id = v_company_id)
  then
    raise exception 'Тапсырыс табылмады' using errcode = 'P0002';
  end if;

  for v_item in
    select * from jsonb_to_recordset(p_items)
      as x(material_id uuid, location_id uuid, quantity numeric)
  loop
    if v_item.quantity <= 0 then
      raise exception 'Мөлшер оң сан болуы керек' using errcode = '23514';
    end if;

    if not exists (
      select 1 from materials where id = v_item.material_id and company_id = v_company_id
    ) then
      raise exception 'Материал табылмады' using errcode = 'P0002';
    end if;

    if not exists (
      select 1 from warehouse_locations
      where id = v_item.location_id and company_id = v_company_id
    ) then
      raise exception 'Қойма орны табылмады' using errcode = 'P0002';
    end if;

    insert into inventory_transactions (
      company_id, material_id, location_id, delta_quantity, kind, order_id, performed_by
    )
    values (
      v_company_id, v_item.material_id, v_item.location_id, -v_item.quantity,
      'issue', p_order_id, auth.uid()
    );

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

-- Requirement: "Production резерві". p_order_id/p_material_id/
-- p_location_id are all verified against the caller's own company;
-- the auto-picked location (when p_location_id is omitted) is
-- constrained to the same company too.
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
  v_company_id uuid := auth_company_id();
  v_reservation_id uuid;
  v_location_id uuid;
begin
  if not auth_has_permission('warehouse.write') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;
  if p_quantity <= 0 then
    raise exception 'Мөлшер оң сан болуы керек' using errcode = '23514';
  end if;

  if not exists (select 1 from orders where id = p_order_id and company_id = v_company_id) then
    raise exception 'Тапсырыс табылмады' using errcode = 'P0002';
  end if;

  if not exists (
    select 1 from materials where id = p_material_id and company_id = v_company_id
  ) then
    raise exception 'Материал табылмады' using errcode = 'P0002';
  end if;

  v_location_id := p_location_id;
  if v_location_id is null then
    select ib.location_id into v_location_id from inventory_balances ib
    where ib.material_id = p_material_id and ib.company_id = v_company_id
    order by (ib.quantity - ib.reserved_quantity) desc
    limit 1;
  elsif not exists (
    select 1 from warehouse_locations where id = v_location_id and company_id = v_company_id
  ) then
    raise exception 'Қойма орны табылмады' using errcode = 'P0002';
  end if;

  insert into material_reservations (company_id, order_id, material_id, quantity, location_id)
  values (v_company_id, p_order_id, p_material_id, p_quantity, v_location_id)
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
  v_company_id uuid := auth_company_id();
  v_reservation material_reservations;
begin
  if not auth_has_permission('warehouse.write') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  select * into v_reservation from material_reservations
  where id = p_reservation_id and company_id = v_company_id;
  if not found then
    raise exception 'Резерв табылмады' using errcode = 'P0002';
  end if;

  if v_reservation.location_id is not null then
    update inventory_balances
    set reserved_quantity = greatest(reserved_quantity - v_reservation.quantity, 0)
    where material_id = v_reservation.material_id and location_id = v_reservation.location_id;
  end if;

  delete from material_reservations where id = p_reservation_id and company_id = v_company_id;
end;
$$;

-- Requirement: "Резерв" — a generic, non-order hold. p_material_id/
-- p_location_id are verified against the caller's own company.
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
  v_company_id uuid := auth_company_id();
  v_hold_id uuid;
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

  insert into inventory_holds (company_id, material_id, location_id, quantity, reason, created_by)
  values (v_company_id, p_material_id, p_location_id, p_quantity, p_reason, auth.uid())
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
  v_company_id uuid := auth_company_id();
  v_hold inventory_holds;
begin
  if not auth_has_permission('warehouse.write') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  select * into v_hold from inventory_holds
  where id = p_hold_id and company_id = v_company_id and released_at is null;
  if not found then
    raise exception 'Резерв табылмады' using errcode = 'P0002';
  end if;

  update inventory_holds set released_at = now() where id = p_hold_id;

  update inventory_balances
  set reserved_quantity = greatest(reserved_quantity - v_hold.quantity, 0)
  where material_id = v_hold.material_id and location_id = v_hold.location_id;
end;
$$;
