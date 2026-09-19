-- Production module — see Production module requirements. The
-- shop-floor Kanban (production_stages, seeded with the owner's exact
-- 9-stage list in supabase/seed/seed.sql) is a DIFFERENT axis from the
-- order-level `order_status` enum (measurement/accepted/in_progress/
-- ready/installed): 'installed' appears as a card position in both,
-- but moving a card to "Орнатылды" here never touches
-- `orders.status` — that stays an explicit, role-gated action via
-- the existing order_status_role_permissions trigger. Per CLAUDE.md's
-- "production % and payment % are two independent values" rule, this
-- extends to "production stage and order status are two independent
-- concepts" — this module never writes to `orders.status`.
--
-- Visibility follows ROLES_AND_PERMISSIONS.md's documented matrix
-- ("Production stage": director RU, manager R, workshop_manager RU,
-- master RU (assigned), — no existing table RLS expresses "assigned"
-- scoping for this table, so get_production_queue()/
-- get_order_production_detail() are SECURITY DEFINER RPCs that apply
-- it explicitly, same architectural choice as Employees/Partners/
-- Analytics: broad roles (director/workshop_manager/manager) see every
-- order in production; master/anyone else with only production.read
-- sees just the orders they're assigned to (order_assignments or
-- orders.responsible_employee_id).

create table production_time_logs (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders (id) on delete cascade,
  stage_id uuid references production_stages (id),
  employee_id uuid not null references profiles (id),
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  created_at timestamptz not null default now()
);

create index production_time_logs_order_id_idx on production_time_logs (order_id);
create index production_time_logs_employee_id_idx on production_time_logs (employee_id);

-- Append-only audit trail — same convention as order_status_history:
-- one row per real stage transition, written only by the trigger
-- below, never directly by application code.
create table production_stage_history (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders (id) on delete cascade,
  previous_stage_id uuid references production_stages (id),
  new_stage_id uuid references production_stages (id),
  changed_by uuid references profiles (id),
  changed_at timestamptz not null default now(),
  comment text
);

create index production_stage_history_order_id_idx on production_stage_history (order_id);

alter table production_time_logs enable row level security;
alter table production_stage_history enable row level security;

create policy "production_time_logs_select" on production_time_logs
  for select using (auth_is_active() and auth_has_permission('production.read'));

-- Insert/update your OWN time log, unless you're a director/
-- workshop_manager correcting someone else's forgotten timer.
create policy "production_time_logs_insert" on production_time_logs
  for insert with check (
    auth_is_active() and auth_has_permission('production.write')
    and (
      employee_id = auth.uid()
      or auth_is_director()
      or auth_has_role('workshop_manager')
    )
  );

create policy "production_time_logs_update" on production_time_logs
  for update using (
    auth_is_active() and auth_has_permission('production.write')
    and (
      employee_id = auth.uid()
      or auth_is_director()
      or auth_has_role('workshop_manager')
    )
  );

create policy "production_stage_history_select" on production_stage_history
  for select using (auth_is_active() and auth_has_permission('production.read'));

-- Written only by enforce_production_stage_change() below, which runs
-- with the invoker's own privileges (not SECURITY DEFINER) — same
-- pattern as enforce_order_status_change()/order_status_history, so
-- the insert succeeds under the same production.write permission that
-- already gated the order_production_progress UPDATE that triggered it.
create policy "production_stage_history_insert" on production_stage_history
  for insert with check (auth_is_active() and auth_has_permission('production.write'));

-- Logs every real stage change and keeps percent_complete in sync with
-- the new stage's default_percent, so callers never have to set both
-- fields separately (and can't drift them out of sync).
create function enforce_production_stage_change()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_default_percent smallint;
begin
  if NEW.current_stage_id is not null and (
    TG_OP = 'INSERT' or NEW.current_stage_id is distinct from OLD.current_stage_id
  ) then
    select default_percent into v_default_percent
    from production_stages where id = NEW.current_stage_id;
    NEW.percent_complete := coalesce(v_default_percent, NEW.percent_complete);

    insert into production_stage_history (order_id, previous_stage_id, new_stage_id, changed_by)
    values (
      NEW.order_id,
      case when TG_OP = 'UPDATE' then OLD.current_stage_id else null end,
      NEW.current_stage_id,
      auth.uid()
    );
  end if;
  NEW.updated_by := auth.uid();
  NEW.updated_at := now();
  return NEW;
end;
$$;

create trigger order_production_progress_stage_change
  before insert or update on order_production_progress
  for each row execute function enforce_production_stage_change();

-- order_photos' original write policy (20260713000012_rls_policies.sql)
-- gates insert on `orders.write`, which master deliberately does NOT
-- hold (per the Orders module's design — master can move production
-- stages but shouldn't edit order price/fields). Requirement #2
-- "Фото тіркеу" needs master to attach photos, so this replaces that
-- policy to also accept `production.write`.
drop policy if exists "order_photos_rw" on order_photos;

create policy "order_photos_select" on order_photos
  for select using (auth_is_active() and auth_has_permission('orders.read'));

create policy "order_photos_write" on order_photos
  for all using (
    auth_is_active()
    and (auth_has_permission('orders.write') or auth_has_permission('production.write'))
  )
  with check (
    auth_is_active()
    and (auth_has_permission('orders.write') or auth_has_permission('production.write'))
  );

insert into storage.buckets (id, name, public)
values ('order-photos', 'order-photos', false)
on conflict (id) do nothing;

create policy "order_photos_bucket_read"
  on storage.objects for select
  using (bucket_id = 'order-photos' and auth_has_permission('orders.read'));

create policy "order_photos_bucket_write"
  on storage.objects for insert
  with check (
    bucket_id = 'order-photos'
    and (auth_has_permission('orders.write') or auth_has_permission('production.write'))
  );

create policy "order_photos_bucket_delete"
  on storage.objects for delete
  using (
    bucket_id = 'order-photos'
    and (auth_has_permission('orders.write') or auth_has_permission('production.write'))
  );

-- Requirement: "Өндіріс кезегі" + "Цех тақтасы (Kanban)" — every order
-- currently in production (order_status = 'in_progress'), defaulted to
-- the first stage ("Күтіп тұр") when no order_production_progress row
-- exists yet, so a freshly-accepted order shows up on the board
-- without a manual first insert.
create or replace function get_production_queue(
  p_stage_id uuid default null,
  p_master_id uuid default null,
  p_search text default null
)
returns table (
  order_id uuid,
  order_number text,
  product_type text,
  client_name text,
  stage_id uuid,
  stage_key text,
  stage_name_kk text,
  stage_sort_order int,
  percent_complete smallint,
  master_id uuid,
  master_name text,
  materials_sufficient boolean,
  photos_count bigint,
  planned_completion_date date,
  updated_at timestamptz
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
  v_scope_assigned boolean := v_read and not v_scope_all;
  v_default_stage_id uuid;
begin
  if not v_read then
    return;
  end if;

  select id into v_default_stage_id from production_stages order by sort_order limit 1;

  return query
    select
      o.id,
      o.order_number,
      o.product_type,
      c.name,
      coalesce(ps.id, v_default_stage_id),
      coalesce(ps.key, (select key from production_stages where id = v_default_stage_id)),
      coalesce(ps.name_kk, (select name_kk from production_stages where id = v_default_stage_id)),
      coalesce(ps.sort_order, 1),
      coalesce(opp.percent_complete, 0),
      m.profile_id,
      m.full_name,
      not exists (
        select 1 from material_reservations mr
        where mr.order_id = o.id
          and mr.quantity > coalesce((
            select sum(ib.quantity - ib.reserved_quantity)
            from inventory_balances ib where ib.material_id = mr.material_id
          ), 0)
      ),
      (select count(*) from order_photos op where op.order_id = o.id and op.kind = 'production'),
      o.planned_completion_date,
      coalesce(opp.updated_at, o.updated_at)
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
    where o.deleted_at is null
      and o.status = 'in_progress'
      and (
        v_scope_all
        or (
          v_scope_assigned and (
            o.responsible_employee_id = auth.uid()
            or exists (
              select 1 from order_assignments oa2
              where oa2.order_id = o.id and oa2.profile_id = auth.uid()
            )
          )
        )
      )
      and (p_stage_id is null or coalesce(ps.id, v_default_stage_id) = p_stage_id)
      and (p_master_id is null or m.profile_id = p_master_id)
      and (
        p_search is null or p_search = '' or
        o.order_number ilike '%' || p_search || '%' or
        o.product_type ilike '%' || p_search || '%' or
        c.name ilike '%' || p_search || '%'
      )
    order by coalesce(ps.sort_order, 1), o.planned_completion_date nulls last;
end;
$$;

-- Requirement: full single-order production view — stage, master,
-- material availability breakdown, recent photos, time logs, stage
-- history. Raises for a caller with no production.read at all, or
-- with production.read but not assigned to this specific order (same
-- "assigned" scoping as get_production_queue()) — unlike the list
-- RPC's silent-empty convention, a direct detail fetch of an order
-- you have no business viewing is treated as a blocked action.
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

-- Requirement: "Drag & Drop Kanban" — the RPC the Kanban board's drop
-- handler calls. Upserts order_production_progress; percent_complete
-- and the history row are handled entirely by the trigger above, so
-- this never has to duplicate that logic.
create or replace function move_order_to_stage(
  p_order_id uuid,
  p_stage_id uuid,
  p_comment text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not auth_has_permission('production.write') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  insert into order_production_progress (order_id, current_stage_id)
  values (p_order_id, p_stage_id)
  on conflict (order_id) do update set current_stage_id = excluded.current_stage_id;

  if p_comment is not null then
    update production_stage_history set comment = p_comment
    where order_id = p_order_id
    order by changed_at desc
    limit 1;
  end if;
end;
$$;

-- Requirement: "Әр тапсырысқа жауапты шебер" — assigning/reassigning
-- work is a supervisory action, not something a peer master does to
-- themselves or each other, so this is director/workshop_manager/
-- manager only (stricter than the base production.write permission
-- that workshop_manager/master also hold). manager is included per
-- the role matrix's "Manager: көру және жоспарлау" — planning who
-- works on what is a manager responsibility distinct from actually
-- moving Kanban cards day-to-day, which stays workshop_manager/
-- master's job (manager has production.read only, not
-- production.write — see get_production_queue()'s v_scope_all).
create or replace function set_order_master(p_order_id uuid, p_master_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_master_role_id uuid;
begin
  if not (
    auth_is_director() or auth_has_role('workshop_manager') or auth_has_role('manager')
  ) then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  select id into v_master_role_id from roles where key = 'master';

  delete from order_assignments
  where order_id = p_order_id and role = 'master';

  insert into order_assignments (order_id, profile_id, role, assigned_at)
  values (p_order_id, p_master_id, 'master', now());
end;
$$;

-- Backs the master-assignment picker. Deliberately NOT a call to the
-- Employees module's get_employees() — that RPC restricts the full
-- roster to director/manager (employees.read); workshop_manager can
-- call set_order_master() above but doesn't hold employees.read, so
-- it would only ever get its own single row back. This is a narrow,
-- purpose-built substitute: just (user_id, full_name) for active
-- master-role employees, visible to anyone who can actually assign
-- one (same check as set_order_master()) — no salary/contact fields,
-- so it doesn't need Employees' stricter tiering.
create or replace function get_masters()
returns table (user_id uuid, full_name text)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not (
    auth_is_director() or auth_has_role('workshop_manager') or auth_has_role('manager')
  ) then
    return;
  end if;

  return query
    select p.id, p.full_name
    from profiles p
    join user_roles ur on ur.profile_id = p.id
    join roles r on r.id = ur.role_id
    where r.key = 'master' and p.is_active
    order by p.full_name;
end;
$$;

-- Requirement: "Уақыт журналдары" — a master starts a timer when
-- beginning work on an order+stage. Rejects starting a second timer
-- while one is already open (an employee can't be logged into two
-- orders' time at once).
create or replace function start_time_log(p_order_id uuid, p_stage_id uuid default null)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
begin
  if not auth_has_permission('production.write') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  if exists (
    select 1 from production_time_logs
    where employee_id = auth.uid() and ended_at is null
  ) then
    raise exception 'Сізде әлі тоқтатылмаған уақыт журналы бар' using errcode = '23514';
  end if;

  insert into production_time_logs (order_id, stage_id, employee_id)
  values (p_order_id, p_stage_id, auth.uid())
  returning id into v_id;

  return v_id;
end;
$$;

create or replace function stop_time_log(p_log_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not auth_has_permission('production.write') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  update production_time_logs set ended_at = now()
  where id = p_log_id
    and ended_at is null
    and (employee_id = auth.uid() or auth_is_director() or auth_has_role('workshop_manager'));

  if not found then
    raise exception 'Уақыт журналы табылмады' using errcode = 'P0002';
  end if;
end;
$$;
