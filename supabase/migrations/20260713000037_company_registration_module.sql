-- Company registration, join & approval flow.
--
-- Closes the last missing piece of the multi-tenant conversion: until
-- now nothing could ever insert a row into `companies` (it has had
-- only `companies_select_own` since 20260713000023) or move a
-- profile's `company_id`/`status` out of the initial
-- `null`/`'pending'` state `handle_new_auth_user()` leaves it in. This
-- migration adds that whole funnel: a signed-up user creates a new
-- company (becoming its `owner`, immediately active) or requests to
-- join an existing one by its lookup `code` (pending until a director
-- of THAT company approves/rejects), plus a pre-authorized
-- invite-code shortcut that activates membership immediately. Every
-- RPC below follows the established `42501`/`23514`/`P0002`
-- convention (permission denied / invalid input / not-found-or-
-- cross-tenant, the last one deliberately indistinguishable from a
-- row that never existed) and every place that legitimately needs to
-- move `profiles.company_id`/`status` sets the transaction-local
-- `app.bypass_profile_guard` flag from 20260713000036 immediately
-- before doing so — that migration made those two columns otherwise
-- unwritable outside these RPCs, closing the raw-PATCH hole that
-- would otherwise let a client bypass all of this by editing its own
-- `profiles` row directly.
--
-- Subscription scaffolding: `subscription_plans` is a global catalog
-- (mirrors the `roles`/`permissions` global-taxonomy pattern);
-- `company_subscriptions` is the actual per-company historical
-- record. `companies.subscription_plan/subscription_status/
-- subscription_expires_at` remain a denormalized "current" cache,
-- mirrored here whenever a `company_subscriptions` row is inserted —
-- not replaced by it.

-- ---------- companies.code ----------
create function generate_company_code()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text;
begin
  loop
    v_code := upper(substr(md5(random()::text || clock_timestamp()::text), 1, 7));
    exit when not exists (select 1 from companies where code = v_code);
  end loop;
  return v_code;
end;
$$;

alter table companies add column code text;
update companies set code = generate_company_code() where code is null;
alter table companies alter column code set not null;
alter table companies add constraint companies_code_key unique (code);

-- ---------- company_join_requests ----------
create table company_join_requests (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references profiles (id) on delete cascade,
  company_id uuid not null references companies (id),
  requested_role role_key not null,
  message text,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected', 'withdrawn')),
  reviewed_by uuid references profiles (id),
  reviewed_at timestamptz,
  rejection_reason text,
  created_at timestamptz not null default now()
);

-- Defense-in-depth backstop only — the real single-pending-request
-- guard is each RPC's own precondition on the caller's
-- profiles.company_id/status.
create unique index company_join_requests_one_pending_idx
  on company_join_requests (profile_id) where status = 'pending';

create index company_join_requests_company_idx on company_join_requests (company_id, status);

alter table company_join_requests enable row level security;

-- Defense-in-depth only (see employees_module's header comment for
-- the same pattern) — the real gate is the REVOKE below. A requester
-- sees only their own requests; a director sees only their own
-- company's, and only while genuinely active (mirrors the
-- auth_is_active() gap called out for pre-existing director-only
-- policies — this table's RPCs check it explicitly too).
create policy "company_join_requests_select_own_or_director" on company_join_requests
  for select using (
    profile_id = auth.uid()
    or (auth_is_active() and auth_is_director() and company_id = auth_company_id())
  );

revoke all on company_join_requests from authenticated, anon;

-- ---------- company_invitations ----------
create table company_invitations (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references companies (id),
  code text not null unique,
  role_key role_key not null,
  created_by uuid not null references profiles (id),
  max_uses int not null default 1 check (max_uses > 0),
  uses_count int not null default 0 check (uses_count >= 0),
  expires_at timestamptz not null default (now() + interval '7 days'),
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);

create index company_invitations_company_idx on company_invitations (company_id);

alter table company_invitations enable row level security;

create policy "company_invitations_select_director" on company_invitations
  for select using (auth_is_active() and auth_is_director() and company_id = auth_company_id());

revoke all on company_invitations from authenticated, anon;

-- ---------- subscription_plans (global catalog) ----------
create table subscription_plans (
  key text primary key,
  name_kk text not null,
  name_ru text,
  max_employees int,
  price_tiyn bigint not null default 0,
  is_active boolean not null default true
);

insert into subscription_plans (key, name_kk, name_ru, max_employees, price_tiyn) values
  ('free', 'Тегін', 'Бесплатный', 5, 0);

alter table subscription_plans enable row level security;

-- Public catalog data (like a pricing page) — visible even to a
-- pending, not-yet-active user browsing plans during onboarding.
create policy "subscription_plans_read_all" on subscription_plans
  for select using (true);

-- ---------- company_subscriptions (per-company history) ----------
create table company_subscriptions (
  id uuid primary key default gen_random_uuid(),
  company_id uuid not null references companies (id),
  plan_key text not null references subscription_plans (key),
  status text not null default 'active'
    check (status in ('active', 'expired', 'cancelled')),
  started_at timestamptz not null default now(),
  expires_at timestamptz,
  created_by uuid references profiles (id),
  created_at timestamptz not null default now()
);

create index company_subscriptions_company_idx on company_subscriptions (company_id, created_at desc);

alter table company_subscriptions enable row level security;

create policy "company_subscriptions_select_own_company" on company_subscriptions
  for select using (auth_is_active() and company_id = auth_company_id());

-- ==================== RPCs ====================

create function create_company_and_owner(
  p_name text,
  p_phone text default null,
  p_email text default null,
  p_city text default null,
  p_address text default null,
  p_iin_bin text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_company_id uuid;
  v_code text;
  v_owner_role_id uuid;
  v_current_company_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Аутентификация қажет' using errcode = '42501';
  end if;
  if p_name is null or length(trim(p_name)) = 0 then
    raise exception 'Компания атауы міндетті' using errcode = '23514';
  end if;

  select company_id into v_current_company_id from profiles where id = auth.uid();
  if v_current_company_id is not null then
    raise exception 'Сіз бұрын компанияға тіркелгенсіз' using errcode = '23514';
  end if;

  v_code := generate_company_code();

  insert into companies (name, code, phone, email, city, address, iin_bin, subscription_plan, subscription_status)
  values (p_name, v_code, p_phone, p_email, p_city, p_address, p_iin_bin, 'free', 'active')
  returning id into v_company_id;

  insert into company_subscriptions (company_id, plan_key, status, created_by)
  values (v_company_id, 'free', 'active', auth.uid());

  perform set_config('app.bypass_profile_guard', 'on', true);
  update profiles set company_id = v_company_id, status = 'active' where id = auth.uid();

  select id into v_owner_role_id from roles where key = 'owner';
  delete from user_roles where profile_id = auth.uid();
  insert into user_roles (profile_id, role_id, assigned_by)
  values (auth.uid(), v_owner_role_id, auth.uid());

  insert into audit_logs (company_id, actor_id, action, entity_type, entity_id, after)
  values (
    v_company_id, auth.uid(), 'company_created', 'companies', v_company_id,
    jsonb_build_object('name', p_name, 'code', v_code)
  );

  return v_company_id;
end;
$$;

create function request_to_join_company(
  p_company_code text,
  p_requested_role role_key,
  p_message text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_target_company_id uuid;
  v_current_company_id uuid;
  v_current_status profile_status;
  v_recent_count int;
  v_request_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Аутентификация қажет' using errcode = '42501';
  end if;

  select company_id, status into v_current_company_id, v_current_status
  from profiles where id = auth.uid();

  if not (v_current_company_id is null or v_current_status = 'rejected') then
    raise exception 'Сіз бұрын компанияға тіркелгенсіз немесе сұраныс күтуде' using errcode = '23514';
  end if;

  select count(*) into v_recent_count from company_join_requests
  where profile_id = auth.uid() and created_at > now() - interval '1 hour';
  if v_recent_count >= 3 then
    raise exception 'Тым көп сұраныс жіберілді, кейінірек қайталаңыз' using errcode = '23514';
  end if;

  select id into v_target_company_id from companies where code = p_company_code;
  if v_target_company_id is null then
    raise exception 'Компания табылмады' using errcode = 'P0002';
  end if;

  insert into company_join_requests (profile_id, company_id, requested_role, message, status)
  values (auth.uid(), v_target_company_id, p_requested_role, p_message, 'pending')
  returning id into v_request_id;

  perform set_config('app.bypass_profile_guard', 'on', true);
  update profiles set company_id = v_target_company_id, status = 'pending' where id = auth.uid();

  return v_request_id;
end;
$$;

create function withdraw_company_join_request(p_request_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_request company_join_requests;
begin
  if auth.uid() is null then
    raise exception 'Аутентификация қажет' using errcode = '42501';
  end if;

  select * into v_request from company_join_requests
  where id = p_request_id and profile_id = auth.uid();
  if not found then
    raise exception 'Сұраныс табылмады' using errcode = 'P0002';
  end if;
  if v_request.status <> 'pending' then
    raise exception 'Сұранысты қайтарып алу мүмкін емес' using errcode = '23514';
  end if;

  update company_join_requests set status = 'withdrawn' where id = p_request_id;

  perform set_config('app.bypass_profile_guard', 'on', true);
  update profiles set company_id = null, status = 'pending' where id = auth.uid();
end;
$$;

create function get_my_join_requests()
returns table (
  id uuid,
  company_id uuid,
  company_name text,
  requested_role role_key,
  message text,
  status text,
  rejection_reason text,
  created_at timestamptz,
  reviewed_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select r.id, r.company_id, c.name, r.requested_role, r.message, r.status, r.rejection_reason,
    r.created_at, r.reviewed_at
  from company_join_requests r
  join companies c on c.id = r.company_id
  where r.profile_id = auth.uid()
  order by r.created_at desc;
$$;

create function get_pending_company_requests()
returns table (
  id uuid,
  profile_id uuid,
  full_name text,
  phone text,
  requested_role role_key,
  message text,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
begin
  if not (auth_is_active() and auth_is_director()) then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  return query
    select r.id, r.profile_id, p.full_name, p.phone, r.requested_role, r.message, r.created_at
    from company_join_requests r
    join profiles p on p.id = r.profile_id
    where r.company_id = auth_company_id() and r.status = 'pending'
    order by r.created_at;
end;
$$;

create function approve_company_join_request(
  p_request_id uuid,
  p_override_role_key role_key default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_request company_join_requests;
  v_final_role role_key;
  v_role_id uuid;
begin
  if not (auth_is_active() and auth_is_director()) then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  select * into v_request from company_join_requests
  where id = p_request_id and company_id = auth_company_id();
  if not found then
    raise exception 'Сұраныс табылмады' using errcode = 'P0002';
  end if;
  if v_request.status <> 'pending' then
    raise exception 'Сұраныс бұрын қаралған' using errcode = '23514';
  end if;

  v_final_role := coalesce(p_override_role_key, v_request.requested_role);

  update company_join_requests
  set status = 'approved', reviewed_by = auth.uid(), reviewed_at = now()
  where id = p_request_id;

  perform set_config('app.bypass_profile_guard', 'on', true);
  update profiles set status = 'active' where id = v_request.profile_id;

  select id into v_role_id from roles where key = v_final_role;
  delete from user_roles where profile_id = v_request.profile_id;
  insert into user_roles (profile_id, role_id, assigned_by)
  values (v_request.profile_id, v_role_id, auth.uid());

  insert into audit_logs (company_id, actor_id, action, entity_type, entity_id, after)
  values (
    auth_company_id(), auth.uid(), 'join_request_approved', 'company_join_requests', p_request_id,
    jsonb_build_object('profile_id', v_request.profile_id, 'role', v_final_role)
  );
end;
$$;

create function reject_company_join_request(
  p_request_id uuid,
  p_reason text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_request company_join_requests;
begin
  if not (auth_is_active() and auth_is_director()) then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  select * into v_request from company_join_requests
  where id = p_request_id and company_id = auth_company_id();
  if not found then
    raise exception 'Сұраныс табылмады' using errcode = 'P0002';
  end if;
  if v_request.status <> 'pending' then
    raise exception 'Сұраныс бұрын қаралған' using errcode = '23514';
  end if;

  update company_join_requests
  set status = 'rejected', reviewed_by = auth.uid(), reviewed_at = now(), rejection_reason = p_reason
  where id = p_request_id;

  perform set_config('app.bypass_profile_guard', 'on', true);
  update profiles set status = 'rejected' where id = v_request.profile_id;

  insert into audit_logs (company_id, actor_id, action, entity_type, entity_id, after)
  values (
    auth_company_id(), auth.uid(), 'join_request_rejected', 'company_join_requests', p_request_id,
    jsonb_build_object('profile_id', v_request.profile_id, 'reason', p_reason)
  );
end;
$$;

create function create_company_invitation(
  p_role_key role_key,
  p_max_uses int default 1,
  p_expires_in_hours int default 168
)
returns table (code text, expires_at timestamptz)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_code text;
  v_expires_at timestamptz;
begin
  if not (auth_is_active() and auth_is_director()) then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;
  if p_max_uses <= 0 then
    raise exception 'max_uses оң сан болуы керек' using errcode = '23514';
  end if;

  loop
    v_code := upper(substr(md5(random()::text || clock_timestamp()::text), 1, 8));
    exit when not exists (select 1 from company_invitations where code = v_code);
  end loop;

  v_expires_at := now() + (p_expires_in_hours || ' hours')::interval;

  insert into company_invitations (company_id, code, role_key, created_by, max_uses, expires_at)
  values (auth_company_id(), v_code, p_role_key, auth.uid(), p_max_uses, v_expires_at);

  return query select v_code, v_expires_at;
end;
$$;

create function accept_company_invitation(
  p_code text,
  p_message text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_invitation company_invitations;
  v_current_company_id uuid;
  v_current_status profile_status;
  v_role_id uuid;
  v_request_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Аутентификация қажет' using errcode = '42501';
  end if;

  select company_id, status into v_current_company_id, v_current_status
  from profiles where id = auth.uid();
  if not (v_current_company_id is null or v_current_status = 'rejected') then
    raise exception 'Сіз бұрын компанияға тіркелгенсіз немесе сұраныс күтуде' using errcode = '23514';
  end if;

  select * into v_invitation from company_invitations where code = p_code;
  if not found then
    raise exception 'Шақыру коды табылмады' using errcode = 'P0002';
  end if;
  if v_invitation.revoked_at is not null
    or v_invitation.expires_at < now()
    or v_invitation.uses_count >= v_invitation.max_uses then
    raise exception 'Шақыру коды жарамсыз немесе мерзімі өткен' using errcode = 'P0002';
  end if;

  perform set_config('app.bypass_profile_guard', 'on', true);
  update profiles set company_id = v_invitation.company_id, status = 'active' where id = auth.uid();

  select id into v_role_id from roles where key = v_invitation.role_key;
  delete from user_roles where profile_id = auth.uid();
  insert into user_roles (profile_id, role_id, assigned_by)
  values (auth.uid(), v_role_id, v_invitation.created_by);

  update company_invitations set uses_count = uses_count + 1 where id = v_invitation.id;

  insert into company_join_requests (
    profile_id, company_id, requested_role, message, status, reviewed_by, reviewed_at
  )
  values (
    auth.uid(), v_invitation.company_id, v_invitation.role_key, p_message, 'approved',
    v_invitation.created_by, now()
  )
  returning id into v_request_id;

  insert into audit_logs (company_id, actor_id, action, entity_type, entity_id, after)
  values (
    v_invitation.company_id, auth.uid(), 'invitation_accepted', 'company_invitations', v_invitation.id,
    jsonb_build_object('profile_id', auth.uid(), 'role', v_invitation.role_key)
  );

  return v_invitation.company_id;
end;
$$;
