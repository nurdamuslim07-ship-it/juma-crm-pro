-- Orders domain — see DATABASE_SCHEMA.md "Orders domain" and
-- ORDER_WORKFLOW.md. Critical design rule carried over from both docs:
-- production progress (order_production_progress) and payment progress
-- (derived from the `payments` ledger in the finance migration) are
-- SEPARATE, independently queryable concepts — never a single blended
-- percentage column on `orders` itself. See CLAUDE.md's explicit rule.

create table orders (
  id uuid primary key default gen_random_uuid(),
  order_number text not null unique,
  client_id uuid not null references clients (id),
  product_type text not null,
  material text,
  dimensions text,
  description text,
  address text,
  status order_status not null default 'measurement',
  -- Single "who owns this order" pointer used by the Orders module UI
  -- (simple picker over `profiles`). Distinct from the richer
  -- multi-role `order_assignments` table below, which stays available
  -- for finer-grained per-stage assignment (measurer/designer/
  -- installer, etc.) once that UI exists — the two are not mutually
  -- exclusive.
  responsible_employee_id uuid references profiles (id),
  priority task_priority not null default 'normal',
  tags text[] not null default '{}',
  contract_date date,
  measurement_date date,
  planned_start_date date,
  planned_completion_date date,
  delivery_date date,
  installation_date date,
  total_amount_tiyn bigint not null default 0 check (total_amount_tiyn >= 0),
  discount_amount_tiyn bigint not null default 0 check (discount_amount_tiyn >= 0),
  delay_reason text,
  created_by uuid references profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index orders_client_id_idx on orders (client_id);
create index orders_responsible_employee_id_idx on orders (responsible_employee_id);
create index orders_status_idx on orders (status);
create index orders_order_number_idx on orders (order_number);

create trigger orders_set_updated_at
  before update on orders
  for each row execute function set_updated_at();

create table order_assignments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders (id) on delete cascade,
  profile_id uuid not null references profiles (id),
  role order_assignment_role not null,
  assigned_at timestamptz not null default now(),
  unique (order_id, profile_id, role)
);

create index order_assignments_order_id_idx on order_assignments (order_id);
create index order_assignments_profile_id_idx on order_assignments (profile_id);

-- Full status-change audit trail — the legacy web app just overwrote
-- Order.status in place with no history at all (REQUIREMENTS.md gap).
create table order_status_history (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders (id) on delete cascade,
  previous_status order_status,
  new_status order_status not null,
  changed_by uuid references profiles (id),
  changed_at timestamptz not null default now(),
  comment text,
  photo_url text,
  source text not null default 'web' check (source in ('web', 'mobile', 'telegram')),
  was_offline boolean not null default false,
  sync_result text
);

create index order_status_history_order_id_idx on order_status_history (order_id);

-- Configurable production stage list — NOT a hardcoded enum, per the
-- master spec's "status percentages should be configurable"
-- requirement and QUESTIONS_FOR_OWNER.md #8 (exact stages pending
-- owner confirmation; seeded with a reasonable starting list).
create table production_stages (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  name_kk text not null,
  name_ru text,
  sort_order int not null,
  default_percent smallint not null check (default_percent between 0 and 100)
);

-- The field that closes the critical gap identified in
-- REQUIREMENTS.md / ORDER_WORKFLOW.md: production completion is
-- tracked completely independently of payment completion.
create table order_production_progress (
  order_id uuid primary key references orders (id) on delete cascade,
  current_stage_id uuid references production_stages (id),
  percent_complete smallint not null default 0 check (percent_complete between 0 and 100),
  updated_by uuid references profiles (id),
  updated_at timestamptz not null default now()
);

create table order_files (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders (id) on delete cascade,
  storage_path text not null,
  kind text not null check (kind in ('measurement', 'design', 'contract', 'production', 'delivery', 'installation', 'other')),
  uploaded_by uuid references profiles (id),
  uploaded_at timestamptz not null default now()
);

create table order_photos (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders (id) on delete cascade,
  storage_path text not null,
  kind text not null check (kind in ('measurement', 'production', 'delivery', 'installation', 'warranty', 'other')),
  uploaded_by uuid references profiles (id),
  uploaded_at timestamptz not null default now()
);

create index order_files_order_id_idx on order_files (order_id);
create index order_photos_order_id_idx on order_photos (order_id);
