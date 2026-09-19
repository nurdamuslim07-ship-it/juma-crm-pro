-- Multi-tenant SaaS conversion — Stage 1d, part 4: partners RPCs.
--
-- `partners`/`partner_documents` have ALL direct table grants revoked
-- (see 20260713000018's header) — before this patch, every RPC here
-- operated across the whole table with no company filter at all, so
-- any caller with `partners.write`/`.read*` in their own company could
-- read, edit, or soft-delete ANY other company's suppliers.

create or replace function get_partners(
  p_search text default null,
  p_category partner_category default null,
  p_active_filter boolean default null,
  p_include_deleted boolean default false,
  p_id uuid default null,
  p_limit int default 50,
  p_offset int default 0
)
returns table (
  id uuid,
  display_name text,
  company_name text,
  category partner_category,
  phone text,
  phone_secondary text,
  whatsapp_phone text,
  address text,
  city text,
  contact_person text,
  tax_id text,
  service_description text,
  price_note text,
  trust_rating smallint,
  last_worked_at date,
  notes text,
  bank_details text,
  balance_tiyn bigint,
  is_active boolean,
  created_at timestamptz,
  updated_at timestamptz,
  deleted_at timestamptz,
  has_extended_access boolean,
  has_financial_access boolean
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_company_id uuid := auth_company_id();
  v_financial boolean := auth_has_permission('partners.read_financial');
  v_extended boolean := v_financial or auth_has_permission('partners.read_extended');
  v_basic boolean := v_extended or auth_has_permission('partners.read');
  v_show_deleted boolean := p_include_deleted and auth_is_director();
begin
  if not auth_is_active() then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  if not v_basic then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  return query
    select
      p.id, p.display_name, p.company_name, p.category,
      p.phone, p.phone_secondary, p.whatsapp_phone, p.address, p.city, p.contact_person,
      case when v_extended then p.tax_id end,
      case when v_extended then p.service_description end,
      case when v_extended then p.price_note end,
      case when v_extended then p.trust_rating end,
      case when v_extended then p.last_worked_at end,
      case when v_extended then p.notes end,
      case when v_financial then p.bank_details end,
      case when v_financial then p.balance_tiyn end,
      p.is_active, p.created_at, p.updated_at,
      case when auth_is_director() then p.deleted_at end,
      v_extended, v_financial
    from partners p
    where
      p.company_id = v_company_id
      and (case when v_show_deleted then p.deleted_at is not null else p.deleted_at is null end)
      and (p_id is null or p.id = p_id)
      and (
        p_search is null or p_search = '' or
        p.display_name ilike '%' || p_search || '%' or
        p.company_name ilike '%' || p_search || '%' or
        p.phone ilike '%' || p_search || '%' or
        p.phone_secondary ilike '%' || p_search || '%' or
        p.service_description ilike '%' || p_search || '%'
      )
      and (p_category is null or p.category = p_category)
      and (p_active_filter is null or p.is_active = p_active_filter)
    order by p.display_name
    limit greatest(p_limit, 0)
    offset greatest(p_offset, 0);
end;
$$;

create or replace function create_partner(
  p_display_name text,
  p_category partner_category,
  p_company_name text default null,
  p_phone text default null,
  p_phone_secondary text default null,
  p_whatsapp_phone text default null,
  p_address text default null,
  p_city text default null,
  p_contact_person text default null,
  p_tax_id text default null,
  p_service_description text default null,
  p_price_note text default null,
  p_trust_rating smallint default null,
  p_notes text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
begin
  if not auth_has_permission('partners.write') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  insert into partners (
    company_id, display_name, category, company_name, phone, phone_secondary, whatsapp_phone,
    address, city, contact_person, tax_id, service_description, price_note,
    trust_rating, notes
  ) values (
    auth_company_id(), p_display_name, p_category, p_company_name, p_phone, p_phone_secondary,
    p_whatsapp_phone, p_address, p_city, p_contact_person, p_tax_id, p_service_description,
    p_price_note, p_trust_rating, p_notes
  ) returning id into v_id;

  return v_id;
end;
$$;

-- Non-financial fields only, by design — see this file's header.
-- Financial fields go through update_partner_financials() instead.
create or replace function update_partner(
  p_id uuid,
  p_display_name text,
  p_category partner_category,
  p_company_name text default null,
  p_phone text default null,
  p_phone_secondary text default null,
  p_whatsapp_phone text default null,
  p_address text default null,
  p_city text default null,
  p_contact_person text default null,
  p_tax_id text default null,
  p_service_description text default null,
  p_price_note text default null,
  p_trust_rating smallint default null,
  p_notes text default null,
  p_is_active boolean default true
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not auth_has_permission('partners.write') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  update partners set
    display_name = p_display_name,
    category = p_category,
    company_name = p_company_name,
    phone = p_phone,
    phone_secondary = p_phone_secondary,
    whatsapp_phone = p_whatsapp_phone,
    address = p_address,
    city = p_city,
    contact_person = p_contact_person,
    tax_id = p_tax_id,
    service_description = p_service_description,
    price_note = p_price_note,
    trust_rating = p_trust_rating,
    notes = p_notes,
    is_active = p_is_active
  where id = p_id and company_id = auth_company_id() and deleted_at is null;

  if not found then
    raise exception 'Серіктес табылмады' using errcode = 'P0002';
  end if;
end;
$$;

-- Director-only — requirement: accountant "sees" financial data, only
-- the director has a write verb attached to it in the spec.
create or replace function update_partner_financials(
  p_id uuid,
  p_bank_details text,
  p_balance_tiyn bigint
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not auth_is_director() then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  update partners set bank_details = p_bank_details, balance_tiyn = p_balance_tiyn
  where id = p_id and company_id = auth_company_id() and deleted_at is null;

  if not found then
    raise exception 'Серіктес табылмады' using errcode = 'P0002';
  end if;
end;
$$;

create or replace function soft_delete_partner(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not auth_is_director() then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;
  update partners set deleted_at = now()
  where id = p_id and company_id = auth_company_id() and deleted_at is null;
end;
$$;

create or replace function restore_partner(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not auth_is_director() then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;
  update partners set deleted_at = null
  where id = p_id and company_id = auth_company_id() and deleted_at is not null;
end;
$$;

create or replace function get_partner_documents(p_partner_id uuid)
returns table (
  id uuid,
  partner_id uuid,
  storage_path text,
  file_name text,
  uploaded_by uuid,
  created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_company_id uuid := auth_company_id();
begin
  if not (
    auth_has_permission('partners.read_extended')
    or auth_has_permission('partners.read_financial')
  ) then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  if not exists (
    select 1 from partners where id = p_partner_id and company_id = v_company_id
  ) then
    raise exception 'Серіктес табылмады' using errcode = 'P0002';
  end if;

  return query
    select d.id, d.partner_id, d.storage_path, d.file_name, d.uploaded_by, d.created_at
    from partner_documents d
    where d.partner_id = p_partner_id and d.company_id = v_company_id
    order by d.created_at desc;
end;
$$;

create or replace function add_partner_document(
  p_partner_id uuid,
  p_storage_path text,
  p_file_name text
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_company_id uuid := auth_company_id();
  v_id uuid;
begin
  if not auth_has_permission('partners.write') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  if not exists (
    select 1 from partners where id = p_partner_id and company_id = v_company_id
  ) then
    raise exception 'Серіктес табылмады' using errcode = 'P0002';
  end if;

  insert into partner_documents (company_id, partner_id, storage_path, file_name, uploaded_by)
  values (v_company_id, p_partner_id, p_storage_path, p_file_name, auth.uid())
  returning id into v_id;

  return v_id;
end;
$$;

create or replace function delete_partner_document(p_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_company_id uuid := auth_company_id();
  v_path text;
begin
  if not auth_has_permission('partners.write') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  select storage_path into v_path from partner_documents
  where id = p_id and company_id = v_company_id;
  if not found then
    raise exception 'Құжат табылмады' using errcode = 'P0002';
  end if;

  delete from partner_documents where id = p_id and company_id = v_company_id;
  delete from storage.objects where bucket_id = 'partner-documents' and name = v_path;
end;
$$;
