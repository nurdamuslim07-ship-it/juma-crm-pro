-- Flutter's order insert omits company_id. Derive the default from the
-- authenticated profile, retaining all existing RLS and FK checks.
begin;
alter table public.orders alter column company_id set default public.auth_company_id();
commit;
