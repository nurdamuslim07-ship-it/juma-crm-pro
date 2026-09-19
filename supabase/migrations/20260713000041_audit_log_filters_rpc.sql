-- Stage 4, Part 3: Audit Log UI backend.
--
-- The audit log LIST itself needs no new RPC: `audit_logs` already has
-- a real, non-revoked `audit_logs_select_director` policy
-- (20260713000025), and every filter/pagination primitive the
-- AuditLogScreen needs (date range, actor, entity_type, action,
-- search, offset/limit) is expressible as a direct PostgREST query
-- under that policy — see CompanyRemoteDataSource.getCompanySettings()
-- from Stage 3 for the same "direct table read, RLS already scopes
-- it" precedent. "Employee" filter options reuse the existing
-- `get_employees()` RPC (20260713000017/28) rather than a new one.
--
-- The one thing PostgREST genuinely cannot do is a `select distinct`
-- projection (it always returns full rows) — that's the only reason
-- this RPC exists, to populate the Module/Action filter dropdowns.

create function get_audit_log_filters()
returns table (modules text[], actions text[])
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  v_company_id uuid := auth_company_id();
begin
  if not (auth_is_active() and auth_is_director()) then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  return query
    select
      (select coalesce(array_agg(distinct entity_type order by entity_type), array[]::text[])
       from audit_logs where company_id = v_company_id),
      (select coalesce(array_agg(distinct action order by action), array[]::text[])
       from audit_logs where company_id = v_company_id);
end;
$$;
