-- Identity & RBAC — see DATABASE_SCHEMA.md "Identity & RBAC" and
-- ROLES_AND_PERMISSIONS.md. Supersedes the legacy web app's AppUser
-- (which stored a plaintext password, see SECURITY_PLAN.md finding #3)
-- — auth itself lives entirely in Supabase Auth (auth.users); this
-- schema only stores profile/role data, never a password.

create table profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  full_name text not null,
  phone text,
  avatar_url text,
  is_active boolean not null default true,
  telegram_user_id bigint unique, -- see TELEGRAM_MINI_APP_PLAN.md identity mapping
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table roles (
  id uuid primary key default gen_random_uuid(),
  key role_key not null unique,
  name_kk text not null,
  name_ru text
);

create table permissions (
  id uuid primary key default gen_random_uuid(),
  key text not null unique, -- e.g. 'orders.read', 'finance.read_profit'
  description text
);

create table role_permissions (
  role_id uuid not null references roles (id) on delete cascade,
  permission_id uuid not null references permissions (id) on delete cascade,
  primary key (role_id, permission_id)
);

create table user_roles (
  profile_id uuid not null references profiles (id) on delete cascade,
  role_id uuid not null references roles (id) on delete cascade,
  assigned_at timestamptz not null default now(),
  assigned_by uuid references profiles (id),
  primary key (profile_id, role_id)
);

create index user_roles_profile_id_idx on user_roles (profile_id);
create index role_permissions_role_id_idx on role_permissions (role_id);

-- Auto-create a profile row whenever a new Supabase Auth user is
-- created (director-initiated via the admin API — see
-- ROLES_AND_PERMISSIONS.md "Director capabilities": there is no
-- public self-registration, unlike the legacy web app's open
-- handleCustomRegister flow, which is exactly what SECURITY_PLAN.md
-- flags as a gap).
create function handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, phone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    new.raw_user_meta_data ->> 'phone'
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_auth_user();

create function set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_set_updated_at
  before update on profiles
  for each row execute function set_updated_at();
