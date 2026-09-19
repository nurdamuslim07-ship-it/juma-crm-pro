-- Partners/Suppliers module — see Partners module requirements.
-- Bank/payment details and the debt/advance balance are explicitly
-- called out as sensitive ("Банк реквизиттері мен баланс барлық
-- қолданушыға ашық болмасын"), so this module follows the Employees
-- module's stronger security pattern rather than the earlier
-- view-based column hide: ALL direct table privileges are revoked
-- from `authenticated`/`anon`, and every read/write goes through a
-- SECURITY DEFINER RPC that decides column visibility in Postgres.
--
-- Visibility is three-tiered (see get_partners() below):
--   partners.read           — basic contact info only (name, company,
--                              category, phones, address, city,
--                              contact person) — every internal role.
--   partners.read_extended  — + tax id, service/price notes, trust
--                              rating, last worked date, notes,
--                              documents — director/manager/purchaser/
--                              accountant.
--   partners.read_financial — + bank details, debt/advance balance —
--                              director/accountant only.
-- Write is split the same way: partners.write (create/edit
-- non-financial fields) is director/manager/purchaser; financial
-- fields are only ever changed via update_partner_financials(),
-- director-only — the requirement gives accountant "көреді" (sees)
-- for financial data, never a write verb, so accountant stays
-- read-only there. Delete/restore are director-only.

create table partners (
  id uuid primary key default gen_random_uuid(),
  display_name text not null,
  company_name text,
  category partner_category not null default 'other',
  phone text,
  phone_secondary text,
  whatsapp_phone text,
  address text,
  city text,
  contact_person text,
  tax_id text, -- БСН/ЖСН, optional per requirement
  service_description text, -- "Қызмет немесе тауар сипаттамасы"
  price_note text, -- "Баға туралы ескертпе"
  trust_rating smallint check (trust_rating between 1 and 5),
  last_worked_at date, -- "Соңғы жұмыс күні"
  notes text,
  -- Financial — redacted for everyone without partners.read_financial.
  -- Stored as a simple running column for now; always read/written
  -- through the RPCs below (never a direct `.from('partners')` query
  -- from Dart) specifically so a future partner_balance_transactions
  -- ledger table (per the requirement "partner_balances үшін кейін
  -- кеңейтуге ыңғайлы архитектура") can replace this column with a
  -- computed sum inside get_partners()'s SQL body alone, with zero
  -- change to the RPC's public signature or the Flutter call sites.
  -- Sign convention: positive = біздің серіктеске қарызымыз бар (our
  -- debt to the partner); negative = біз аванс төледік (we've prepaid
  -- them an advance).
  bank_details text,
  balance_tiyn bigint not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index partners_category_idx on partners (category);
create index partners_is_active_idx on partners (is_active);
create index partners_deleted_at_idx on partners (deleted_at);

create trigger partners_set_updated_at
  before update on partners
  for each row execute function set_updated_at();

create table partner_documents (
  id uuid primary key default gen_random_uuid(),
  partner_id uuid not null references partners (id) on delete cascade,
  storage_path text not null,
  file_name text not null,
  uploaded_by uuid references profiles (id),
  created_at timestamptz not null default now()
);

create index partner_documents_partner_id_idx on partner_documents (partner_id);

alter table partners enable row level security;
alter table partner_documents enable row level security;

-- Defense-in-depth only (see this file's header) — the real gate is
-- the REVOKE below. Mirrors the tiering the RPCs enforce.
create policy "partners_select_with_read_permission" on partners
  for select using (
    (deleted_at is null or auth_is_director())
    and (
      auth_has_permission('partners.read')
      or auth_has_permission('partners.read_extended')
      or auth_has_permission('partners.read_financial')
    )
  );

create policy "partners_insert_write_permission" on partners
  for insert with check (auth_has_permission('partners.write'));

create policy "partners_update_write_permission" on partners
  for update using (auth_has_permission('partners.write'))
  with check (auth_has_permission('partners.write'));

create policy "partners_delete_director_only" on partners
  for delete using (auth_is_director());

create policy "partner_documents_select_extended" on partner_documents
  for select using (
    auth_has_permission('partners.read_extended')
    or auth_has_permission('partners.read_financial')
  );

create policy "partner_documents_write_permission" on partner_documents
  for all using (auth_has_permission('partners.write'))
  with check (auth_has_permission('partners.write'));

revoke all on partners from authenticated, anon;
revoke all on partner_documents from authenticated, anon;
-- SECURITY DEFINER functions below still work: they execute as the
-- function owner, unaffected by this revoke.

-- Serves both the list screen (p_id null) and the detail screen
-- (p_id set), same pattern as get_employees()/p_user_id. p_include_deleted
-- is a director-only "trash" toggle: when true, only soft-deleted rows
-- are returned (for the restore screen); it's silently ignored for
-- everyone else so a non-director can never even discover a deleted
-- partner exists.
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
  -- Explicit access flags, not left for the client to infer from
  -- nullability — several extended/financial fields (trust_rating,
  -- notes, balance_tiyn) are legitimately nullable even when the
  -- caller DOES have access, so "field is null" alone can't tell the
  -- Flutter entity whether that's redaction or just an empty value.
  has_extended_access boolean,
  has_financial_access boolean
)
language plpgsql
stable
security definer
set search_path = public
as $$
declare
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
      (case when v_show_deleted then p.deleted_at is not null else p.deleted_at is null end)
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
    display_name, category, company_name, phone, phone_secondary, whatsapp_phone,
    address, city, contact_person, tax_id, service_description, price_note,
    trust_rating, notes
  ) values (
    p_display_name, p_category, p_company_name, p_phone, p_phone_secondary, p_whatsapp_phone,
    p_address, p_city, p_contact_person, p_tax_id, p_service_description, p_price_note,
    p_trust_rating, p_notes
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
  where id = p_id and deleted_at is null;

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
  where id = p_id and deleted_at is null;

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
  update partners set deleted_at = now() where id = p_id and deleted_at is null;
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
  update partners set deleted_at = null where id = p_id and deleted_at is not null;
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
begin
  if not (
    auth_has_permission('partners.read_extended')
    or auth_has_permission('partners.read_financial')
  ) then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  return query
    select d.id, d.partner_id, d.storage_path, d.file_name, d.uploaded_by, d.created_at
    from partner_documents d
    where d.partner_id = p_partner_id
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
  v_id uuid;
begin
  if not auth_has_permission('partners.write') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  insert into partner_documents (partner_id, storage_path, file_name, uploaded_by)
  values (p_partner_id, p_storage_path, p_file_name, auth.uid())
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
  v_path text;
begin
  if not auth_has_permission('partners.write') then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  select storage_path into v_path from partner_documents where id = p_id;
  delete from partner_documents where id = p_id;
  if v_path is not null then
    delete from storage.objects where bucket_id = 'partner-documents' and name = v_path;
  end if;
end;
$$;

-- Private bucket (like `receipts`, unlike the public `avatars` bucket)
-- — price lists/contracts aren't meant to be publicly linkable.
insert into storage.buckets (id, name, public)
values ('partner-documents', 'partner-documents', false)
on conflict (id) do nothing;

create policy "partner_documents_bucket_read"
  on storage.objects for select
  using (
    bucket_id = 'partner-documents'
    and (
      auth_has_permission('partners.read_extended')
      or auth_has_permission('partners.read_financial')
    )
  );

create policy "partner_documents_bucket_upload"
  on storage.objects for insert
  with check (bucket_id = 'partner-documents' and auth_has_permission('partners.write'));

create policy "partner_documents_bucket_delete"
  on storage.objects for delete
  using (bucket_id = 'partner-documents' and auth_has_permission('partners.write'));
