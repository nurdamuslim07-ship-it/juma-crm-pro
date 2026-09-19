begin;
-- Measurement workspace. Existing rows remain valid; all access stays tenant-scoped.
alter table public.measurements
  add column material text not null default '',
  add column estimated_amount_tiyn bigint not null default 0 check (estimated_amount_tiyn >= 0),
  add column photo_path text,
  add column photo_annotations jsonb not null default '[]'::jsonb check (jsonb_typeof(photo_annotations) = 'array');

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('measurement-photos', 'measurement-photos', false, 10485760, array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;

create policy measurement_photo_read on storage.objects for select to authenticated
using (bucket_id = 'measurement-photos' and public.auth_is_active()
  and public.auth_has_permission('measurements.read')
  and (storage.foldername(name))[1] = public.auth_company_id()::text);
create policy measurement_photo_insert on storage.objects for insert to authenticated
with check (bucket_id = 'measurement-photos' and public.auth_is_active()
  and public.auth_has_permission('measurements.write')
  and (storage.foldername(name))[1] = public.auth_company_id()::text);
create policy measurement_photo_delete on storage.objects for delete to authenticated
using (bucket_id = 'measurement-photos' and public.auth_is_active()
  and public.auth_has_permission('measurements.write')
  and (storage.foldername(name))[1] = public.auth_company_id()::text);

-- Invoker retains normal RLS. A row lock makes retry/double-tap conversion idempotent.
create or replace function public.measurement_to_order(p_measurement_id uuid)
returns uuid language plpgsql security invoker set search_path = public as $$
declare m public.measurements; result uuid;
begin
  if not auth_is_active() or not auth_has_permission('measurements.write')
     or not auth_has_permission('orders.write') then
    raise exception 'Permission denied' using errcode = '42501';
  end if;
  select * into m from public.measurements
    where id = p_measurement_id and company_id = auth_company_id() for update;
  if not found then raise exception 'Measurement not found'; end if;
  if m.order_id is not null then return m.order_id; end if;
  if not exists (select 1 from public.clients where id = m.client_id and company_id = auth_company_id()) then
    raise exception 'Client not found' using errcode = '42501';
  end if;
  insert into public.orders(company_id, client_id, order_number, product_type, material, dimensions, address, description,
    total_amount_tiyn, status, measurement_date, created_by)
  values (m.company_id, m.client_id, 'ZM-' || gen_random_uuid()::text,
    coalesce(nullif(m.room_type, ''), 'Жиһаз'), m.material,
    concat(m.width, ' × ', m.height, ' × ', m.depth, ' мм'), m.address,
    concat_ws(E'\n', m.address, m.material,
      concat(m.width, ' × ', m.height, ' × ', m.depth, ' мм'), m.notes),
    m.estimated_amount_tiyn, 'measurement', current_date, auth.uid()) returning id into result;
  update public.measurements set order_id = result, status = 'completed' where id = m.id;
  return result;
end $$;
revoke all on function public.measurement_to_order(uuid) from public, anon;
grant execute on function public.measurement_to_order(uuid) to authenticated;

-- Reject cross-company references even if a caller bypasses the client picker.
drop policy measurements_write on public.measurements;
create policy measurements_write on public.measurements for all to authenticated
using (auth_is_active() and auth_has_permission('measurements.write') and company_id = auth_company_id())
with check (auth_is_active() and auth_has_permission('measurements.write') and company_id = auth_company_id()
  and exists (select 1 from public.clients c where c.id = client_id and c.company_id = auth_company_id())
  and (order_id is null or exists (select 1 from public.orders o where o.id = order_id and o.company_id = auth_company_id()))
  and (photo_path is null or split_part(photo_path, '/', 1) = auth_company_id()::text));
commit;
