begin;
select set_config('request.jwt.claim.sub',(select p.id::text from public.profiles p join public.companies c on c.id=p.company_id where c.name='JUMA — әзірлеу' limit 1),true);
set local role authenticated;
do $$
declare cid uuid; oid uuid; tenant uuid;
begin
 select id into cid from clients where company_id=auth_company_id() and deleted_at is null limit 1;
 if cid is null then raise exception 'Test client required';end if;
 -- Mirrors Flutter: company_id omitted, responsible employee is current user.
 insert into orders(client_id,order_number,product_type,total_amount_tiyn,responsible_employee_id,measurement_date,planned_completion_date,created_by,status)
 values(cid,'COMPANY-DEFAULT-TEST-'||gen_random_uuid(),'Тест асүй',56700000,auth.uid(),'2026-09-19','2026-09-30',auth.uid(),'measurement') returning id,company_id into oid,tenant;
 if tenant is distinct from auth_company_id() then raise exception 'Incorrect tenant';end if;
 if not exists(select 1 from orders where id=oid) then raise exception 'Created order not readable';end if;
 begin
 insert into orders(company_id,client_id,order_number,product_type,created_by)
 values(gen_random_uuid(),cid,'CROSS-TENANT-TEST-'||gen_random_uuid(),'Тест',auth.uid());
 raise exception 'Cross-tenant insert accepted';
 exception when insufficient_privilege then null;
 end;
end $$;
rollback;
