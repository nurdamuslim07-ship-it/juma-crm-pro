-- Stage 4, Part 1: Realtime.
--
-- Supabase Realtime's classic "Postgres Changes" feature only
-- broadcasts a table's changes once it's added to the
-- `supabase_realtime` publication, and — per Supabase's own docs —
-- still gates each event through the subscribing role's RLS policies
-- and table grants, exactly like a normal query. That second part is
-- why `employees`/`company_join_requests`/`company_invitations` are
-- deliberately NOT added here: they have `revoke all ... from
-- authenticated, anon` (see 20260713000017/37's own header comments —
-- RPC-only access, defense in depth), so a direct subscription from
-- an authenticated client would never receive anything anyway. The
-- Flutter side proxies "Employees changed" / "a join request
-- landed or was resolved" through `profiles` instead — every one of
-- those actions already writes to `profiles.company_id`/`status` via
-- the onboarding RPCs (see 20260713000037), and `profiles` has a real,
-- non-revoked SELECT policy.
--
-- No REPLICA IDENTITY FULL anywhere: the Flutter side only uses these
-- events as an "something changed, refetch the list" signal (see
-- core/realtime/realtime_providers.dart), never diffs old vs. new
-- values client-side, so the default primary-key-only replica
-- identity is sufficient.

alter publication supabase_realtime add table
  orders,
  payments,
  materials,
  inventory_balances,
  profiles,
  companies,
  company_subscriptions;
