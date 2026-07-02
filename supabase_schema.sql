-- ============================================================================
-- JUMA UI — Мебель CRM Pro | Supabase схемасы
-- Осы SQL-ды udaijfkqxrafadhxktzl.supabase.co жобасының
-- SQL Editor бөлімінде іске қосыңыз (mebel-crm-мен бірдей Supabase жоба).
--
-- МАҢЫЗДЫ: баған атаулары src/types.ts-тегі өрістермен ДӘЛ бірдей camelCase
-- түрінде, тырнақшамен ("clientName" сияқты) жазылған. Осылайша
-- src/lib/supabase.ts ешбір snake_case<->camelCase түрлендіруін жасамайды —
-- JS обьектісі тікелей жолға (row) сәйкес келеді.
-- ============================================================================

create table if not exists public.users (
  id                 text primary key,
  name               text not null,
  email              text,
  phone              text,
  role               text not null check (role in ('director','employee')),
  password           text,
  "telegramId"       bigint,
  "telegramUsername" text,
  "createdAt"        text not null default now()::text
);

create table if not exists public.clients (
  id            text primary key,
  name          text not null,
  phone         text not null,
  email         text,
  address       text,
  "totalOrders" integer not null default 0,
  "totalSpent"  numeric not null default 0,
  notes         text,
  "createdAt"   text not null default now()::text
);

create table if not exists public.inventory (
  id            text primary key,
  name          text not null,
  category      text not null check (category in ('material','wood','foam','hardware','accessories')),
  quantity      numeric not null default 0,
  unit          text not null default 'дана',
  "minQuantity" numeric not null default 0,
  "costPerUnit" numeric not null default 0
);

create table if not exists public.employees (
  id               text primary key,
  name             text not null,
  role             text not null check (role in ('carpenter','upholsterer','designer','measurer','courier','manager')),
  phone            text,
  "activeTasks"    integer not null default 0,
  "completedTasks" integer not null default 0,
  "totalBonuses"   numeric not null default 0
);

create table if not exists public.measurements (
  id           text primary key,
  "clientName" text not null,
  phone        text,
  address      text,
  date         text,
  status       text not null default 'pending' check (status in ('pending','completed')),
  notes        text,
  width        numeric,
  depth        numeric,
  height       numeric,
  "roomType"   text,
  obstacles    jsonb,
  angle90      boolean
);

-- orders кестесі measurements/employees-тен КЕЙІН құрылады (FK себебінен)
create table if not exists public.orders (
  id                       text primary key,
  "clientName"             text not null,
  "clientPhone"            text not null,
  "productType"            text not null,
  material                 text,
  dimensions               text,
  price                    numeric not null default 0,
  "paidAmount"             numeric not null default 0,
  status                   text not null default 'new'
                             check (status in ('new','measurement','production','delivery','completed','cancelled')),
  "productionStage"        text check ("productionStage" in ('frame','foam','upholstery','assembly','ready')),
  "deliveryDate"           text,
  notes                    text,
  "measurementId"          text references public.measurements(id) on delete set null,
  "employeeId"             text references public.employees(id) on delete set null,
  "costBreakdown"          jsonb,
  "clientIin"              text,
  "contractWarrantyMonths" integer,
  "contractTermsDays"      integer,
  "contractSeller"         text,
  "createdAt"              text not null default now()::text
);

-- ============================================================================
-- Row Level Security — mebel-crm-дегі director/worker рөлдік үлгісіне сай.
-- Ескерту: бұл жоба Supabase Auth-ты емес, өз парольдік логинін қолданады
-- (App.tsx-тегі users кестесі), сондықтан RLS-ті "anon" рөліне ашық қалдырамыз.
-- Нақтырақ қауіпсіздік қажет болса — Supabase Auth-қа көшіп, "authenticated"
-- саясатына ауыстырыңыз немесе парольді бэкенд Edge Function-да тексеріңіз.
-- ============================================================================

alter table public.users        enable row level security;
alter table public.clients      enable row level security;
alter table public.orders       enable row level security;
alter table public.inventory    enable row level security;
alter table public.employees    enable row level security;
alter table public.measurements enable row level security;

do $$
declare
  t text;
begin
  foreach t in array array['users','clients','orders','inventory','employees','measurements'] loop
    execute format('drop policy if exists "allow_all_%1$s" on public.%1$s;', t);
    execute format('create policy "allow_all_%1$s" on public.%1$s for all using (true) with check (true);', t);
  end loop;
end $$;

-- ============================================================================
-- Realtime — CRM-дер арасында лайв синхрондау үшін (Dashboard → Database →
-- Replication бөлімінен де қосуға болады)
-- ============================================================================
alter publication supabase_realtime add table public.orders, public.clients,
  public.inventory, public.employees, public.measurements, public.users;
