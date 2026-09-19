begin;
-- Backfill only missing lookup entries; no financial ledger is changed.
insert into public.payment_methods(company_id,key,name_kk)
select c.id,m.key,m.name_kk from public.companies c cross join (values
 ('cash','Қолма-қол'),('kaspi','Kaspi'),('bank_transfer','Банк аударымы'),('card','Карта'),('other','Басқа')
) as m(key,name_kk) on conflict(company_id,key) do nothing;
create function public.seed_company_payment_methods() returns trigger
language plpgsql security definer set search_path=public as $$
begin
 insert into payment_methods(company_id,key,name_kk) values
 (new.id,'cash','Қолма-қол'),(new.id,'kaspi','Kaspi'),(new.id,'bank_transfer','Банк аударымы'),(new.id,'card','Карта'),(new.id,'other','Басқа')
 on conflict(company_id,key) do nothing;
 return new;
end $$;
revoke all on function public.seed_company_payment_methods() from public,anon,authenticated;
create trigger companies_seed_payment_methods after insert on public.companies for each row execute function public.seed_company_payment_methods();
commit;
