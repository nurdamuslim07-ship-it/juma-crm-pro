-- Fixes the same defect class as 20260713000053 (clients), now
-- confirmed to also apply to orders — flagged as a high-confidence,
-- unconfirmed carryover blocker in the previous fix pass
-- (FINAL_PRODUCTION_FIX_REPORT.md's "remaining blockers" §1), now
-- investigated and fixed.
--
-- `order_remote_datasource.dart`'s deleteOrder() does a raw
-- `UPDATE orders SET deleted_at = <non-null> ...`. `orders_select_broad`/
-- `orders_select_assigned`/`orders_select_financial` all require
-- `deleted_at is null`. Exactly as with clients, PostgreSQL's
-- row-security engine requires the resulting new row to still satisfy
-- at least one applicable SELECT policy for any UPDATE — so this
-- raw update fails RLS unconditionally, for every role, regardless of
-- what `orders_update`'s own WITH CHECK says (it has no deleted_at
-- clause, exactly like clients_update).
--
-- Same fix: a SECURITY DEFINER RPC pair, matching
-- `soft_delete_client()`/`restore_client()` and `soft_delete_employee()`
-- exactly. Gated by `auth_is_director()`, matching the intent already
-- expressed (but previously unreachable for this exact transition) by
-- the existing `orders_delete_director` policy.
create or replace function soft_delete_order(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_company_id uuid := auth_company_id();
begin
  if not auth_is_director() then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  update orders set deleted_at = now()
  where id = p_order_id and company_id = v_company_id;
end;
$$;

create or replace function restore_order(p_order_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_company_id uuid := auth_company_id();
begin
  if not auth_is_director() then
    raise exception 'Бұл әрекетке рұқсатыңыз жоқ' using errcode = '42501';
  end if;

  update orders set deleted_at = null
  where id = p_order_id and company_id = v_company_id;
end;
$$;
