-- Payments & finance — see DATABASE_SCHEMA.md "Payments & finance".
-- Every payment is its own insert-only row (idempotency_key enforced
-- unique) — this is what replaces the legacy web app's single running
-- Order.paidAmount number, which could not represent partial-payment
-- history, method, or who recorded it. Reversal is a new row
-- referencing the original, never an UPDATE/DELETE — see
-- SECURITY_PLAN.md and OFFLINE_PWA_PLAN.md's idempotency design.

create table payment_methods (
  id uuid primary key default gen_random_uuid(),
  key text not null unique, -- e.g. 'cash', 'bank_transfer', 'kaspi'
  name_kk text not null
);

create table cashboxes (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  opening_balance_tiyn bigint not null default 0
);

create table bank_accounts (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  iban text,
  opening_balance_tiyn bigint not null default 0
);

create table payments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references orders (id),
  client_id uuid not null references clients (id),
  amount_tiyn bigint not null check (amount_tiyn > 0),
  method_id uuid references payment_methods (id),
  cashbox_id uuid references cashboxes (id),
  bank_account_id uuid references bank_accounts (id),
  -- The date the payment was actually made (user-entered, may be
  -- backdated), distinct from created_at (when the row was inserted).
  -- See Payments module requirement #4 "Төлем күні".
  paid_at date not null default current_date,
  recorded_by uuid references profiles (id),
  confirmed_by uuid references profiles (id),
  confirmed_at timestamptz,
  status payment_status not null default 'pending',
  reversal_of uuid references payments (id),
  idempotency_key text not null unique,
  comment text,
  receipt_url text,
  created_offline_at timestamptz, -- set by client for offline-queued payments, see OFFLINE_PWA_PLAN.md
  created_at timestamptz not null default now(),
  -- Soft delete, per the Payments module's requirement #14 — same
  -- pattern as clients/orders. Deleted payments are excluded from
  -- active_payments (see 20260713000016_payments_module.sql) so a
  -- soft-deleted payment stops counting toward an order's paid total.
  deleted_at timestamptz
);

create index payments_order_id_idx on payments (order_id);
create index payments_client_id_idx on payments (client_id);

create table expense_categories (
  id uuid primary key default gen_random_uuid(),
  key text not null unique,
  name_kk text not null
);

create table suppliers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text,
  contact_person text
);

create table expenses (
  id uuid primary key default gen_random_uuid(),
  order_id uuid references orders (id), -- null = general company expense
  category_id uuid references expense_categories (id),
  amount_tiyn bigint not null check (amount_tiyn > 0),
  supplier_id uuid references suppliers (id),
  method_id uuid references payment_methods (id),
  receipt_url text,
  recorded_by uuid references profiles (id),
  approved_by uuid references profiles (id),
  approval_status expense_approval_status not null default 'pending',
  idempotency_key text not null unique,
  comment text,
  created_at timestamptz not null default now()
);

create index expenses_order_id_idx on expenses (order_id);

create table supplier_debts (
  id uuid primary key default gen_random_uuid(),
  supplier_id uuid not null references suppliers (id),
  amount_tiyn bigint not null check (amount_tiyn > 0),
  due_date date,
  settled boolean not null default false,
  created_at timestamptz not null default now()
);

-- Idempotency ledger backing OFFLINE_PWA_PLAN.md's offline mutation
-- queue — a retried sync with the same key is a no-op, not a
-- duplicate insert. Financial write RPCs (see rls_policies migration)
-- check this table before inserting into payments/expenses.
create table idempotency_keys (
  key text primary key,
  created_at timestamptz not null default now(),
  response jsonb
);
