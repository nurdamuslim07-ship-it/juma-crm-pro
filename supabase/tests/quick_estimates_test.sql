begin;
select set_config('request.jwt.claim.sub',(select p.id::text from profiles p join companies c on c.id=p.company_id where c.name='JUMA — әзірлеу' limit 1),true);
set local role authenticated;
do $$ declare eid uuid; sid uuid; foreign_company uuid; begin
 insert into quick_estimates(name,snapshot) values('ROLLBACK-TEST','{"name":"test","price":200000}') returning id into eid;
 insert into estimate_price_catalog(item_key,snapshot) values('ROLLBACK-TEST','{"price":200000}');
 update estimate_price_catalog set snapshot='{"price":300000}' where item_key='ROLLBACK-TEST';
 if (select snapshot->>'price' from quick_estimates where id=eid)<>'200000' then raise exception 'Estimate mutated with catalog';end if;
 insert into quick_estimates(name,snapshot) select name||' copy',snapshot from quick_estimates where id=eid returning id into sid;
 if sid=eid then raise exception 'Copy id reused';end if;
 update quick_estimates set name='UPDATED' where id=eid;
 if not exists(select 1 from quick_estimates where id=eid and name='UPDATED') then raise exception 'Save failed';end if;
 foreign_company:=gen_random_uuid();
 begin
 insert into quick_estimates(company_id,name,snapshot) values(foreign_company,'DENIED','{}');
 raise exception 'Cross tenant insert accepted';
 exception when insufficient_privilege then null;
 end;
end $$;
rollback;
