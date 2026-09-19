begin;
alter table public.orders add column journey_stage text not null default 'measurement'
 check(journey_stage in ('measurement','design','contract','advance','cutting','edge_banding','assembly','quality','delivery','installation','completed'));
update public.orders set journey_stage=case status::text when 'installed' then 'completed' when 'ready' then 'quality' when 'in_progress' then 'assembly' when 'accepted' then 'contract' else 'measurement' end;
create table public.client_whatsapp_consent (
 client_id uuid primary key references public.clients(id), company_id uuid not null references public.companies(id),
 enabled boolean not null default false, source text not null, recorded_by uuid references auth.users(id), recorded_at timestamptz not null default now()
);
create table public.order_journey_history (
 id uuid primary key default gen_random_uuid(),company_id uuid not null references public.companies(id),order_id uuid not null references public.orders(id),
 stage text not null,changed_by uuid references auth.users(id),created_at timestamptz not null default now()
);
create table public.order_contracts (
 id uuid primary key default gen_random_uuid(),company_id uuid not null references public.companies(id),order_id uuid not null references public.orders(id),
 snapshot jsonb not null,storage_path text not null,status text not null default 'draft' check(status in ('draft','approved')),
 approved_by uuid references auth.users(id),approved_at timestamptz,created_at timestamptz not null default now()
);
create table public.whatsapp_outbox (
 id uuid primary key default gen_random_uuid(),company_id uuid not null references public.companies(id),order_id uuid not null references public.orders(id),client_id uuid not null references public.clients(id),
 event_key text not null unique,kind text not null check(kind in ('stage','contract')),payload jsonb not null,
 status text not null default 'queued' check(status in ('queued','sending','sent','delivered','read','failed','unknown','skipped')),
 provider_id text unique,error_code text,created_at timestamptz not null default now(),updated_at timestamptz not null default now()
);
create index whatsapp_outbox_pending on public.whatsapp_outbox(company_id,created_at) where status='queued';
create index order_journey_history_order on public.order_journey_history(order_id,created_at);
create index order_contracts_order on public.order_contracts(order_id,created_at);
create index whatsapp_outbox_order on public.whatsapp_outbox(order_id,created_at);
alter table public.client_whatsapp_consent enable row level security;
alter table public.order_journey_history enable row level security;
alter table public.order_contracts enable row level security;
alter table public.whatsapp_outbox enable row level security;
create policy consent_read on public.client_whatsapp_consent for select to authenticated using(company_id=auth_company_id() and auth_is_active() and auth_has_permission('orders.read'));
create policy journey_read on public.order_journey_history for select to authenticated using(company_id=auth_company_id() and auth_is_active() and auth_has_permission('orders.read'));
create policy contracts_read on public.order_contracts for select to authenticated using(company_id=auth_company_id() and auth_is_active() and auth_has_permission('orders.read'));
create policy outbox_read on public.whatsapp_outbox for select to authenticated using(company_id=auth_company_id() and auth_is_active() and auth_has_permission('orders.read'));
revoke all on public.client_whatsapp_consent,public.order_journey_history,public.order_contracts,public.whatsapp_outbox from anon,authenticated;
grant select on public.client_whatsapp_consent,public.order_journey_history,public.order_contracts,public.whatsapp_outbox to authenticated;
grant all on public.client_whatsapp_consent,public.order_journey_history,public.order_contracts,public.whatsapp_outbox to service_role;

create function public.set_client_whatsapp_consent(p_client_id uuid,p_enabled boolean,p_source text)
returns void language plpgsql security definer set search_path=public as $$
begin
 if not auth_is_active() or not auth_has_permission('orders.write') or not exists(select 1 from clients where id=p_client_id and company_id=auth_company_id()) then raise exception 'Permission denied' using errcode='42501';end if;
 if length(trim(p_source))<3 then raise exception 'Consent source required';end if;
 insert into client_whatsapp_consent(client_id,company_id,enabled,source,recorded_by) values(p_client_id,auth_company_id(),p_enabled,trim(p_source),auth.uid())
 on conflict(client_id) do update set enabled=excluded.enabled,source=excluded.source,recorded_by=excluded.recorded_by,recorded_at=now();
 if not p_enabled then update whatsapp_outbox set status='skipped',error_code='consent_revoked',updated_at=now() where client_id=p_client_id and company_id=auth_company_id() and status='queued';end if;
end $$;

create function public.record_order_journey() returns trigger language plpgsql security definer set search_path=public as $$
declare event uuid; allowed boolean; client_name text;
begin
 if new.journey_stage is not distinct from old.journey_stage then return new;end if;
 insert into order_journey_history(company_id,order_id,stage,changed_by) values(new.company_id,new.id,new.journey_stage,auth.uid()) returning id into event;
 select name into client_name from clients where id=new.client_id and company_id=new.company_id;
 select enabled into allowed from client_whatsapp_consent where client_id=new.client_id and company_id=new.company_id;
 insert into whatsapp_outbox(company_id,order_id,client_id,event_key,kind,payload,status,error_code)
 values(new.company_id,new.id,new.client_id,event::text,'stage',jsonb_build_object('client_name',client_name,'order_number',new.order_number,'stage',new.journey_stage),case when allowed then 'queued' else 'skipped' end,case when allowed then null else 'no_consent' end);
 return new;
end $$;
create trigger orders_journey_changed after update of journey_stage on public.orders for each row execute function public.record_order_journey();

create function public.sync_production_journey() returns trigger language plpgsql security definer set search_path=public as $$
declare stage_key text;
begin
 select key into stage_key from production_stages where id=new.new_stage_id;
 stage_key:=case stage_key when 'ready' then 'quality' when 'ready_for_installation' then 'delivery' when 'installed' then 'completed' else stage_key end;
 if stage_key in ('cutting','edge_banding','assembly','quality','delivery','completed') then
 update orders set journey_stage=stage_key where id=new.order_id;
 end if;
 return new;
end $$;
create trigger production_journey_sync after insert on public.production_stage_history for each row execute function public.sync_production_journey();

create function public.set_order_journey(p_order_id uuid,p_stage text)
returns void language plpgsql security definer set search_path=public as $$
declare sid uuid; stage_key text;
begin
 if not auth_is_active() or not auth_has_permission('orders.write') or not exists(select 1 from orders where id=p_order_id and company_id=auth_company_id() and deleted_at is null) then raise exception 'Permission denied' using errcode='42501';end if;
 if p_stage not in ('measurement','design','contract','advance','cutting','edge_banding','assembly','quality','delivery','installation','completed') then raise exception 'Invalid stage';end if;
 stage_key:=case p_stage when 'quality' then 'ready' when 'delivery' then 'ready_for_installation' when 'completed' then 'installed' else p_stage end;
 select id into sid from production_stages where company_id=auth_company_id() and key=stage_key;
 if sid is not null then perform move_order_to_stage(p_order_id,sid,null);end if;
 update orders set journey_stage=p_stage where id=p_order_id;
end $$;

create function public.save_order_contract(p_order_id uuid,p_snapshot jsonb,p_storage_path text)
returns uuid language plpgsql security definer set search_path=public as $$
declare result uuid;
begin
 if not auth_is_active() or not auth_has_permission('orders.write') or not exists(select 1 from orders where id=p_order_id and company_id=auth_company_id() and deleted_at is null) or split_part(p_storage_path,'/',1)<>auth_company_id()::text then raise exception 'Permission denied' using errcode='42501';end if;
 insert into order_contracts(company_id,order_id,snapshot,storage_path) values(auth_company_id(),p_order_id,p_snapshot,p_storage_path) returning id into result;
 return result;
end $$;
create function public.approve_order_contract(p_contract_id uuid)
returns void language plpgsql security definer set search_path=public as $$
declare c order_contracts; o orders; allowed boolean;
begin
 if not auth_is_active() or not auth_has_permission('orders.write') then raise exception 'Permission denied' using errcode='42501';end if;
 select * into c from order_contracts where id=p_contract_id and company_id=auth_company_id() for update;
 if not found then raise exception 'Contract not found';end if;
 select * into o from orders where id=c.order_id and company_id=c.company_id and deleted_at is null;
 if not found then raise exception 'Order not found';end if;
 select enabled into allowed from client_whatsapp_consent where client_id=o.client_id and company_id=c.company_id;
 if not coalesce(allowed,false) then raise exception 'Client consent required';end if;
 update order_contracts set status='approved',approved_by=auth.uid(),approved_at=now() where id=c.id;
 insert into whatsapp_outbox(company_id,order_id,client_id,event_key,kind,payload)
 values(c.company_id,o.id,o.client_id,'contract:'||c.id,'contract',jsonb_build_object('order_number',o.order_number,'contract_id',c.id,'storage_path',c.storage_path)) on conflict(event_key) do nothing;
end $$;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('order-contracts','order-contracts',false,10485760,array['application/pdf']) on conflict(id) do nothing;
create policy contract_pdf_read on storage.objects for select to authenticated using(bucket_id='order-contracts' and auth_is_active() and auth_has_permission('orders.read') and (storage.foldername(name))[1]=auth_company_id()::text);
create policy contract_pdf_write on storage.objects for insert to authenticated with check(bucket_id='order-contracts' and auth_is_active() and auth_has_permission('orders.write') and (storage.foldername(name))[1]=auth_company_id()::text);
revoke all on function public.set_client_whatsapp_consent(uuid,boolean,text),public.set_order_journey(uuid,text),public.save_order_contract(uuid,jsonb,text),public.approve_order_contract(uuid) from public,anon;
grant execute on function public.set_client_whatsapp_consent(uuid,boolean,text),public.set_order_journey(uuid,text),public.save_order_contract(uuid,jsonb,text),public.approve_order_contract(uuid) to authenticated;
-- Trigger functions are not public RPC entry points.
revoke all on function public.record_order_journey(),public.sync_production_journey() from public,anon,authenticated;

create function public.claim_whatsapp_message(p_company_id uuid)
returns setof public.whatsapp_outbox language plpgsql security definer set search_path=public as $$
begin
 update whatsapp_outbox set status='unknown',error_code='worker_interrupted',updated_at=now() where company_id=p_company_id and status='sending' and updated_at<now()-interval '10 minutes';
 update whatsapp_outbox q set status='skipped',error_code='consent_or_order_unavailable',updated_at=now()
 where q.company_id=p_company_id and q.status='queued' and (
 not exists(select 1 from client_whatsapp_consent c where c.client_id=q.client_id and c.company_id=q.company_id and c.enabled)
 or not exists(select 1 from orders o join companies c on c.id=o.company_id where o.id=q.order_id and o.deleted_at is null and c.is_active)
 or q.created_at<now()-interval '48 hours');
 return query update whatsapp_outbox set status='sending',updated_at=now() where id=(select id from whatsapp_outbox where company_id=p_company_id and status='queued' order by created_at for update skip locked limit 1) returning *;
end $$;
revoke all on function public.claim_whatsapp_message(uuid) from public,anon,authenticated;
grant execute on function public.claim_whatsapp_message(uuid) to service_role;

create table public.order_tracking_links(order_id uuid primary key references orders(id),company_id uuid not null references companies(id),token_hash text not null unique,expires_at timestamptz not null);
alter table public.order_tracking_links enable row level security;
revoke all on public.order_tracking_links from public,anon,authenticated;
grant all on public.order_tracking_links to service_role;
create function public.create_order_tracking_link(p_order_id uuid)
returns text language plpgsql security definer set search_path=public,extensions as $$
declare token text;
begin
 if not auth_is_active() or not auth_has_permission('orders.write') or not exists(select 1 from orders where id=p_order_id and company_id=auth_company_id() and deleted_at is null) then raise exception 'Permission denied' using errcode='42501';end if;
 token:=encode(gen_random_bytes(32),'hex');
 insert into order_tracking_links(order_id,company_id,token_hash,expires_at) values(p_order_id,auth_company_id(),encode(digest(token,'sha256'),'hex'),now()+interval '90 days')
 on conflict(order_id) do update set token_hash=excluded.token_hash,expires_at=excluded.expires_at;
 return token;
end $$;
revoke all on function public.create_order_tracking_link(uuid) from public,anon;
grant execute on function public.create_order_tracking_link(uuid) to authenticated;
commit;
