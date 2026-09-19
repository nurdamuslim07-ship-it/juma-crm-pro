-- Second half of the create-employee fix (20260713000045 fixed the
-- company_id/profile-provisioning side). Live-tested the deployed
-- Edge Function end-to-end and found `service_role` has the exact
-- same schema-wide missing-baseline-grants defect already found and
-- partially fixed for `authenticated` (20260713000043) and `clients`
-- for `authenticated` (20260713000044) — same root cause (every
-- table in this project was created by the `postgres` role, which
-- gets a weaker pg_default_acl entry than `supabase_admin`), just
-- never discovered for `service_role` until an Edge Function actually
-- exercised a direct table write through the admin client.
--
-- Scoped to exactly what create-employee's adminClient needs, verified
-- against its actual code (supabase/functions/create-employee/index.ts):
--   - roles: SELECT (role-key lookup)
--   - user_roles: INSERT (role assignment)
--   - employees: INSERT (the employee record itself)
-- Not a broad service_role grants sweep — that is the same kind of
-- schema-wide fix already deliberately postponed for authenticated/anon
-- and should get the same dedicated, separate treatment, not be
-- folded in here.
grant select on roles to service_role;
grant insert on user_roles to service_role;
grant insert on employees to service_role;
