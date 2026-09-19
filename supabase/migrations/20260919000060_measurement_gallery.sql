begin;
alter table public.measurements add column photo_gallery jsonb not null default '[]'::jsonb;
alter table public.measurements add column room_plan jsonb not null default '[]'::jsonb check (jsonb_typeof(room_plan) = 'array');
update public.measurements set photo_gallery = jsonb_build_array(jsonb_build_object('path',photo_path,'annotations',photo_annotations)) where photo_path is not null;
create function public.valid_measurement_gallery(gallery jsonb, company uuid)
returns boolean language sql immutable set search_path = public as $$
 select case when jsonb_typeof(gallery) <> 'array' then false else not exists (
   select 1 from jsonb_array_elements(gallery) p
   where jsonb_typeof(p) <> 'object' or coalesce(jsonb_typeof(p->'path'),'null') <> 'string'
     or split_part(p->>'path','/',1) <> company::text
     or coalesce(jsonb_typeof(p->'annotations'),'null') <> 'array'
 ) end;
$$;
alter table public.measurements add constraint measurements_gallery_valid check (public.valid_measurement_gallery(photo_gallery,company_id));
commit;
