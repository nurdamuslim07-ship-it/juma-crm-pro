-- Multi-tenant SaaS conversion — Stage 1b: company_id on every
-- business table.
--
-- Global/shared tables deliberately excluded (per the plan's "global
-- vs per-company lookup tables" decision): `roles`, `permissions`,
-- `role_permissions` (shared RBAC taxonomy), `app_settings`,
-- `localization_terms` (app-wide config/i18n), `order_status_role_permissions`
-- (workflow rule, not business data), `user_roles` (already unambiguous
-- once `profiles.company_id` exists — a role assignment belongs to
-- whichever single company its profile belongs to). `payment_methods`,
-- `expense_categories`, `material_categories`, `production_stages` DO
-- get `company_id` — different furniture factories should be able to
-- run their own payment methods/expense categories/material
-- categories/shop-floor stages once companies can customize them.
--
-- Every table follows the same three steps: add the column nullable,
-- backfill every existing row to the one "Default" company created in
-- 20260713000023, then enforce `not null`. `purchase_requests` and the
-- original (2007-file) `purchase_orders` are skipped — both are
-- superseded/dropped by 20260713000022_purchases_module.sql and no
-- longer exist.

do $$
declare
  v_default_company_id uuid;
begin
  select id into v_default_company_id from companies order by created_at asc limit 1;

  -- ---------- clients ----------
  alter table clients add column company_id uuid references companies (id);
  update clients set company_id = v_default_company_id where company_id is null;
  alter table clients alter column company_id set not null;
  create index clients_company_id_idx on clients (company_id);

  alter table client_contacts add column company_id uuid references companies (id);
  update client_contacts set company_id = v_default_company_id where company_id is null;
  alter table client_contacts alter column company_id set not null;
  create index client_contacts_company_id_idx on client_contacts (company_id);

  alter table client_notes add column company_id uuid references companies (id);
  update client_notes set company_id = v_default_company_id where company_id is null;
  alter table client_notes alter column company_id set not null;
  create index client_notes_company_id_idx on client_notes (company_id);

  alter table client_files add column company_id uuid references companies (id);
  update client_files set company_id = v_default_company_id where company_id is null;
  alter table client_files alter column company_id set not null;
  create index client_files_company_id_idx on client_files (company_id);

  -- ---------- orders ----------
  alter table orders add column company_id uuid references companies (id);
  update orders set company_id = v_default_company_id where company_id is null;
  alter table orders alter column company_id set not null;
  create index orders_company_id_idx on orders (company_id);
  -- order_number was globally unique — two different companies must
  -- each be free to run their own "PO-0001"-style numbering.
  alter table orders drop constraint orders_order_number_key;
  alter table orders add constraint orders_company_id_order_number_key unique (company_id, order_number);

  alter table order_assignments add column company_id uuid references companies (id);
  update order_assignments set company_id = v_default_company_id where company_id is null;
  alter table order_assignments alter column company_id set not null;
  create index order_assignments_company_id_idx on order_assignments (company_id);

  alter table order_status_history add column company_id uuid references companies (id);
  update order_status_history set company_id = v_default_company_id where company_id is null;
  alter table order_status_history alter column company_id set not null;
  create index order_status_history_company_id_idx on order_status_history (company_id);

  -- Per-company customizable shop-floor stages (see header comment).
  alter table production_stages add column company_id uuid references companies (id);
  update production_stages set company_id = v_default_company_id where company_id is null;
  alter table production_stages alter column company_id set not null;
  create index production_stages_company_id_idx on production_stages (company_id);
  -- `key` was globally unique (one shared stage list) — now that each
  -- company can customize its own stages, uniqueness must be scoped
  -- per company instead, or two companies could never both have a
  -- stage keyed e.g. 'cutting'.
  alter table production_stages drop constraint production_stages_key_key;
  alter table production_stages add constraint production_stages_company_id_key_key unique (company_id, key);

  alter table order_production_progress add column company_id uuid references companies (id);
  update order_production_progress set company_id = v_default_company_id where company_id is null;
  alter table order_production_progress alter column company_id set not null;
  create index order_production_progress_company_id_idx on order_production_progress (company_id);

  alter table order_files add column company_id uuid references companies (id);
  update order_files set company_id = v_default_company_id where company_id is null;
  alter table order_files alter column company_id set not null;
  create index order_files_company_id_idx on order_files (company_id);

  alter table order_photos add column company_id uuid references companies (id);
  update order_photos set company_id = v_default_company_id where company_id is null;
  alter table order_photos alter column company_id set not null;
  create index order_photos_company_id_idx on order_photos (company_id);

  -- ---------- measurements & design ----------
  alter table measurements add column company_id uuid references companies (id);
  update measurements set company_id = v_default_company_id where company_id is null;
  alter table measurements alter column company_id set not null;
  create index measurements_company_id_idx on measurements (company_id);

  alter table measurement_items add column company_id uuid references companies (id);
  update measurement_items set company_id = v_default_company_id where company_id is null;
  alter table measurement_items alter column company_id set not null;
  create index measurement_items_company_id_idx on measurement_items (company_id);

  alter table measurement_photos add column company_id uuid references companies (id);
  update measurement_photos set company_id = v_default_company_id where company_id is null;
  alter table measurement_photos alter column company_id set not null;
  create index measurement_photos_company_id_idx on measurement_photos (company_id);

  alter table designs add column company_id uuid references companies (id);
  update designs set company_id = v_default_company_id where company_id is null;
  alter table designs alter column company_id set not null;
  create index designs_company_id_idx on designs (company_id);

  alter table design_approvals add column company_id uuid references companies (id);
  update design_approvals set company_id = v_default_company_id where company_id is null;
  alter table design_approvals alter column company_id set not null;
  create index design_approvals_company_id_idx on design_approvals (company_id);

  -- ---------- finance ----------
  -- Per-company customizable payment methods/expense categories (see
  -- header comment).
  alter table payment_methods add column company_id uuid references companies (id);
  update payment_methods set company_id = v_default_company_id where company_id is null;
  alter table payment_methods alter column company_id set not null;
  create index payment_methods_company_id_idx on payment_methods (company_id);
  alter table payment_methods drop constraint payment_methods_key_key;
  alter table payment_methods add constraint payment_methods_company_id_key_key unique (company_id, key);

  alter table cashboxes add column company_id uuid references companies (id);
  update cashboxes set company_id = v_default_company_id where company_id is null;
  alter table cashboxes alter column company_id set not null;
  create index cashboxes_company_id_idx on cashboxes (company_id);

  alter table bank_accounts add column company_id uuid references companies (id);
  update bank_accounts set company_id = v_default_company_id where company_id is null;
  alter table bank_accounts alter column company_id set not null;
  create index bank_accounts_company_id_idx on bank_accounts (company_id);

  alter table payments add column company_id uuid references companies (id);
  update payments set company_id = v_default_company_id where company_id is null;
  alter table payments alter column company_id set not null;
  create index payments_company_id_idx on payments (company_id);

  alter table expense_categories add column company_id uuid references companies (id);
  update expense_categories set company_id = v_default_company_id where company_id is null;
  alter table expense_categories alter column company_id set not null;
  create index expense_categories_company_id_idx on expense_categories (company_id);
  alter table expense_categories drop constraint expense_categories_key_key;
  alter table expense_categories add constraint expense_categories_company_id_key_key unique (company_id, key);

  alter table suppliers add column company_id uuid references companies (id);
  update suppliers set company_id = v_default_company_id where company_id is null;
  alter table suppliers alter column company_id set not null;
  create index suppliers_company_id_idx on suppliers (company_id);

  alter table expenses add column company_id uuid references companies (id);
  update expenses set company_id = v_default_company_id where company_id is null;
  alter table expenses alter column company_id set not null;
  create index expenses_company_id_idx on expenses (company_id);

  alter table supplier_debts add column company_id uuid references companies (id);
  update supplier_debts set company_id = v_default_company_id where company_id is null;
  alter table supplier_debts alter column company_id set not null;
  create index supplier_debts_company_id_idx on supplier_debts (company_id);

  alter table idempotency_keys add column company_id uuid references companies (id);
  update idempotency_keys set company_id = v_default_company_id where company_id is null;
  alter table idempotency_keys alter column company_id set not null;
  create index idempotency_keys_company_id_idx on idempotency_keys (company_id);

  -- ---------- warehouse ----------
  -- Per-company customizable material categories (see header comment).
  alter table material_categories add column company_id uuid references companies (id);
  update material_categories set company_id = v_default_company_id where company_id is null;
  alter table material_categories alter column company_id set not null;
  create index material_categories_company_id_idx on material_categories (company_id);
  alter table material_categories drop constraint material_categories_key_key;
  alter table material_categories add constraint material_categories_company_id_key_key unique (company_id, key);

  alter table materials add column company_id uuid references companies (id);
  update materials set company_id = v_default_company_id where company_id is null;
  alter table materials alter column company_id set not null;
  create index materials_company_id_idx on materials (company_id);
  -- barcode was globally unique — a real-world barcode two different
  -- companies' distinct materials happen to share must not block one
  -- of them from ever registering it. `materials.barcode` is nullable
  -- (added `unique` in 20260713000021), so this composite unique still
  -- allows any number of NULLs per company as Postgres treats NULLs
  -- as distinct in a unique constraint.
  alter table materials drop constraint materials_barcode_key;
  alter table materials add constraint materials_company_id_barcode_key unique (company_id, barcode);

  alter table warehouses add column company_id uuid references companies (id);
  update warehouses set company_id = v_default_company_id where company_id is null;
  alter table warehouses alter column company_id set not null;
  create index warehouses_company_id_idx on warehouses (company_id);

  alter table warehouse_locations add column company_id uuid references companies (id);
  update warehouse_locations set company_id = v_default_company_id where company_id is null;
  alter table warehouse_locations alter column company_id set not null;
  create index warehouse_locations_company_id_idx on warehouse_locations (company_id);

  alter table inventory_balances add column company_id uuid references companies (id);
  update inventory_balances set company_id = v_default_company_id where company_id is null;
  alter table inventory_balances alter column company_id set not null;
  create index inventory_balances_company_id_idx on inventory_balances (company_id);

  alter table inventory_transactions add column company_id uuid references companies (id);
  update inventory_transactions set company_id = v_default_company_id where company_id is null;
  alter table inventory_transactions alter column company_id set not null;
  create index inventory_transactions_company_id_idx on inventory_transactions (company_id);

  alter table material_reservations add column company_id uuid references companies (id);
  update material_reservations set company_id = v_default_company_id where company_id is null;
  alter table material_reservations alter column company_id set not null;
  create index material_reservations_company_id_idx on material_reservations (company_id);

  -- ---------- logistics ----------
  alter table deliveries add column company_id uuid references companies (id);
  update deliveries set company_id = v_default_company_id where company_id is null;
  alter table deliveries alter column company_id set not null;
  create index deliveries_company_id_idx on deliveries (company_id);

  alter table installations add column company_id uuid references companies (id);
  update installations set company_id = v_default_company_id where company_id is null;
  alter table installations alter column company_id set not null;
  create index installations_company_id_idx on installations (company_id);

  alter table installation_checklists add column company_id uuid references companies (id);
  update installation_checklists set company_id = v_default_company_id where company_id is null;
  alter table installation_checklists alter column company_id set not null;
  create index installation_checklists_company_id_idx on installation_checklists (company_id);

  alter table warranty_requests add column company_id uuid references companies (id);
  update warranty_requests set company_id = v_default_company_id where company_id is null;
  alter table warranty_requests alter column company_id set not null;
  create index warranty_requests_company_id_idx on warranty_requests (company_id);

  alter table service_requests add column company_id uuid references companies (id);
  update service_requests set company_id = v_default_company_id where company_id is null;
  alter table service_requests alter column company_id set not null;
  create index service_requests_company_id_idx on service_requests (company_id);

  -- ---------- tasks ----------
  alter table tasks add column company_id uuid references companies (id);
  update tasks set company_id = v_default_company_id where company_id is null;
  alter table tasks alter column company_id set not null;
  create index tasks_company_id_idx on tasks (company_id);

  alter table task_comments add column company_id uuid references companies (id);
  update task_comments set company_id = v_default_company_id where company_id is null;
  alter table task_comments alter column company_id set not null;
  create index task_comments_company_id_idx on task_comments (company_id);

  alter table task_checklists add column company_id uuid references companies (id);
  update task_checklists set company_id = v_default_company_id where company_id is null;
  alter table task_checklists alter column company_id set not null;
  create index task_checklists_company_id_idx on task_checklists (company_id);

  -- ---------- system ----------
  alter table documents add column company_id uuid references companies (id);
  update documents set company_id = v_default_company_id where company_id is null;
  alter table documents alter column company_id set not null;
  create index documents_company_id_idx on documents (company_id);

  alter table notifications add column company_id uuid references companies (id);
  update notifications set company_id = v_default_company_id where company_id is null;
  alter table notifications alter column company_id set not null;
  create index notifications_company_id_idx on notifications (company_id);

  alter table notification_preferences add column company_id uuid references companies (id);
  update notification_preferences set company_id = v_default_company_id where company_id is null;
  alter table notification_preferences alter column company_id set not null;
  create index notification_preferences_company_id_idx on notification_preferences (company_id);

  alter table audit_logs add column company_id uuid references companies (id);
  update audit_logs set company_id = v_default_company_id where company_id is null;
  alter table audit_logs alter column company_id set not null;
  create index audit_logs_company_id_idx on audit_logs (company_id);

  alter table activity_feed add column company_id uuid references companies (id);
  update activity_feed set company_id = v_default_company_id where company_id is null;
  alter table activity_feed alter column company_id set not null;
  create index activity_feed_company_id_idx on activity_feed (company_id);

  alter table comments add column company_id uuid references companies (id);
  update comments set company_id = v_default_company_id where company_id is null;
  alter table comments alter column company_id set not null;
  create index comments_company_id_idx on comments (company_id);

  alter table mentions add column company_id uuid references companies (id);
  update mentions set company_id = v_default_company_id where company_id is null;
  alter table mentions alter column company_id set not null;
  create index mentions_company_id_idx on mentions (company_id);

  -- ---------- employees ----------
  alter table employees add column company_id uuid references companies (id);
  update employees set company_id = v_default_company_id where company_id is null;
  alter table employees alter column company_id set not null;
  create index employees_company_id_idx on employees (company_id);

  -- ---------- partners ----------
  alter table partners add column company_id uuid references companies (id);
  update partners set company_id = v_default_company_id where company_id is null;
  alter table partners alter column company_id set not null;
  create index partners_company_id_idx on partners (company_id);

  alter table partner_documents add column company_id uuid references companies (id);
  update partner_documents set company_id = v_default_company_id where company_id is null;
  alter table partner_documents alter column company_id set not null;
  create index partner_documents_company_id_idx on partner_documents (company_id);

  -- ---------- production (module 20) ----------
  alter table production_time_logs add column company_id uuid references companies (id);
  update production_time_logs set company_id = v_default_company_id where company_id is null;
  alter table production_time_logs alter column company_id set not null;
  create index production_time_logs_company_id_idx on production_time_logs (company_id);

  alter table production_stage_history add column company_id uuid references companies (id);
  update production_stage_history set company_id = v_default_company_id where company_id is null;
  alter table production_stage_history alter column company_id set not null;
  create index production_stage_history_company_id_idx on production_stage_history (company_id);

  -- ---------- warehouse (module 21) ----------
  alter table inventory_batches add column company_id uuid references companies (id);
  update inventory_batches set company_id = v_default_company_id where company_id is null;
  alter table inventory_batches alter column company_id set not null;
  create index inventory_batches_company_id_idx on inventory_batches (company_id);

  alter table inventory_holds add column company_id uuid references companies (id);
  update inventory_holds set company_id = v_default_company_id where company_id is null;
  alter table inventory_holds alter column company_id set not null;
  create index inventory_holds_company_id_idx on inventory_holds (company_id);

  -- ---------- purchases (module 22) ----------
  alter table purchase_orders add column company_id uuid references companies (id);
  update purchase_orders set company_id = v_default_company_id where company_id is null;
  alter table purchase_orders alter column company_id set not null;
  create index purchase_orders_company_id_idx on purchase_orders (company_id);
  -- order_number was globally unique — same reasoning as orders.order_number
  -- above: two companies must each be free to run their own numbering.
  alter table purchase_orders drop constraint purchase_orders_order_number_key;
  alter table purchase_orders add constraint purchase_orders_company_id_order_number_key
    unique (company_id, order_number);

  alter table purchase_order_items add column company_id uuid references companies (id);
  update purchase_order_items set company_id = v_default_company_id where company_id is null;
  alter table purchase_order_items alter column company_id set not null;
  create index purchase_order_items_company_id_idx on purchase_order_items (company_id);

  alter table supplier_invoices add column company_id uuid references companies (id);
  update supplier_invoices set company_id = v_default_company_id where company_id is null;
  alter table supplier_invoices alter column company_id set not null;
  create index supplier_invoices_company_id_idx on supplier_invoices (company_id);

  alter table supplier_payments add column company_id uuid references companies (id);
  update supplier_payments set company_id = v_default_company_id where company_id is null;
  alter table supplier_payments alter column company_id set not null;
  create index supplier_payments_company_id_idx on supplier_payments (company_id);
end;
$$;
