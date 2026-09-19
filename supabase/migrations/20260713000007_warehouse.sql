-- Warehouse — see DATABASE_SCHEMA.md "Warehouse". Supersedes the
-- legacy web app's flat InventoryItem stock-count record with
-- transactional stock tracking, reservations, and purchasing.

create table material_categories (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  name_kk text not null
);

create table materials (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  category_id uuid references material_categories (id),
  unit text not null,
  cost_per_unit_tiyn bigint not null default 0,
  min_quantity numeric not null default 0,
  created_at timestamptz not null default now()
);

create table warehouses (
  id uuid primary key default gen_random_uuid(),
  name text not null
);

create table warehouse_locations (
  id uuid primary key default gen_random_uuid(),
  warehouse_id uuid not null references warehouses (id) on delete cascade,
  name text not null
);

create table inventory_balances (
  material_id uuid not null references materials (id),
  location_id uuid not null references warehouse_locations (id),
  quantity numeric not null default 0,
  reserved_quantity numeric not null default 0,
  primary key (material_id, location_id)
);

create table inventory_transactions (
  id uuid primary key default gen_random_uuid(),
  material_id uuid not null references materials (id),
  location_id uuid not null references warehouse_locations (id),
  delta_quantity numeric not null,
  kind inventory_transaction_kind not null,
  order_id uuid references orders (id),
  performed_by uuid references profiles (id),
  created_at timestamptz not null default now()
);

create index inventory_transactions_material_id_idx on inventory_transactions (material_id);
create index inventory_transactions_order_id_idx on inventory_transactions (order_id);

create table material_reservations (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders (id) on delete cascade,
  material_id uuid not null references materials (id),
  quantity numeric not null check (quantity > 0),
  reserved_at timestamptz not null default now()
);

create table purchase_requests (
  id uuid primary key default gen_random_uuid(),
  material_id uuid not null references materials (id),
  quantity numeric not null check (quantity > 0),
  requested_by uuid references profiles (id),
  approved_by uuid references profiles (id),
  status purchase_status not null default 'requested',
  created_at timestamptz not null default now()
);

create table purchase_orders (
  id uuid primary key default gen_random_uuid(),
  purchase_request_id uuid references purchase_requests (id),
  supplier_id uuid references suppliers (id),
  material_id uuid not null references materials (id),
  quantity numeric not null check (quantity > 0),
  status purchase_status not null default 'ordered',
  ordered_at timestamptz not null default now(),
  received_at timestamptz
);
