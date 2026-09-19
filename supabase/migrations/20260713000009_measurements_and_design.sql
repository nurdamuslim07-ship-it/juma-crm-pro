-- Measurements & design — see DATABASE_SCHEMA.md. Supersedes the
-- legacy web app's single-item Measurement (one set of dimensions, no
-- photos) with multi-item/multi-photo support, and adds the Design
-- domain (not present at all in the audited app).

create table measurements (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references clients (id),
  order_id uuid references orders (id),
  address text,
  scheduled_at timestamptz,
  status measurement_status not null default 'pending',
  width numeric,
  depth numeric,
  height numeric,
  room_type text,
  obstacles text[] not null default '{}',
  angle_90 boolean,
  notes text,
  measured_by uuid references profiles (id),
  created_at timestamptz not null default now()
);

create index measurements_client_id_idx on measurements (client_id);
create index measurements_order_id_idx on measurements (order_id);

create table measurement_items (
  id uuid primary key default gen_random_uuid(),
  measurement_id uuid not null references measurements (id) on delete cascade,
  label text not null,
  width numeric,
  depth numeric,
  height numeric
);

create table measurement_photos (
  id uuid primary key default gen_random_uuid(),
  measurement_id uuid not null references measurements (id) on delete cascade,
  storage_path text not null,
  uploaded_at timestamptz not null default now()
);

create table designs (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders (id) on delete cascade,
  file_url text not null,
  version int not null default 1,
  created_by uuid references profiles (id),
  created_at timestamptz not null default now()
);

create table design_approvals (
  id uuid primary key default gen_random_uuid(),
  design_id uuid not null references designs (id) on delete cascade,
  client_approved boolean,
  approved_at timestamptz,
  approval_note text
);

create index designs_order_id_idx on designs (order_id);
