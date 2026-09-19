-- Row Level Security — the actual, non-bypassable authorization
-- boundary (see ROLES_AND_PERMISSIONS.md "Three-layer enforcement" and
-- SECURITY_PLAN.md finding #6: "hiding a button is not security").
-- Every table gets RLS enabled; policies are keyed off the
-- auth_has_permission()/auth_has_role()/auth_is_director() functions
-- from 20260713000003, which read user_roles → role_permissions.
--
-- Deleted/deactivated users are blocked everywhere via auth_is_active()
-- — see ROLES_AND_PERMISSIONS.md "Director capabilities" (deactivate
-- employee accounts).

-- ---------- profiles / rbac ----------
alter table profiles enable row level security;
alter table roles enable row level security;
alter table permissions enable row level security;
alter table role_permissions enable row level security;
alter table user_roles enable row level security;

create policy "profiles_select_own_or_colleague" on profiles
  for select using (auth.uid() = id or auth_is_active());

create policy "profiles_update_own" on profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

create policy "profiles_director_manage" on profiles
  for all using (auth_is_director()) with check (auth_is_director());

create policy "roles_read_all_active" on roles
  for select using (auth_is_active());

create policy "permissions_read_all_active" on permissions
  for select using (auth_is_active());

create policy "role_permissions_read_all_active" on role_permissions
  for select using (auth_is_active());

create policy "role_permissions_director_write" on role_permissions
  for all using (auth_is_director()) with check (auth_is_director());

create policy "user_roles_read_own_or_director" on user_roles
  for select using (profile_id = auth.uid() or auth_is_director());

create policy "user_roles_director_write" on user_roles
  for insert with check (auth_is_director());

create policy "user_roles_director_delete" on user_roles
  for delete using (auth_is_director());

-- ---------- clients ----------
alter table clients enable row level security;
alter table client_contacts enable row level security;
alter table client_notes enable row level security;
alter table client_files enable row level security;

create policy "clients_select" on clients
  for select using (auth_is_active() and auth_has_permission('clients.read') and deleted_at is null);

create policy "clients_insert" on clients
  for insert with check (auth_is_active() and auth_has_permission('clients.write'));

create policy "clients_update" on clients
  for update using (auth_is_active() and auth_has_permission('clients.write'))
  with check (auth_is_active() and auth_has_permission('clients.write'));

create policy "clients_soft_delete_director" on clients
  for delete using (auth_is_director());

create policy "client_contacts_rw" on client_contacts
  for all using (auth_is_active() and auth_has_permission('clients.read'))
  with check (auth_is_active() and auth_has_permission('clients.write'));

create policy "client_notes_rw" on client_notes
  for all using (auth_is_active() and auth_has_permission('clients.read'))
  with check (auth_is_active() and auth_has_permission('clients.write'));

create policy "client_files_rw" on client_files
  for all using (auth_is_active() and auth_has_permission('clients.read'))
  with check (auth_is_active() and auth_has_permission('clients.write'));

-- ---------- orders ----------
alter table orders enable row level security;
alter table order_assignments enable row level security;
alter table order_status_history enable row level security;
alter table production_stages enable row level security;
alter table order_production_progress enable row level security;
alter table order_files enable row level security;
alter table order_photos enable row level security;

-- Base table includes financial columns (total_amount_tiyn,
-- discount_amount_tiyn) — full row access requires orders.read_financial.
-- Roles without it use the `orders_public` view below instead (see
-- ROLES_AND_PERMISSIONS.md's "manager can view payment status if
-- permitted" / master-spec director-only profit rule).
create policy "orders_select_financial" on orders
  for select using (
    auth_is_active() and auth_has_permission('orders.read_financial') and deleted_at is null
  );

-- Broad, non-financial read for roles that oversee all orders rather
-- than only their own assignments (manager, workshop_manager per
-- ROLES_AND_PERMISSIONS.md's matrix — "manager: RCU", not assigned-only).
create policy "orders_select_broad" on orders
  for select using (
    auth_is_active() and deleted_at is null and auth_has_permission('orders.read_all')
  );

-- Assigned-only read for roles that only need their own work queue
-- (measurer, designer, master, assistant, installer).
create policy "orders_select_assigned" on orders
  for select using (
    auth_is_active() and deleted_at is null and auth_has_permission('orders.read')
    and exists (
      select 1 from order_assignments oa
      where oa.order_id = orders.id and oa.profile_id = auth.uid()
    )
  );

create policy "orders_insert" on orders
  for insert with check (auth_is_active() and auth_has_permission('orders.write'));

create policy "orders_update" on orders
  for update using (auth_is_active() and auth_has_permission('orders.write'))
  with check (auth_is_active() and auth_has_permission('orders.write'));

create policy "orders_delete_director" on orders
  for delete using (auth_is_director());

-- Non-financial view every assigned/permitted role can read regardless
-- of orders.read_financial — closes the "manager/master shouldn't see
-- price" gap without needing column-level Postgres grants per user.
create view orders_public
  with (security_invoker = true) as
  select
    id, order_number, client_id, product_type, material, dimensions,
    description, address, status, priority, tags, contract_date,
    measurement_date, planned_start_date, planned_completion_date,
    delivery_date, installation_date, delay_reason, created_by,
    created_at, updated_at
  from orders
  where deleted_at is null;

create policy "order_assignments_select" on order_assignments
  for select using (auth_is_active() and auth_has_permission('orders.read'));

create policy "order_assignments_write" on order_assignments
  for all using (auth_is_active() and auth_has_permission('orders.write'))
  with check (auth_is_active() and auth_has_permission('orders.write'));

-- Status history is insert-only from the app's perspective — no update
-- or delete policy at all (append-only audit trail, per
-- DATABASE_SCHEMA.md's RLS design summary).
create policy "order_status_history_select" on order_status_history
  for select using (auth_is_active() and auth_has_permission('orders.read'));

create policy "order_status_history_insert" on order_status_history
  for insert with check (auth_is_active() and auth_has_permission('orders.write'));

create policy "production_stages_read_all_active" on production_stages
  for select using (auth_is_active());

create policy "production_stages_write_director" on production_stages
  for all using (auth_is_director()) with check (auth_is_director());

create policy "order_production_progress_select" on order_production_progress
  for select using (auth_is_active() and auth_has_permission('production.read'));

create policy "order_production_progress_write" on order_production_progress
  for all using (auth_is_active() and auth_has_permission('production.write'))
  with check (auth_is_active() and auth_has_permission('production.write'));

create policy "order_files_rw" on order_files
  for all using (auth_is_active() and auth_has_permission('orders.read'))
  with check (auth_is_active() and auth_has_permission('orders.write'));

create policy "order_photos_rw" on order_photos
  for all using (auth_is_active() and auth_has_permission('orders.read'))
  with check (auth_is_active() and auth_has_permission('orders.write'));

-- ---------- measurements & design ----------
alter table measurements enable row level security;
alter table measurement_items enable row level security;
alter table measurement_photos enable row level security;
alter table designs enable row level security;
alter table design_approvals enable row level security;

create policy "measurements_select" on measurements
  for select using (auth_is_active() and auth_has_permission('measurements.read'));

create policy "measurements_write" on measurements
  for all using (auth_is_active() and auth_has_permission('measurements.write'))
  with check (auth_is_active() and auth_has_permission('measurements.write'));

create policy "measurement_items_rw" on measurement_items
  for all using (auth_is_active() and auth_has_permission('measurements.read'))
  with check (auth_is_active() and auth_has_permission('measurements.write'));

create policy "measurement_photos_rw" on measurement_photos
  for all using (auth_is_active() and auth_has_permission('measurements.read'))
  with check (auth_is_active() and auth_has_permission('measurements.write'));

create policy "designs_select" on designs
  for select using (auth_is_active() and auth_has_permission('designs.read'));

create policy "designs_write" on designs
  for all using (auth_is_active() and auth_has_permission('designs.write'))
  with check (auth_is_active() and auth_has_permission('designs.write'));

create policy "design_approvals_rw" on design_approvals
  for all using (auth_is_active() and auth_has_permission('designs.read'))
  with check (auth_is_active() and auth_has_permission('designs.write'));

-- ---------- finance ----------
alter table payment_methods enable row level security;
alter table cashboxes enable row level security;
alter table bank_accounts enable row level security;
alter table payments enable row level security;
alter table expense_categories enable row level security;
alter table suppliers enable row level security;
alter table expenses enable row level security;
alter table supplier_debts enable row level security;
alter table idempotency_keys enable row level security;

create policy "payment_methods_read_all_active" on payment_methods
  for select using (auth_is_active());

create policy "cashboxes_read_finance" on cashboxes
  for select using (auth_is_active() and auth_has_permission('payments.read'));

create policy "bank_accounts_read_finance" on bank_accounts
  for select using (auth_is_active() and auth_has_permission('payments.read'));

-- Payments: created via the record_payment() RPC only in practice
-- (see 20260713000016_payments_module.sql — enforces the overpayment
-- guard), but the insert policy still exists as the RLS-level gate
-- that RPC relies on. Limited-field UPDATE is allowed at the RLS
-- layer (payments.write); the payments_prevent_tamper trigger is what
-- actually stops amount/order/client/status from changing via that
-- UPDATE — see that migration's comment. Hard delete stays
-- director-only/exceptional; ordinary "delete" from the app is a soft
-- delete (UPDATE deleted_at), which the same write policy covers.
create policy "payments_select" on payments
  for select using (
    auth_is_active() and auth_has_permission('payments.read') and deleted_at is null
  );

create policy "payments_insert" on payments
  for insert with check (auth_is_active() and auth_has_permission('payments.write'));

create policy "payments_update" on payments
  for update using (auth_is_active() and auth_has_permission('payments.write'))
  with check (auth_is_active() and auth_has_permission('payments.write'));

create policy "payments_delete_director" on payments
  for delete using (auth_is_director());

create policy "expense_categories_read_all_active" on expense_categories
  for select using (auth_is_active());

create policy "suppliers_rw" on suppliers
  for all using (auth_is_active() and auth_has_permission('warehouse.read'))
  with check (auth_is_active() and auth_has_permission('warehouse.write'));

create policy "expenses_select" on expenses
  for select using (auth_is_active() and auth_has_permission('expenses.read'));

create policy "expenses_insert" on expenses
  for insert with check (auth_is_active() and auth_has_permission('expenses.write'));

create policy "expenses_approve" on expenses
  for update using (auth_is_active() and auth_has_permission('expenses.approve'))
  with check (auth_is_active() and auth_has_permission('expenses.approve'));

create policy "supplier_debts_rw" on supplier_debts
  for all using (auth_is_active() and auth_has_permission('payments.read'))
  with check (auth_is_active() and auth_has_permission('payments.write'));

-- Idempotency keys are only ever touched via SECURITY DEFINER RPCs
-- (record_payment / record_expense, below) — no direct client policy.
create policy "idempotency_keys_no_direct_access" on idempotency_keys
  for all using (false) with check (false);

-- ---------- warehouse ----------
alter table material_categories enable row level security;
alter table materials enable row level security;
alter table warehouses enable row level security;
alter table warehouse_locations enable row level security;
alter table inventory_balances enable row level security;
alter table inventory_transactions enable row level security;
alter table material_reservations enable row level security;
alter table purchase_requests enable row level security;
alter table purchase_orders enable row level security;

create policy "material_categories_read_all_active" on material_categories
  for select using (auth_is_active());

create policy "materials_select" on materials
  for select using (auth_is_active() and auth_has_permission('warehouse.read'));

create policy "materials_write" on materials
  for all using (auth_is_active() and auth_has_permission('warehouse.write'))
  with check (auth_is_active() and auth_has_permission('warehouse.write'));

create policy "warehouses_read_all_active" on warehouses
  for select using (auth_is_active());

create policy "warehouse_locations_read_all_active" on warehouse_locations
  for select using (auth_is_active());

create policy "inventory_balances_select" on inventory_balances
  for select using (auth_is_active() and auth_has_permission('warehouse.read'));

create policy "inventory_balances_write" on inventory_balances
  for all using (auth_is_active() and auth_has_permission('warehouse.write'))
  with check (auth_is_active() and auth_has_permission('warehouse.write'));

create policy "inventory_transactions_select" on inventory_transactions
  for select using (auth_is_active() and auth_has_permission('warehouse.read'));

create policy "inventory_transactions_insert" on inventory_transactions
  for insert with check (auth_is_active() and auth_has_permission('warehouse.write'));

create policy "material_reservations_rw" on material_reservations
  for all using (auth_is_active() and auth_has_permission('warehouse.read'))
  with check (auth_is_active() and auth_has_permission('warehouse.write'));

create policy "purchase_requests_select" on purchase_requests
  for select using (auth_is_active() and auth_has_permission('warehouse.read'));

create policy "purchase_requests_insert" on purchase_requests
  for insert with check (auth_is_active() and auth_has_permission('warehouse.write'));

create policy "purchase_requests_approve" on purchase_requests
  for update using (auth_is_active() and auth_has_permission('warehouse.write'))
  with check (auth_is_active() and auth_has_permission('warehouse.write'));

create policy "purchase_orders_rw" on purchase_orders
  for all using (auth_is_active() and auth_has_permission('warehouse.read'))
  with check (auth_is_active() and auth_has_permission('warehouse.write'));

-- ---------- logistics ----------
alter table deliveries enable row level security;
alter table installations enable row level security;
alter table installation_checklists enable row level security;
alter table warranty_requests enable row level security;
alter table service_requests enable row level security;

create policy "deliveries_select" on deliveries
  for select using (auth_is_active() and auth_has_permission('delivery.read'));

create policy "deliveries_write" on deliveries
  for all using (auth_is_active() and auth_has_permission('delivery.write'))
  with check (auth_is_active() and auth_has_permission('delivery.write'));

create policy "installations_select" on installations
  for select using (auth_is_active() and auth_has_permission('delivery.read'));

create policy "installations_write" on installations
  for all using (auth_is_active() and auth_has_permission('delivery.write'))
  with check (auth_is_active() and auth_has_permission('delivery.write'));

create policy "installation_checklists_rw" on installation_checklists
  for all using (auth_is_active() and auth_has_permission('delivery.read'))
  with check (auth_is_active() and auth_has_permission('delivery.write'));

create policy "warranty_requests_select" on warranty_requests
  for select using (auth_is_active() and auth_has_permission('orders.read'));

create policy "warranty_requests_write" on warranty_requests
  for all using (auth_is_active() and auth_has_permission('orders.write'))
  with check (auth_is_active() and auth_has_permission('orders.write'));

create policy "service_requests_select" on service_requests
  for select using (auth_is_active() and auth_has_permission('orders.read'));

create policy "service_requests_write" on service_requests
  for all using (auth_is_active() and auth_has_permission('orders.write'))
  with check (auth_is_active() and auth_has_permission('orders.write'));

-- ---------- tasks ----------
alter table tasks enable row level security;
alter table task_comments enable row level security;
alter table task_checklists enable row level security;

create policy "tasks_select_own_or_permitted" on tasks
  for select using (
    auth_is_active() and (
      assigned_to = auth.uid() or created_by = auth.uid() or auth_has_permission('orders.write')
    )
  );

create policy "tasks_insert" on tasks
  for insert with check (auth_is_active());

create policy "tasks_update_own_or_permitted" on tasks
  for update using (
    auth_is_active() and (assigned_to = auth.uid() or auth_has_permission('orders.write'))
  )
  with check (
    auth_is_active() and (assigned_to = auth.uid() or auth_has_permission('orders.write'))
  );

create policy "task_comments_rw" on task_comments
  for all using (auth_is_active())
  with check (auth_is_active());

create policy "task_checklists_rw" on task_checklists
  for all using (auth_is_active())
  with check (auth_is_active());

-- ---------- system ----------
alter table documents enable row level security;
alter table notifications enable row level security;
alter table notification_preferences enable row level security;
alter table audit_logs enable row level security;
alter table activity_feed enable row level security;
alter table comments enable row level security;
alter table mentions enable row level security;
alter table app_settings enable row level security;
alter table localization_terms enable row level security;

create policy "documents_select" on documents
  for select using (auth_is_active() and auth_has_permission('orders.read'));

create policy "documents_write" on documents
  for all using (auth_is_active() and auth_has_permission('orders.write'))
  with check (auth_is_active() and auth_has_permission('orders.write'));

create policy "notifications_own" on notifications
  for select using (profile_id = auth.uid());

create policy "notifications_own_update" on notifications
  for update using (profile_id = auth.uid()) with check (profile_id = auth.uid());

create policy "notification_preferences_own" on notification_preferences
  for all using (profile_id = auth.uid()) with check (profile_id = auth.uid());

-- Audit log is append-only and director-readable only — no update/delete
-- policy at all (see SECURITY_PLAN.md "reversal-not-delete").
create policy "audit_logs_select_director" on audit_logs
  for select using (auth_is_director());

create policy "audit_logs_insert" on audit_logs
  for insert with check (auth_is_active());

create policy "activity_feed_read_all_active" on activity_feed
  for select using (auth_is_active());

create policy "activity_feed_insert" on activity_feed
  for insert with check (auth_is_active());

create policy "comments_read_all_active" on comments
  for select using (auth_is_active());

create policy "comments_insert" on comments
  for insert with check (auth_is_active());

create policy "mentions_read_all_active" on mentions
  for select using (auth_is_active());

create policy "mentions_insert" on mentions
  for insert with check (auth_is_active());

create policy "app_settings_read_all_active" on app_settings
  for select using (auth_is_active());

create policy "app_settings_write_director" on app_settings
  for all using (auth_is_director()) with check (auth_is_director());

create policy "localization_terms_read_all_active" on localization_terms
  for select using (auth_is_active());

create policy "localization_terms_write_director" on localization_terms
  for all using (auth_is_director()) with check (auth_is_director());
