-- Tasks — new domain, not present at all in the legacy web app (see
-- DATABASE_SCHEMA.md "Tasks").

create table tasks (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  order_id uuid references orders (id),
  assigned_to uuid references profiles (id),
  priority task_priority not null default 'normal',
  deadline timestamptz,
  status task_status not null default 'todo',
  created_by uuid references profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index tasks_assigned_to_idx on tasks (assigned_to);
create index tasks_order_id_idx on tasks (order_id);
create index tasks_status_idx on tasks (status);

create trigger tasks_set_updated_at
  before update on tasks
  for each row execute function set_updated_at();

create table task_comments (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references tasks (id) on delete cascade,
  author_id uuid references profiles (id),
  body text not null,
  created_at timestamptz not null default now()
);

create table task_checklists (
  id uuid primary key default gen_random_uuid(),
  task_id uuid not null references tasks (id) on delete cascade,
  label text not null,
  checked boolean not null default false
);

create index task_comments_task_id_idx on task_comments (task_id);
create index task_checklists_task_id_idx on task_checklists (task_id);
