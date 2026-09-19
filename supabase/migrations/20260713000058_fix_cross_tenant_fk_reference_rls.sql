-- Found during live adversarial cross-company testing (zero-blocker
-- pass): a real production account could create/edit an `orders` row
-- in its own company that referenced another company's `client_id`
-- or `responsible_employee_id` — `orders_insert`/`orders_update`'s
-- WITH CHECK validates `company_id = auth_company_id()` for the order
-- itself, but never validates that the *referenced* client/employee
-- belongs to that same company. Same gap confirmed on
-- `clients_insert`/`clients_update` for `responsible_manager_id`.
--
-- Confirmed via a live test (real second company, real second owner
-- account, created and cleaned up during this audit) that this is
-- **not a data-confidentiality leak**: the referenced row's own RLS
-- (`clients_select`) still independently blocks the other company
-- from reading it — a joined `select client:clients(name, phone)`
-- correctly returns `client: null` rather than the real data. But it
-- is a real data-integrity gap (an order can end up pointing at a
-- client that was never actually this company's), and the explicit
-- security requirement for this pass is "cross-company inserts must
-- fail everywhere" — so this closes it directly at the RLS layer
-- rather than leaving it as a "contained but present" gap.
--
-- Fix: extend both policies' WITH CHECK with an EXISTS subquery
-- confirming the referenced row (when not null — both columns are
-- nullable) belongs to the caller's own company, exactly the same
-- pattern already used for `orders_select_assigned`'s own EXISTS
-- subquery elsewhere in this schema. No SELECT/DELETE policy
-- changed, no permission model changed.
drop policy if exists "orders_insert" on orders;
create policy "orders_insert" on orders
  for insert with check (
    auth_is_active() and auth_has_permission('orders.write') and company_id = auth_company_id()
    and exists (select 1 from clients c where c.id = client_id and c.company_id = auth_company_id())
    and (
      responsible_employee_id is null
      or exists (
        select 1 from profiles p
        where p.id = responsible_employee_id and p.company_id = auth_company_id()
      )
    )
  );

drop policy if exists "orders_update" on orders;
create policy "orders_update" on orders
  for update using (
    auth_is_active() and auth_has_permission('orders.write') and company_id = auth_company_id()
  )
  with check (
    auth_is_active() and auth_has_permission('orders.write') and company_id = auth_company_id()
    and exists (select 1 from clients c where c.id = client_id and c.company_id = auth_company_id())
    and (
      responsible_employee_id is null
      or exists (
        select 1 from profiles p
        where p.id = responsible_employee_id and p.company_id = auth_company_id()
      )
    )
  );

drop policy if exists "clients_insert" on clients;
create policy "clients_insert" on clients
  for insert with check (
    auth_is_active() and auth_has_permission('clients.write') and company_id = auth_company_id()
    and (
      responsible_manager_id is null
      or exists (
        select 1 from profiles p
        where p.id = responsible_manager_id and p.company_id = auth_company_id()
      )
    )
  );

drop policy if exists "clients_update" on clients;
create policy "clients_update" on clients
  for update using (
    auth_is_active() and auth_has_permission('clients.write') and company_id = auth_company_id()
  )
  with check (
    auth_is_active() and auth_has_permission('clients.write') and company_id = auth_company_id()
    and (
      responsible_manager_id is null
      or exists (
        select 1 from profiles p
        where p.id = responsible_manager_id and p.company_id = auth_company_id()
      )
    )
  );
