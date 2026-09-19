-- Multi-tenant SaaS conversion — Stage 1d, part 1: required trigger
-- fixes (not just hardening — these two triggers would otherwise
-- FAIL outright now that Stage 1b made order_status_history.company_id
-- and production_stage_history.company_id NOT NULL).
--
-- Both triggers fire on a row (`orders`/`order_production_progress`)
-- that already has its own `company_id` — no lookup needed, just carry
-- it over onto the history row being inserted.

create or replace function enforce_order_status_change()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if TG_OP = 'INSERT' then
    if not auth_can_set_order_status(NEW.status) then
      raise exception 'Бұл статусты орнатуға рұқсатыңыз жоқ' using errcode = '42501';
    end if;
    insert into order_status_history (order_id, company_id, previous_status, new_status, changed_by, source)
    values (NEW.id, NEW.company_id, null, NEW.status, auth.uid(), 'web');
  elsif TG_OP = 'UPDATE' and NEW.status is distinct from OLD.status then
    if not auth_can_set_order_status(NEW.status) then
      raise exception 'Бұл статусты орнатуға рұқсатыңыз жоқ' using errcode = '42501';
    end if;
    insert into order_status_history (order_id, company_id, previous_status, new_status, changed_by, source)
    values (NEW.id, NEW.company_id, OLD.status, NEW.status, auth.uid(), 'web');
  end if;
  return NEW;
end;
$$;

create or replace function enforce_production_stage_change()
returns trigger
language plpgsql
set search_path = public
as $$
declare
  v_default_percent smallint;
begin
  if NEW.current_stage_id is not null and (
    TG_OP = 'INSERT' or NEW.current_stage_id is distinct from OLD.current_stage_id
  ) then
    select default_percent into v_default_percent
    from production_stages where id = NEW.current_stage_id;
    NEW.percent_complete := coalesce(v_default_percent, NEW.percent_complete);

    insert into production_stage_history (order_id, company_id, previous_stage_id, new_stage_id, changed_by)
    values (
      NEW.order_id,
      NEW.company_id,
      case when TG_OP = 'UPDATE' then OLD.current_stage_id else null end,
      NEW.current_stage_id,
      auth.uid()
    );
  end if;
  NEW.updated_by := auth.uid();
  NEW.updated_at := now();
  return NEW;
end;
$$;
