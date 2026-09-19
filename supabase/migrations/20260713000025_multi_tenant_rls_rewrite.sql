-- Multi-tenant SaaS conversion — Stage 1c: RLS rewrite.
--
-- Every policy touching a table that gained `company_id` in
-- 20260713000024 is dropped and recreated here with an added
-- `company_id = auth_company_id()` clause (both `using` and
-- `with check`, wherever the original had one) — the existing
-- `auth_is_active()`/`auth_has_permission()`/`auth_is_director()`
-- checks are otherwise untouched. Global tables (`roles`,
-- `permissions`, `role_permissions`, `app_settings`,
-- `localization_terms`, `order_status_role_permissions`) are
-- deliberately left alone — see 20260713000024's header comment.
--
-- Two tables get MORE than a mechanical addition, because their
-- original policies let any active user see across the whole system,
-- which is a real cross-tenant leak once `companies` exist:
--   * `profiles` — `profiles_select_own_or_colleague` today lets any
--     active user read ANY other profile system-wide; `profiles_director_manage`
--     lets any director write ANY profile system-wide.
--   * `user_roles` — has no `company_id` column of its own (a role
--     assignment belongs to whichever single company its `profiles`
--     row belongs to), so its director-authored policies now join
--     back to `profiles` to confirm the target is in the caller's
--     own company.

-- ---------- profiles / rbac ----------
drop policy if exists "profiles_select_own_or_colleague" on profiles;
create policy "profiles_select_own_or_colleague" on profiles
  for select using (
    auth.uid() = id or (auth_is_active() and company_id = auth_company_id())
  );

drop policy if exists "profiles_director_manage" on profiles;
create policy "profiles_director_manage" on profiles
  for all using (auth_is_director() and company_id = auth_company_id())
  with check (auth_is_director() and company_id = auth_company_id());

drop policy if exists "user_roles_read_own_or_director" on user_roles;
create policy "user_roles_read_own_or_director" on user_roles
  for select using (
    profile_id = auth.uid()
    or (
      auth_is_director()
      and exists (
        select 1 from profiles p
        where p.id = user_roles.profile_id and p.company_id = auth_company_id()
      )
    )
  );

drop policy if exists "user_roles_director_write" on user_roles;
create policy "user_roles_director_write" on user_roles
  for insert with check (
    auth_is_director()
    and exists (
      select 1 from profiles p
      where p.id = user_roles.profile_id and p.company_id = auth_company_id()
    )
  );

drop policy if exists "user_roles_director_delete" on user_roles;
create policy "user_roles_director_delete" on user_roles
  for delete using (
    auth_is_director()
    and exists (
      select 1 from profiles p
      where p.id = user_roles.profile_id and p.company_id = auth_company_id()
    )
  );

-- ---------- clients ----------
drop policy if exists "clients_select" on clients;
create policy "clients_select" on clients
  for select using (
    auth_is_active() and auth_has_permission('clients.read')
    and deleted_at is null and company_id = auth_company_id()
  );

drop policy if exists "clients_insert" on clients;
create policy "clients_insert" on clients
  for insert with check (
    auth_is_active() and auth_has_permission('clients.write') and company_id = auth_company_id()
  );

drop policy if exists "clients_update" on clients;
create policy "clients_update" on clients
  for update using (
    auth_is_active() and auth_has_permission('clients.write') and company_id = auth_company_id()
  )
  with check (
    auth_is_active() and auth_has_permission('clients.write') and company_id = auth_company_id()
  );

drop policy if exists "clients_soft_delete_director" on clients;
create policy "clients_soft_delete_director" on clients
  for delete using (auth_is_director() and company_id = auth_company_id());

drop policy if exists "client_contacts_rw" on client_contacts;
create policy "client_contacts_rw" on client_contacts
  for all using (
    auth_is_active() and auth_has_permission('clients.read') and company_id = auth_company_id()
  )
  with check (
    auth_is_active() and auth_has_permission('clients.write') and company_id = auth_company_id()
  );

drop policy if exists "client_notes_rw" on client_notes;
create policy "client_notes_rw" on client_notes
  for all using (
    auth_is_active() and auth_has_permission('clients.read') and company_id = auth_company_id()
  )
  with check (
    auth_is_active() and auth_has_permission('clients.write') and company_id = auth_company_id()
  );

drop policy if exists "client_files_rw" on client_files;
create policy "client_files_rw" on client_files
  for all using (
    auth_is_active() and auth_has_permission('clients.read') and company_id = auth_company_id()
  )
  with check (
    auth_is_active() and auth_has_permission('clients.write') and company_id = auth_company_id()
  );

-- ---------- orders ----------
drop policy if exists "orders_select_financial" on orders;
create policy "orders_select_financial" on orders
  for select using (
    auth_is_active() and auth_has_permission('orders.read_financial')
    and deleted_at is null and company_id = auth_company_id()
  );

drop policy if exists "orders_select_broad" on orders;
create policy "orders_select_broad" on orders
  for select using (
    auth_is_active() and deleted_at is null
    and auth_has_permission('orders.read_all') and company_id = auth_company_id()
  );

drop policy if exists "orders_select_assigned" on orders;
create policy "orders_select_assigned" on orders
  for select using (
    auth_is_active() and deleted_at is null and auth_has_permission('orders.read')
    and company_id = auth_company_id()
    and exists (
      select 1 from order_assignments oa
      where oa.order_id = orders.id and oa.profile_id = auth.uid()
    )
  );

drop policy if exists "orders_insert" on orders;
create policy "orders_insert" on orders
  for insert with check (
    auth_is_active() and auth_has_permission('orders.write') and company_id = auth_company_id()
  );

drop policy if exists "orders_update" on orders;
create policy "orders_update" on orders
  for update using (
    auth_is_active() and auth_has_permission('orders.write') and company_id = auth_company_id()
  )
  with check (
    auth_is_active() and auth_has_permission('orders.write') and company_id = auth_company_id()
  );

drop policy if exists "orders_delete_director" on orders;
create policy "orders_delete_director" on orders
  for delete using (auth_is_director() and company_id = auth_company_id());

drop policy if exists "order_assignments_select" on order_assignments;
create policy "order_assignments_select" on order_assignments
  for select using (
    auth_is_active() and auth_has_permission('orders.read') and company_id = auth_company_id()
  );

drop policy if exists "order_assignments_write" on order_assignments;
create policy "order_assignments_write" on order_assignments
  for all using (
    auth_is_active() and auth_has_permission('orders.write') and company_id = auth_company_id()
  )
  with check (
    auth_is_active() and auth_has_permission('orders.write') and company_id = auth_company_id()
  );

drop policy if exists "order_status_history_select" on order_status_history;
create policy "order_status_history_select" on order_status_history
  for select using (
    auth_is_active() and auth_has_permission('orders.read') and company_id = auth_company_id()
  );

drop policy if exists "order_status_history_insert" on order_status_history;
create policy "order_status_history_insert" on order_status_history
  for insert with check (
    auth_is_active() and auth_has_permission('orders.write') and company_id = auth_company_id()
  );

drop policy if exists "production_stages_read_all_active" on production_stages;
create policy "production_stages_read_all_active" on production_stages
  for select using (auth_is_active() and company_id = auth_company_id());

drop policy if exists "production_stages_write_director" on production_stages;
create policy "production_stages_write_director" on production_stages
  for all using (auth_is_director() and company_id = auth_company_id())
  with check (auth_is_director() and company_id = auth_company_id());

drop policy if exists "order_production_progress_select" on order_production_progress;
create policy "order_production_progress_select" on order_production_progress
  for select using (
    auth_is_active() and auth_has_permission('production.read') and company_id = auth_company_id()
  );

drop policy if exists "order_production_progress_write" on order_production_progress;
create policy "order_production_progress_write" on order_production_progress
  for all using (
    auth_is_active() and auth_has_permission('production.write') and company_id = auth_company_id()
  )
  with check (
    auth_is_active() and auth_has_permission('production.write') and company_id = auth_company_id()
  );

drop policy if exists "order_files_rw" on order_files;
create policy "order_files_rw" on order_files
  for all using (
    auth_is_active() and auth_has_permission('orders.read') and company_id = auth_company_id()
  )
  with check (
    auth_is_active() and auth_has_permission('orders.write') and company_id = auth_company_id()
  );

-- order_photos' live policy set is order_photos_select/order_photos_write
-- (20260713000020_production_module.sql already dropped the original
-- order_photos_rw and replaced it — see that file's own comment).
drop policy if exists "order_photos_select" on order_photos;
create policy "order_photos_select" on order_photos
  for select using (
    auth_is_active() and auth_has_permission('orders.read') and company_id = auth_company_id()
  );

drop policy if exists "order_photos_write" on order_photos;
create policy "order_photos_write" on order_photos
  for all using (
    auth_is_active() and company_id = auth_company_id()
    and (auth_has_permission('orders.write') or auth_has_permission('production.write'))
  )
  with check (
    auth_is_active() and company_id = auth_company_id()
    and (auth_has_permission('orders.write') or auth_has_permission('production.write'))
  );

-- ---------- measurements & design ----------
drop policy if exists "measurements_select" on measurements;
create policy "measurements_select" on measurements
  for select using (
    auth_is_active() and auth_has_permission('measurements.read') and company_id = auth_company_id()
  );

drop policy if exists "measurements_write" on measurements;
create policy "measurements_write" on measurements
  for all using (
    auth_is_active() and auth_has_permission('measurements.write') and company_id = auth_company_id()
  )
  with check (
    auth_is_active() and auth_has_permission('measurements.write') and company_id = auth_company_id()
  );

drop policy if exists "measurement_items_rw" on measurement_items;
create policy "measurement_items_rw" on measurement_items
  for all using (
    auth_is_active() and auth_has_permission('measurements.read') and company_id = auth_company_id()
  )
  with check (
    auth_is_active() and auth_has_permission('measurements.write') and company_id = auth_company_id()
  );

drop policy if exists "measurement_photos_rw" on measurement_photos;
create policy "measurement_photos_rw" on measurement_photos
  for all using (
    auth_is_active() and auth_has_permission('measurements.read') and company_id = auth_company_id()
  )
  with check (
    auth_is_active() and auth_has_permission('measurements.write') and company_id = auth_company_id()
  );

drop policy if exists "designs_select" on designs;
create policy "designs_select" on designs
  for select using (
    auth_is_active() and auth_has_permission('designs.read') and company_id = auth_company_id()
  );

drop policy if exists "designs_write" on designs;
create policy "designs_write" on designs
  for all using (
    auth_is_active() and auth_has_permission('designs.write') and company_id = auth_company_id()
  )
  with check (
    auth_is_active() and auth_has_permission('designs.write') and company_id = auth_company_id()
  );

drop policy if exists "design_approvals_rw" on design_approvals;
create policy "design_approvals_rw" on design_approvals
  for all using (
    auth_is_active() and auth_has_permission('designs.read') and company_id = auth_company_id()
  )
  with check (
    auth_is_active() and auth_has_permission('designs.write') and company_id = auth_company_id()
  );

-- ---------- finance ----------
drop policy if exists "payment_methods_read_all_active" on payment_methods;
create policy "payment_methods_read_all_active" on payment_methods
  for select using (auth_is_active() and company_id = auth_company_id());

drop policy if exists "cashboxes_read_finance" on cashboxes;
create policy "cashboxes_read_finance" on cashboxes
  for select using (
    auth_is_active() and auth_has_permission('payments.read') and company_id = auth_company_id()
  );

drop policy if exists "bank_accounts_read_finance" on bank_accounts;
create policy "bank_accounts_read_finance" on bank_accounts
  for select using (
    auth_is_active() and auth_has_permission('payments.read') and company_id = auth_company_id()
  );

drop policy if exists "payments_select" on payments;
create policy "payments_select" on payments
  for select using (
    auth_is_active() and auth_has_permission('payments.read')
    and deleted_at is null and company_id = auth_company_id()
  );

drop policy if exists "payments_insert" on payments;
create policy "payments_insert" on payments
  for insert with check (
    auth_is_active() and auth_has_permission('payments.write') and company_id = auth_company_id()
  );

drop policy if exists "payments_update" on payments;
create policy "payments_update" on payments
  for update using (
    auth_is_active() and auth_has_permission('payments.write') and company_id = auth_company_id()
  )
  with check (
    auth_is_active() and auth_has_permission('payments.write') and company_id = auth_company_id()
  );

drop policy if exists "payments_delete_director" on payments;
create policy "payments_delete_director" on payments
  for delete using (auth_is_director() and company_id = auth_company_id());

drop policy if exists "expense_categories_read_all_active" on expense_categories;
create policy "expense_categories_read_all_active" on expense_categories
  for select using (auth_is_active() and company_id = auth_company_id());

drop policy if exists "suppliers_rw" on suppliers;
create policy "suppliers_rw" on suppliers
  for all using (
    auth_is_active() and auth_has_permission('warehouse.read') and company_id = auth_company_id()
  )
  with check (
    auth_is_active() and auth_has_permission('warehouse.write') and company_id = auth_company_id()
  );

drop policy if exists "expenses_select" on expenses;
create policy "expenses_select" on expenses
  for select using (
    auth_is_active() and auth_has_permission('expenses.read') and company_id = auth_company_id()
  );

drop policy if exists "expenses_insert" on expenses;
create policy "expenses_insert" on expenses
  for insert with check (
    auth_is_active() and auth_has_permission('expenses.write') and company_id = auth_company_id()
  );

drop policy if exists "expenses_approve" on expenses;
create policy "expenses_approve" on expenses
  for update using (
    auth_is_active() and auth_has_permission('expenses.approve') and company_id = auth_company_id()
  )
  with check (
    auth_is_active() and auth_has_permission('expenses.approve') and company_id = auth_company_id()
  );

drop policy if exists "supplier_debts_rw" on supplier_debts;
create policy "supplier_debts_rw" on supplier_debts
  for all using (
    auth_is_active() and auth_has_permission('payments.read') and company_id = auth_company_id()
  )
  with check (
    auth_is_active() and auth_has_permission('payments.write') and company_id = auth_company_id()
  );

-- idempotency_keys_no_direct_access is untouched (using(false)/with
-- check(false) — no direct client access regardless of tenant).

-- ---------- warehouse ----------
drop policy if exists "material_categories_read_all_active" on material_categories;
create policy "material_categories_read_all_active" on material_categories
  for select using (auth_is_active() and company_id = auth_company_id());

drop policy if exists "materials_select" on materials;
create policy "materials_select" on materials
  for select using (
    auth_is_active() and auth_has_permission('warehouse.read') and company_id = auth_company_id()
  );

drop policy if exists "materials_write" on materials;
create policy "materials_write" on materials
  for all using (
    auth_is_active() and auth_has_permission('warehouse.write') and company_id = auth_company_id()
  )
  with check (
    auth_is_active() and auth_has_permission('warehouse.write') and company_id = auth_company_id()
  );

drop policy if exists "warehouses_read_all_active" on warehouses;
create policy "warehouses_read_all_active" on warehouses
  for select using (auth_is_active() and company_id = auth_company_id());

drop policy if exists "warehouse_locations_read_all_active" on warehouse_locations;
create policy "warehouse_locations_read_all_active" on warehouse_locations
  for select using (auth_is_active() and company_id = auth_company_id());

drop policy if exists "inventory_balances_select" on inventory_balances;
create policy "inventory_balances_select" on inventory_balances
  for select using (
    auth_is_active() and auth_has_permission('warehouse.read') and company_id = auth_company_id()
  );

drop policy if exists "inventory_balances_write" on inventory_balances;
create policy "inventory_balances_write" on inventory_balances
  for all using (
    auth_is_active() and auth_has_permission('warehouse.write') and company_id = auth_company_id()
  )
  with check (
    auth_is_active() and auth_has_permission('warehouse.write') and company_id = auth_company_id()
  );

drop policy if exists "inventory_transactions_select" on inventory_transactions;
create policy "inventory_transactions_select" on inventory_transactions
  for select using (
    auth_is_active() and auth_has_permission('warehouse.read') and company_id = auth_company_id()
  );

drop policy if exists "inventory_transactions_insert" on inventory_transactions;
create policy "inventory_transactions_insert" on inventory_transactions
  for insert with check (
    auth_is_active() and auth_has_permission('warehouse.write') and company_id = auth_company_id()
  );

drop policy if exists "material_reservations_rw" on material_reservations;
create policy "material_reservations_rw" on material_reservations
  for all using (
    auth_is_active() and auth_has_permission('warehouse.read') and company_id = auth_company_id()
  )
  with check (
    auth_is_active() and auth_has_permission('warehouse.write') and company_id = auth_company_id()
  );

-- purchase_requests / the original (007-file) purchase_orders no
-- longer exist (dropped by 20260713000022_purchases_module.sql), so
-- their 20260713000012 policies are already gone with them — nothing
-- to drop/recreate here.

drop policy if exists "inventory_batches_select" on inventory_batches;
create policy "inventory_batches_select" on inventory_batches
  for select using (
    auth_is_active() and auth_has_permission('warehouse.read') and company_id = auth_company_id()
  );

drop policy if exists "inventory_batches_write" on inventory_batches;
create policy "inventory_batches_write" on inventory_batches
  for all using (
    auth_is_active() and auth_has_permission('warehouse.write') and company_id = auth_company_id()
  )
  with check (
    auth_is_active() and auth_has_permission('warehouse.write') and company_id = auth_company_id()
  );

drop policy if exists "inventory_holds_select" on inventory_holds;
create policy "inventory_holds_select" on inventory_holds
  for select using (
    auth_is_active() and auth_has_permission('warehouse.read') and company_id = auth_company_id()
  );

drop policy if exists "inventory_holds_write" on inventory_holds;
create policy "inventory_holds_write" on inventory_holds
  for all using (
    auth_is_active() and auth_has_permission('warehouse.write') and company_id = auth_company_id()
  )
  with check (
    auth_is_active() and auth_has_permission('warehouse.write') and company_id = auth_company_id()
  );

-- ---------- logistics ----------
drop policy if exists "deliveries_select" on deliveries;
create policy "deliveries_select" on deliveries
  for select using (
    auth_is_active() and auth_has_permission('delivery.read') and company_id = auth_company_id()
  );

drop policy if exists "deliveries_write" on deliveries;
create policy "deliveries_write" on deliveries
  for all using (
    auth_is_active() and auth_has_permission('delivery.write') and company_id = auth_company_id()
  )
  with check (
    auth_is_active() and auth_has_permission('delivery.write') and company_id = auth_company_id()
  );

drop policy if exists "installations_select" on installations;
create policy "installations_select" on installations
  for select using (
    auth_is_active() and auth_has_permission('delivery.read') and company_id = auth_company_id()
  );

drop policy if exists "installations_write" on installations;
create policy "installations_write" on installations
  for all using (
    auth_is_active() and auth_has_permission('delivery.write') and company_id = auth_company_id()
  )
  with check (
    auth_is_active() and auth_has_permission('delivery.write') and company_id = auth_company_id()
  );

drop policy if exists "installation_checklists_rw" on installation_checklists;
create policy "installation_checklists_rw" on installation_checklists
  for all using (
    auth_is_active() and auth_has_permission('delivery.read') and company_id = auth_company_id()
  )
  with check (
    auth_is_active() and auth_has_permission('delivery.write') and company_id = auth_company_id()
  );

drop policy if exists "warranty_requests_select" on warranty_requests;
create policy "warranty_requests_select" on warranty_requests
  for select using (
    auth_is_active() and auth_has_permission('orders.read') and company_id = auth_company_id()
  );

drop policy if exists "warranty_requests_write" on warranty_requests;
create policy "warranty_requests_write" on warranty_requests
  for all using (
    auth_is_active() and auth_has_permission('orders.write') and company_id = auth_company_id()
  )
  with check (
    auth_is_active() and auth_has_permission('orders.write') and company_id = auth_company_id()
  );

drop policy if exists "service_requests_select" on service_requests;
create policy "service_requests_select" on service_requests
  for select using (
    auth_is_active() and auth_has_permission('orders.read') and company_id = auth_company_id()
  );

drop policy if exists "service_requests_write" on service_requests;
create policy "service_requests_write" on service_requests
  for all using (
    auth_is_active() and auth_has_permission('orders.write') and company_id = auth_company_id()
  )
  with check (
    auth_is_active() and auth_has_permission('orders.write') and company_id = auth_company_id()
  );

-- ---------- tasks ----------
drop policy if exists "tasks_select_own_or_permitted" on tasks;
create policy "tasks_select_own_or_permitted" on tasks
  for select using (
    auth_is_active() and company_id = auth_company_id() and (
      assigned_to = auth.uid() or created_by = auth.uid() or auth_has_permission('orders.write')
    )
  );

drop policy if exists "tasks_insert" on tasks;
create policy "tasks_insert" on tasks
  for insert with check (auth_is_active() and company_id = auth_company_id());

drop policy if exists "tasks_update_own_or_permitted" on tasks;
create policy "tasks_update_own_or_permitted" on tasks
  for update using (
    auth_is_active() and company_id = auth_company_id()
    and (assigned_to = auth.uid() or auth_has_permission('orders.write'))
  )
  with check (
    auth_is_active() and company_id = auth_company_id()
    and (assigned_to = auth.uid() or auth_has_permission('orders.write'))
  );

drop policy if exists "task_comments_rw" on task_comments;
create policy "task_comments_rw" on task_comments
  for all using (auth_is_active() and company_id = auth_company_id())
  with check (auth_is_active() and company_id = auth_company_id());

drop policy if exists "task_checklists_rw" on task_checklists;
create policy "task_checklists_rw" on task_checklists
  for all using (auth_is_active() and company_id = auth_company_id())
  with check (auth_is_active() and company_id = auth_company_id());

-- ---------- system ----------
drop policy if exists "documents_select" on documents;
create policy "documents_select" on documents
  for select using (
    auth_is_active() and auth_has_permission('orders.read') and company_id = auth_company_id()
  );

drop policy if exists "documents_write" on documents;
create policy "documents_write" on documents
  for all using (
    auth_is_active() and auth_has_permission('orders.write') and company_id = auth_company_id()
  )
  with check (
    auth_is_active() and auth_has_permission('orders.write') and company_id = auth_company_id()
  );

drop policy if exists "notifications_own" on notifications;
create policy "notifications_own" on notifications
  for select using (profile_id = auth.uid() and company_id = auth_company_id());

drop policy if exists "notifications_own_update" on notifications;
create policy "notifications_own_update" on notifications
  for update using (profile_id = auth.uid() and company_id = auth_company_id())
  with check (profile_id = auth.uid() and company_id = auth_company_id());

drop policy if exists "notification_preferences_own" on notification_preferences;
create policy "notification_preferences_own" on notification_preferences
  for all using (profile_id = auth.uid() and company_id = auth_company_id())
  with check (profile_id = auth.uid() and company_id = auth_company_id());

drop policy if exists "audit_logs_select_director" on audit_logs;
create policy "audit_logs_select_director" on audit_logs
  for select using (auth_is_director() and company_id = auth_company_id());

drop policy if exists "audit_logs_insert" on audit_logs;
create policy "audit_logs_insert" on audit_logs
  for insert with check (auth_is_active() and company_id = auth_company_id());

drop policy if exists "activity_feed_read_all_active" on activity_feed;
create policy "activity_feed_read_all_active" on activity_feed
  for select using (auth_is_active() and company_id = auth_company_id());

drop policy if exists "activity_feed_insert" on activity_feed;
create policy "activity_feed_insert" on activity_feed
  for insert with check (auth_is_active() and company_id = auth_company_id());

drop policy if exists "comments_read_all_active" on comments;
create policy "comments_read_all_active" on comments
  for select using (auth_is_active() and company_id = auth_company_id());

drop policy if exists "comments_insert" on comments;
create policy "comments_insert" on comments
  for insert with check (auth_is_active() and company_id = auth_company_id());

drop policy if exists "mentions_read_all_active" on mentions;
create policy "mentions_read_all_active" on mentions
  for select using (auth_is_active() and company_id = auth_company_id());

drop policy if exists "mentions_insert" on mentions;
create policy "mentions_insert" on mentions
  for insert with check (auth_is_active() and company_id = auth_company_id());

-- app_settings / localization_terms stay global — no change.

-- ---------- employees (defense-in-depth only; real gate is the REVOKE
-- + SECURITY DEFINER RPCs, patched separately for company scoping) ----------
drop policy if exists "employees_select_definer_only" on employees;
create policy "employees_select_definer_only" on employees
  for select using (
    deleted_at is null and company_id = auth_company_id() and (
      auth_has_permission('employees.read_financial')
      or auth_has_permission('employees.read')
      or user_id = auth.uid()
    )
  );

drop policy if exists "employees_write_director_only" on employees;
create policy "employees_write_director_only" on employees
  for all using (auth_is_director() and company_id = auth_company_id())
  with check (auth_is_director() and company_id = auth_company_id());

-- ---------- partners (defense-in-depth only; real gate is the REVOKE
-- + SECURITY DEFINER RPCs) ----------
drop policy if exists "partners_select_with_read_permission" on partners;
create policy "partners_select_with_read_permission" on partners
  for select using (
    (deleted_at is null or auth_is_director())
    and company_id = auth_company_id()
    and (
      auth_has_permission('partners.read')
      or auth_has_permission('partners.read_extended')
      or auth_has_permission('partners.read_financial')
    )
  );

drop policy if exists "partners_insert_write_permission" on partners;
create policy "partners_insert_write_permission" on partners
  for insert with check (auth_has_permission('partners.write') and company_id = auth_company_id());

drop policy if exists "partners_update_write_permission" on partners;
create policy "partners_update_write_permission" on partners
  for update using (auth_has_permission('partners.write') and company_id = auth_company_id())
  with check (auth_has_permission('partners.write') and company_id = auth_company_id());

drop policy if exists "partners_delete_director_only" on partners;
create policy "partners_delete_director_only" on partners
  for delete using (auth_is_director() and company_id = auth_company_id());

drop policy if exists "partner_documents_select_extended" on partner_documents;
create policy "partner_documents_select_extended" on partner_documents
  for select using (
    company_id = auth_company_id()
    and (
      auth_has_permission('partners.read_extended')
      or auth_has_permission('partners.read_financial')
    )
  );

drop policy if exists "partner_documents_write_permission" on partner_documents;
create policy "partner_documents_write_permission" on partner_documents
  for all using (auth_has_permission('partners.write') and company_id = auth_company_id())
  with check (auth_has_permission('partners.write') and company_id = auth_company_id());

-- ---------- production (module 20) ----------
drop policy if exists "production_time_logs_select" on production_time_logs;
create policy "production_time_logs_select" on production_time_logs
  for select using (
    auth_is_active() and auth_has_permission('production.read') and company_id = auth_company_id()
  );

drop policy if exists "production_time_logs_insert" on production_time_logs;
create policy "production_time_logs_insert" on production_time_logs
  for insert with check (
    auth_is_active() and auth_has_permission('production.write') and company_id = auth_company_id()
    and (
      employee_id = auth.uid()
      or auth_is_director()
      or auth_has_role('workshop_manager')
    )
  );

drop policy if exists "production_time_logs_update" on production_time_logs;
create policy "production_time_logs_update" on production_time_logs
  for update using (
    auth_is_active() and auth_has_permission('production.write') and company_id = auth_company_id()
    and (
      employee_id = auth.uid()
      or auth_is_director()
      or auth_has_role('workshop_manager')
    )
  );

drop policy if exists "production_stage_history_select" on production_stage_history;
create policy "production_stage_history_select" on production_stage_history
  for select using (
    auth_is_active() and auth_has_permission('production.read') and company_id = auth_company_id()
  );

drop policy if exists "production_stage_history_insert" on production_stage_history;
create policy "production_stage_history_insert" on production_stage_history
  for insert with check (
    auth_is_active() and auth_has_permission('production.write') and company_id = auth_company_id()
  );

-- ---------- purchases (module 22) ----------
drop policy if exists "purchase_orders_select" on purchase_orders;
create policy "purchase_orders_select" on purchase_orders
  for select using (
    auth_is_active() and auth_has_permission('purchases.read') and company_id = auth_company_id()
  );

drop policy if exists "purchase_orders_write" on purchase_orders;
create policy "purchase_orders_write" on purchase_orders
  for all using (
    auth_is_active() and auth_has_permission('purchases.write') and company_id = auth_company_id()
  )
  with check (
    auth_is_active() and auth_has_permission('purchases.write') and company_id = auth_company_id()
  );

drop policy if exists "purchase_order_items_select" on purchase_order_items;
create policy "purchase_order_items_select" on purchase_order_items
  for select using (
    auth_is_active() and auth_has_permission('purchases.read') and company_id = auth_company_id()
  );

drop policy if exists "purchase_order_items_write" on purchase_order_items;
create policy "purchase_order_items_write" on purchase_order_items
  for all using (
    auth_is_active() and auth_has_permission('purchases.write') and company_id = auth_company_id()
  )
  with check (
    auth_is_active() and auth_has_permission('purchases.write') and company_id = auth_company_id()
  );

drop policy if exists "supplier_invoices_select" on supplier_invoices;
create policy "supplier_invoices_select" on supplier_invoices
  for select using (
    auth_is_active() and auth_has_permission('purchases.read') and company_id = auth_company_id()
  );

drop policy if exists "supplier_invoices_write" on supplier_invoices;
create policy "supplier_invoices_write" on supplier_invoices
  for all using (
    auth_is_active() and auth_has_permission('purchases.write') and company_id = auth_company_id()
  )
  with check (
    auth_is_active() and auth_has_permission('purchases.write') and company_id = auth_company_id()
  );

drop policy if exists "supplier_payments_select" on supplier_payments;
create policy "supplier_payments_select" on supplier_payments
  for select using (
    auth_is_active() and auth_has_permission('purchases.read') and company_id = auth_company_id()
  );

drop policy if exists "supplier_payments_write" on supplier_payments;
create policy "supplier_payments_write" on supplier_payments
  for all using (
    auth_is_active() and auth_has_permission('purchases.pay') and company_id = auth_company_id()
  )
  with check (
    auth_is_active() and auth_has_permission('purchases.pay') and company_id = auth_company_id()
  );
