begin;
create table public.quick_estimates (
 id uuid primary key default gen_random_uuid(),
 company_id uuid not null default public.auth_company_id() references public.companies(id),
 name text not null,
 snapshot jsonb not null check(jsonb_typeof(snapshot) = 'object'),
 updated_at timestamptz not null default now()
);
create table public.estimate_price_catalog (
 id uuid primary key default gen_random_uuid(),
 company_id uuid not null default public.auth_company_id() references public.companies(id),
 item_key text not null,
 snapshot jsonb not null check(jsonb_typeof(snapshot) = 'object'),
 unique(company_id, item_key)
);
alter table public.quick_estimates enable row level security;
alter table public.estimate_price_catalog enable row level security;
create policy estimates_read on public.quick_estimates for select to authenticated using(company_id = public.auth_company_id() and public.auth_is_active() and public.auth_has_permission('orders.read'));
create policy estimates_write on public.quick_estimates for all to authenticated using(company_id = public.auth_company_id() and public.auth_is_active() and public.auth_has_permission('orders.write')) with check(company_id = public.auth_company_id() and public.auth_is_active() and public.auth_has_permission('orders.write'));
create policy catalog_read on public.estimate_price_catalog for select to authenticated using(company_id = public.auth_company_id() and public.auth_is_active() and public.auth_has_permission('orders.read'));
create policy catalog_write on public.estimate_price_catalog for all to authenticated using(company_id = public.auth_company_id() and public.auth_is_active() and public.auth_has_permission('orders.write')) with check(company_id = public.auth_company_id() and public.auth_is_active() and public.auth_has_permission('orders.write'));
grant select, insert, update, delete on public.quick_estimates, public.estimate_price_catalog to authenticated;
commit;
