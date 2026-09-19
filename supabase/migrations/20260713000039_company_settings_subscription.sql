-- Stage 3: Company Settings & Subscription Management.
--
-- Extends the existing `companies`/`subscription_plans`/
-- `company_subscriptions` tables (all from 20260713000023/000036) —
-- no new tables, only the columns this stage's screens actually need,
-- plus the RPCs that read/write them. Follows the same rule as every
-- prior stage: `company_id` is never a client-supplied parameter,
-- every RPC derives it from `auth_company_id()`.

-- ---------- companies: settings fields the requirement asks for ----------
-- name/logo/phone/email/address/iin_bin already exist (20260713000023).
-- website/timezone/currency/working_hours/description/trial_ends_at
-- are new. `trial_ends_at` lets the Subscription screen show trial
-- status without inventing a separate table — a company is "on trial"
-- exactly when this is set and still in the future.
alter table companies
  add column website text,
  add column timezone text not null default 'Asia/Almaty',
  add column currency text not null default 'KZT',
  add column working_hours text,
  add column description text,
  add column trial_ends_at timestamptz;

-- ---------- subscription_plans: plan-card fields ----------
alter table subscription_plans
  add column max_storage_mb int,
  add column features jsonb not null default '{}'::jsonb;

-- `enterprise` is custom-priced ("contact sales") — null, not 0 (0 is
-- what `free` genuinely means), so ordering/rendering can tell the two
-- apart. Relaxing this now rather than a sentinel-number hack.
alter table subscription_plans alter column price_tiyn drop not null;

-- Additive plan catalog rows — 'free' already exists (20260713000037).
-- Prices are placeholders (no real payment integration yet, per
-- supabase/README.md's "Company registration" section) but stored in
-- the same integer-tiyn convention as every other money column.
insert into subscription_plans (key, name_kk, name_ru, max_employees, max_storage_mb, price_tiyn, features)
values
  ('start', 'Старт', 'Старт', 10, 1024, 990000,
    '{"analytics": false, "warehouse": true, "production": true, "purchases": false}'::jsonb),
  ('pro', 'Про', 'Про', 30, 5120, 2990000,
    '{"analytics": true, "warehouse": true, "production": true, "purchases": true}'::jsonb),
  ('business', 'Бизнес', 'Бизнес', 100, 20480, 7990000,
    '{"analytics": true, "warehouse": true, "production": true, "purchases": true, "api": true}'::jsonb),
  ('enterprise', 'Кәсіпорын', 'Корпоративный', null, null, null,
    '{"analytics": true, "warehouse": true, "production": true, "purchases": true, "api": true, "dedicated_support": true}'::jsonb)
on conflict (key) do nothing;

-- ---------- RPCs ----------

-- Director/owner-only settings edit. Deliberately does NOT accept
-- subscription_plan/subscription_status/subscription_expires_at/
-- is_active/code — those are plan/lifecycle fields, not "settings",
-- and stay changeable only via a future billing RPC or director
-- support action, same separation of concerns as
-- restrict_profile_self_update() keeping company_id/status out of
-- reach of a plain profile edit.
create function update_company_settings(
  p_name text,
  p_logo text default null,
  p_phone text default null,
  p_email text default null,
  p_address text default null,
  p_iin_bin text default null,
  p_website text default null,
  p_timezone text default null,
  p_currency text default null,
  p_working_hours text default null,
  p_description text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not auth_is_director() then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;
  if p_name is null or length(trim(p_name)) = 0 then
    raise exception 'Компания атауы міндетті' using errcode = '23514';
  end if;

  update companies set
    name = p_name,
    logo = p_logo,
    phone = p_phone,
    email = p_email,
    address = p_address,
    iin_bin = p_iin_bin,
    website = p_website,
    timezone = coalesce(p_timezone, timezone),
    currency = coalesce(p_currency, currency),
    working_hours = p_working_hours,
    description = p_description
  where id = auth_company_id();

  if not found then
    raise exception 'Компания табылмады' using errcode = 'P0002';
  end if;
end;
$$;

-- Any active member can read their own company's subscription
-- picture (informational, not financial-profit data — see
-- CLAUDE.md's "Director-only financial data" rule, which is about
-- profit/cash flow, not plan limits). Scoped to auth_company_id() the
-- same way every other RPC in this schema is.
create or replace function get_company_subscription_info()
returns table (
  plan_key text,
  plan_name_kk text,
  plan_name_ru text,
  max_employees int,
  max_storage_mb int,
  price_tiyn bigint,
  subscription_status text,
  started_at timestamptz,
  expires_at timestamptz,
  remaining_days int,
  is_trial boolean,
  trial_ends_at timestamptz,
  company_is_active boolean,
  active_users bigint
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_company_id uuid := auth_company_id();
begin
  if not auth_is_active() then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  return query
    select
      sp.key, sp.name_kk, sp.name_ru, sp.max_employees, sp.max_storage_mb, sp.price_tiyn,
      cs.status,
      cs.started_at,
      coalesce(cs.expires_at, c.subscription_expires_at),
      case
        when coalesce(cs.expires_at, c.subscription_expires_at) is null then null
        else greatest(
          0,
          (coalesce(cs.expires_at, c.subscription_expires_at)::date - now()::date)
        )
      end,
      c.trial_ends_at is not null and c.trial_ends_at > now(),
      c.trial_ends_at,
      c.is_active,
      (select count(*) from profiles p where p.company_id = v_company_id and p.status = 'active')
    from companies c
    left join lateral (
      select * from company_subscriptions
      where company_id = v_company_id
      order by created_at desc
      limit 1
    ) cs on true
    left join subscription_plans sp on sp.key = coalesce(cs.plan_key, c.subscription_plan)
    where c.id = v_company_id;
end;
$$;

-- Global catalog read — already covered by subscription_plans_read_all
-- (20260713000037), no new policy needed; this RPC just gives the
-- Flutter side a stable, ordered call site instead of a raw
-- `.from('subscription_plans')` select.
create or replace function get_subscription_plans()
returns table (
  key text,
  name_kk text,
  name_ru text,
  max_employees int,
  max_storage_mb int,
  price_tiyn bigint,
  features jsonb
)
language sql
stable
security definer
set search_path = public
as $$
  select key, name_kk, name_ru, max_employees, max_storage_mb, price_tiyn, features
  from subscription_plans
  where is_active
  order by price_tiyn asc nulls last;
$$;
