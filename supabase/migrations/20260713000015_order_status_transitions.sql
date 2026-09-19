-- Per-status role gating for order status transitions — the owner's
-- explicit rule (see ORDER_WORKFLOW.md): each of the 5 statuses may
-- only be *set* by specific roles. This is enforced here at the
-- database layer via a trigger, not just in the Flutter UI (per
-- CLAUDE.md: "hiding a button is not security").
--
-- A lookup table rather than a hardcoded CASE in the trigger function
-- body, so the mapping stays configurable (ORDER_WORKFLOW.md's
-- "status percentages/config should be configurable" principle) —
-- the Flutter app also reads this table directly to only *offer* the
-- statuses a user is allowed to set, instead of duplicating the rule
-- in Dart.
create table order_status_role_permissions (
  status order_status not null,
  role_key role_key not null,
  primary key (status, role_key)
);

insert into order_status_role_permissions (status, role_key) values
  ('measurement', 'measurer'),
  ('measurement', 'manager'),
  ('measurement', 'director'),
  ('accepted', 'manager'),
  ('accepted', 'director'),
  ('in_progress', 'manager'),
  ('in_progress', 'designer'),
  ('in_progress', 'director'),
  ('ready', 'director'),
  ('ready', 'manager'),
  ('ready', 'workshop_manager'),
  ('installed', 'director'),
  ('installed', 'manager'),
  ('installed', 'workshop_manager');

alter table order_status_role_permissions enable row level security;

-- Every active user can read the full mapping (it's what the order
-- form uses to decide which statuses to *offer* — see
-- OrderStatusPicker in the Flutter app); only ever written by this
-- migration/a future admin tool, never by app code, so there is no
-- write policy at all.
create policy "order_status_role_permissions_read_all_active"
  on order_status_role_permissions
  for select using (auth_is_active());

create function auth_can_set_order_status(target_status order_status)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from order_status_role_permissions osrp
    join roles r on r.key = osrp.role_key
    join user_roles ur on ur.role_id = r.id
    where osrp.status = target_status
      and ur.profile_id = auth.uid()
  );
$$;

-- Enforces the role gate on the status column specifically, and
-- automatically logs every real transition to order_status_history
-- (see ORDER_WORKFLOW.md: "every transition writes one row") — the
-- app never inserts into order_status_history directly for ordinary
-- status changes, only this trigger does, so there is exactly one
-- code path that can produce a history row and it can't be skipped by
-- forgetting to call it from the client.
--
-- Deliberately does NOT gate ordinary field edits (address, notes,
-- price, etc.) that leave status unchanged — those stay governed by
-- the regular orders.write RLS policy only, so e.g. a measurer fixing
-- a typo in the address isn't blocked just because they don't hold a
-- role listed for the order's *current* status.
create function enforce_order_status_change()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if TG_OP = 'INSERT' then
    if not auth_can_set_order_status(NEW.status) then
      raise exception 'Бұл статусты орнатуға рұқсатыңыз жоқ' using errcode = '42501';
    end if;
    insert into order_status_history (order_id, previous_status, new_status, changed_by, source)
    values (NEW.id, null, NEW.status, auth.uid(), 'web');
  elsif TG_OP = 'UPDATE' and NEW.status is distinct from OLD.status then
    if not auth_can_set_order_status(NEW.status) then
      raise exception 'Бұл статусты орнатуға рұқсатыңыз жоқ' using errcode = '42501';
    end if;
    insert into order_status_history (order_id, previous_status, new_status, changed_by, source)
    values (NEW.id, OLD.status, NEW.status, auth.uid(), 'web');
  end if;
  return NEW;
end;
$$;

create trigger orders_status_transition_guard
  before insert or update on orders
  for each row execute function enforce_order_status_change();
