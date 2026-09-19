-- System tables — documents, notifications, audit, settings,
-- localization, comments/mentions. See DATABASE_SCHEMA.md "System".

create table documents (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders (id),
  kind text not null check (kind in ('contract', 'offer', 'invoice', 'receipt', 'warranty', 'other')),
  file_url text not null,
  version int not null default 1,
  generated_by uuid references profiles (id),
  generated_at timestamptz not null default now()
);

create index documents_order_id_idx on documents (order_id);

create table notifications (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles (id) on delete cascade,
  kind text not null,
  body_kk text not null,
  related_order_id uuid references orders (id),
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create index notifications_profile_id_idx on notifications (profile_id);

create table notification_preferences (
  profile_id uuid not null references profiles (id) on delete cascade,
  channel text not null check (channel in ('in_app', 'telegram', 'email')),
  enabled boolean not null default true,
  primary key (profile_id, channel)
);

-- Generic audit trail beyond order_status_history/payments — covers
-- role changes, employee deactivation, settings changes. Every
-- financial/security-sensitive mutation should also write here (see
-- SECURITY_PLAN.md "Audit logging").
create table audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references profiles (id),
  action text not null,
  entity_type text not null,
  entity_id uuid,
  before jsonb,
  after jsonb,
  created_at timestamptz not null default now()
);

create index audit_logs_entity_idx on audit_logs (entity_type, entity_id);

create table activity_feed (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references profiles (id),
  entity_type text not null,
  entity_id uuid,
  summary text not null,
  created_at timestamptz not null default now()
);

create table comments (
  id uuid primary key default gen_random_uuid(),
  entity_type text not null,
  entity_id uuid not null,
  author_id uuid references profiles (id),
  body text not null,
  created_at timestamptz not null default now()
);

create table mentions (
  id uuid primary key default gen_random_uuid(),
  comment_id uuid not null references comments (id) on delete cascade,
  mentioned_profile_id uuid not null references profiles (id)
);

create index comments_entity_idx on comments (entity_type, entity_id);

-- Configurable settings instead of hardcoded values (master spec:
-- "status percentages should be configurable").
create table app_settings (
  key text primary key,
  value jsonb not null
);

-- Future extension point for a DB-editable dictionary (see
-- KAZAKH_LOCALIZATION.md's "Non-goal for Phase 1" — Phase 1 ships a
-- static compiled Dart dictionary; this table is not read by the app
-- yet, only reserved).
create table localization_terms (
  key text primary key,
  kk text not null,
  ru text
);
