-- Clients — see DATABASE_SCHEMA.md "Clients & measurements". Extends
-- the legacy web app's flat Client shape with the fields
-- REQUIREMENTS.md flagged as missing (secondary phone, source,
-- responsible manager, preferred language, structured notes/files).

create table clients (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text not null,
  phone_secondary text,
  whatsapp_or_telegram text,
  address text,
  city text,
  source text,
  responsible_manager_id uuid references profiles (id),
  preferred_language text not null default 'kk',
  notes text,
  created_by uuid references profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz -- soft delete, per SECURITY_PLAN.md going-forward rules
);

create index clients_responsible_manager_idx on clients (responsible_manager_id);
create index clients_name_idx on clients using gin (to_tsvector('simple', name));

create trigger clients_set_updated_at
  before update on clients
  for each row execute function set_updated_at();

create table client_contacts (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references clients (id) on delete cascade,
  label text not null,
  value text not null,
  created_at timestamptz not null default now()
);

create table client_notes (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references clients (id) on delete cascade,
  author_id uuid references profiles (id),
  body text not null,
  created_at timestamptz not null default now()
);

create table client_files (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references clients (id) on delete cascade,
  storage_path text not null,
  uploaded_by uuid references profiles (id),
  uploaded_at timestamptz not null default now()
);

create index client_contacts_client_id_idx on client_contacts (client_id);
create index client_notes_client_id_idx on client_notes (client_id);
create index client_files_client_id_idx on client_files (client_id);
