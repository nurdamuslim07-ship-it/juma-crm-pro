begin;
-- Future companies receive all defaults without touching existing method IDs.
do $$ declare company uuid; begin
 insert into companies(name,code) values('PAYMENT-METHOD-PROVISION-TEST',gen_random_uuid()::text) returning id into company;
 if (select count(*) from payment_methods where company_id=company)<>5 then raise exception 'Default method provisioning failed';end if;
end $$;
select set_config('request.jwt.claim.sub',(select p.id::text from profiles p join companies c on c.id=p.company_id where c.name='JUMA — әзірлеу' limit 1),true);
set local role authenticated;
do $$
declare cid uuid; oid uuid; mid uuid; payment public.payments;
begin
 select id into cid from clients where company_id=auth_company_id() and deleted_at is null limit 1;
 select id into mid from payment_methods where company_id=auth_company_id() and key='kaspi';
 if mid is null then raise exception 'Kaspi unavailable';end if;
 insert into orders(client_id,order_number,product_type,total_amount_tiyn,created_by) values(cid,'PAYMENT-LOOKUP-TEST-'||gen_random_uuid(),'Тест',56700000,auth.uid()) returning id into oid;
 payment:=record_payment(gen_random_uuid()::text,oid,cid,45000000,mid);
 if payment.amount_tiyn<>45000000 or payment.method_id<>mid then raise exception 'Payment mismatch';end if;
end $$;
rollback;
