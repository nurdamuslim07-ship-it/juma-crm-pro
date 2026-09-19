-- Fixes the confirmed root cause of "client soft-delete fails RLS":
--   update clients set deleted_at = <non-null> ...
--   -> ERROR 42501: new row violates row-level security policy for table "clients"
--
-- Root cause (confirmed by isolated reproduction on a throwaway table
-- with an identical policy set, in a rolled-back transaction — not
-- guessed): `clients_select`'s policy requires `deleted_at is null`.
-- For UPDATE, PostgreSQL's row-security engine requires the resulting
-- new row to still satisfy at least one applicable SELECT policy, in
-- addition to the UPDATE policy's own WITH CHECK — this is standard,
-- documented Postgres RLS behaviour (not specific to this schema),
-- and reproduces on ANY table shaped like clients: a SELECT policy
-- filtering by `deleted_at is null` will always reject an UPDATE that
-- sets `deleted_at` to non-null, no matter what the UPDATE policy's
-- own WITH CHECK says, because the post-update row would no longer be
-- visible under that SELECT policy. `clients_update`'s WITH CHECK was
-- never wrong — it was confirmed, via direct evaluation, to return
-- true for the exact row/user/permission combination that still
-- failed. Changing `clients_update`'s policy text cannot fix this,
-- because the conflict is with the *SELECT* policy, not the UPDATE
-- policy.
--
-- Fix: move the soft-delete/restore transition into a SECURITY
-- DEFINER RPC, exactly matching the pattern this codebase already
-- uses for the identical problem on employees
-- (`soft_delete_employee()`, 20260713000017). A SECURITY DEFINER
-- function executes as its owner (this project's tables are all
-- owned by `postgres`, which has `relforcerowsecurity = false` on
-- `clients` — confirmed — so RLS does not apply to the owner's own
-- writes at all); the function's own explicit `auth_is_director()`
-- check becomes the sole authorization gate, matching the intent
-- already expressed by the existing (previously unreachable)
-- `clients_soft_delete_director` policy. This sidesteps the
-- SELECT-vs-UPDATE RLS interaction entirely rather than fighting it.
--
-- restore_client() is the necessary counterpart — a "soft delete"
-- with no way back is not actually a soft delete (per
-- DATABASE_SCHEMA.md's soft-delete convention) — added here for the
-- same reason and with the same authorization gate, not as a new,
-- separately-scoped feature.
create or replace function soft_delete_client(p_client_id uuid)
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

  update clients set deleted_at = now()
  where id = p_client_id and company_id = v_company_id;
end;
$$;

create or replace function restore_client(p_client_id uuid)
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

  update clients set deleted_at = null
  where id = p_client_id and company_id = v_company_id;
end;
$$;
