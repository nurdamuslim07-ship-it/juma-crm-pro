-- JUMA UI Furniture CRM — extensions and shared enum types.
-- See DATABASE_SCHEMA.md for the full table-by-table design this
-- migration set implements. Money is stored as bigint minor units
-- (tiyn, 1 ₸ = 100 tiyn) everywhere — never numeric/float — per
-- DATABASE_SCHEMA.md's explicit "never floating point" rule.

create extension if not exists "pgcrypto"; -- gen_random_uuid()

create type role_key as enum (
  'director',
  'manager',
  'measurer',
  'designer',
  'workshop_manager',
  'master',
  'assistant',
  'installer',
  'accountant',
  'warehouse',
  'admin',
  -- Added for the Partners/Suppliers module — "Purchaser/закупщик" in
  -- the requirement has no established Kazakh HR title in the codebase
  -- yet; name_kk is a working translation pending native-speaker
  -- sign-off (see KAZAKH_TERMINOLOGY_REVIEW.md).
  'purchaser'
);

-- Partner/supplier category (see Partners module requirements' exact
-- category list). An enum, not a reference table, per the module spec
-- ("partner_categories enum немесе reference table") — this is a
-- fixed, small set of business relationship types, not user-editable
-- data, so it follows the same convention as order_status/payment_status
-- rather than the editable lookup tables (material_categories etc).
create type partner_category as enum (
  'gazelle_driver',  -- ГАЗЕЛИСТ
  'taxi_driver',     -- ТАКСИСТ
  'ldsp',            -- ЛДСП
  'mdf_cnc',         -- МДФ ЧПУ
  'fittings',        -- ФУРНИТУРА
  'canteen',         -- АСХАНА
  'other'            -- БАСҚА
);

-- Order status — the owner's confirmed 5-stage workflow (resolves
-- QUESTIONS_FOR_OWNER.md #8; supersedes the illustrative 26-stage
-- draft this enum originally shipped with). Kazakh labels/role gating
-- for each value live in order_status_role_permissions
-- (20260713000015_order_status_transitions.sql), not hardcoded in
-- application code, so the list stays configurable per
-- ORDER_WORKFLOW.md's "status percentages should be configurable" rule.
--
--   measurement  — Замер
--   accepted     — Қабылданды
--   in_progress  — Өңделуде
--   ready        — Тапсырыс дайын
--   installed    — Орнатылды
create type order_status as enum (
  'measurement',
  'accepted',
  'in_progress',
  'ready',
  'installed'
);

-- Order assignment roles — who is attached to an order and in what
-- capacity (see DATABASE_SCHEMA.md order_assignments, replacing the
-- single Order.employeeId field audited in the legacy web app).
create type order_assignment_role as enum (
  'manager',
  'measurer',
  'designer',
  'workshop_manager',
  'master',
  'installer'
);

create type payment_status as enum ('pending', 'confirmed', 'reversed');

create type expense_approval_status as enum ('pending', 'approved', 'rejected');

create type purchase_status as enum ('requested', 'approved', 'ordered', 'received', 'cancelled');

create type inventory_transaction_kind as enum ('receive', 'issue', 'adjust', 'waste');

create type delivery_status as enum ('scheduled', 'in_transit', 'delivered', 'failed');

create type installation_status as enum ('scheduled', 'in_progress', 'completed', 'client_accepted');

create type measurement_status as enum ('pending', 'completed', 'cancelled');

create type task_status as enum ('todo', 'in_progress', 'blocked', 'done');

create type task_priority as enum ('low', 'normal', 'high', 'urgent');
