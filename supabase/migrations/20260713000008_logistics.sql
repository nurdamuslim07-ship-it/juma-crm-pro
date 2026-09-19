-- Delivery & installation — see DATABASE_SCHEMA.md "Logistics". Not
-- modeled at all in the legacy web app beyond a single Order.deliveryDate
-- field (REQUIREMENTS.md gap).

create table deliveries (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders (id) on delete cascade,
  address text,
  scheduled_at timestamptz,
  driver_id uuid references profiles (id),
  vehicle text,
  status delivery_status not null default 'scheduled',
  created_at timestamptz not null default now()
);

create index deliveries_order_id_idx on deliveries (order_id);

create table installations (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders (id) on delete cascade,
  delivery_id uuid references deliveries (id),
  scheduled_at timestamptz,
  team uuid[] not null default '{}', -- profile ids
  status installation_status not null default 'scheduled',
  client_accepted_at timestamptz,
  client_signature_url text,
  created_at timestamptz not null default now()
);

create index installations_order_id_idx on installations (order_id);

create table installation_checklists (
  id uuid primary key default gen_random_uuid(),
  installation_id uuid not null references installations (id) on delete cascade,
  item text not null,
  checked boolean not null default false,
  checked_by uuid references profiles (id)
);

create table warranty_requests (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders (id),
  reported_by uuid references profiles (id),
  description text not null,
  status text not null default 'open' check (status in ('open', 'in_progress', 'resolved', 'rejected')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

create table service_requests (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders (id),
  reported_by uuid references profiles (id),
  description text not null,
  status text not null default 'open' check (status in ('open', 'in_progress', 'resolved', 'rejected')),
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

create index warranty_requests_order_id_idx on warranty_requests (order_id);
create index service_requests_order_id_idx on service_requests (order_id);
