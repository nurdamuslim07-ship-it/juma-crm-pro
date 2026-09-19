-- Run after migration 61 as a rollback-only integration test using a dedicated test account.
begin;
select set_config('request.jwt.claim.sub',(select p.id::text from public.profiles p join public.companies c on c.id=p.company_id where c.name='JUMA — әзірлеу' limit 1),true);
set local role authenticated;
do $$
declare cid uuid; oid uuid; count_before integer; contract_id uuid; link text;
begin
 select id into cid from clients where company_id=auth_company_id() limit 1;
 if cid is null then raise exception 'Dedicated test client required';end if;
 insert into orders(company_id,client_id,order_number,product_type,created_by) values(auth_company_id(),cid,'WORKFLOW-TEST-'||gen_random_uuid(),'Тест',auth.uid()) returning id into oid;
 perform set_order_journey(oid,'design');
 if not exists(select 1 from whatsapp_outbox where order_id=oid and status='skipped') then raise exception 'No-consent guard failed';end if;
 perform set_client_whatsapp_consent(cid,true,'Integration test, rolled back');
 perform set_order_journey(oid,'contract');
 select count(*) into count_before from whatsapp_outbox where order_id=oid;
 perform set_order_journey(oid,'contract');
 if (select count(*) from whatsapp_outbox where order_id=oid)<>count_before then raise exception 'Repeated stage duplicated message';end if;
 contract_id:=save_order_contract(oid,'{"test":true}',auth_company_id()::text||'/test.pdf');
 perform approve_order_contract(contract_id);perform approve_order_contract(contract_id);
 if (select count(*) from whatsapp_outbox where event_key='contract:'||contract_id)<>1 then raise exception 'Repeated approval duplicated message';end if;
 link:=create_order_tracking_link(oid);if length(link)<>64 then raise exception 'Bad tracking token';end if;
 perform set_client_whatsapp_consent(cid,false,'Test revocation');
 if exists(select 1 from whatsapp_outbox where order_id=oid and status='queued') then raise exception 'Revocation left queued messages';end if;
end $$;
rollback;
