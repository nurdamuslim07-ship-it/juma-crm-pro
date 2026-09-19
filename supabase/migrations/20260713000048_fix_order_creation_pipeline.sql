-- Fixes the confirmed root cause of "creating a new Order fails":
-- `orders_status_transition_guard` (20260713000015) is a single
-- BEFORE INSERT OR UPDATE trigger. On INSERT, its own function
-- (enforce_order_status_change()) does:
--   insert into order_status_history (order_id, ...) values (NEW.id, ...)
-- `order_status_history.order_id` has a non-deferrable FK to
-- `orders.id` (confirmed via pg_constraint: condeferrable = false).
-- A BEFORE INSERT trigger fires before the triggering row is written
-- into `orders` — so at the moment this child insert runs, no row
-- with id = NEW.id exists in `orders` yet, and the FK check (which
-- runs immediately, not deferred) fails every time, for every role,
-- unconditionally. This is why order creation has never worked.
--
-- Two candidate fixes were evaluated:
--   (a) make the FK DEFERRABLE INITIALLY DEFERRED, so its check waits
--       until COMMIT (by which point the parent row exists).
--   (b) split the combined trigger so the INSERT-branch runs AFTER
--       INSERT instead of BEFORE, leaving the UPDATE-branch's timing
--       untouched (UPDATE was never affected by this bug — the row
--       being updated already exists in the table, so its BEFORE
--       UPDATE trigger never had a missing-parent-row problem).
--
-- (b) was chosen. Reasoning:
--   - Zero other constraint anywhere in this schema is deferrable
--     (checked via pg_constraint across every table) — introducing
--     the first one would be a genuinely new, previously-unused
--     pattern for this codebase to carry, and deferred constraints
--     are a known source of "why did this error surface so late"
--     confusion (the violation would only be reported at COMMIT,
--     which can be a different point than the statement that
--     actually caused it, in a more complex future transaction).
--   - (b) only changes the timing of the exact code path that is
--     actually broken (INSERT) and leaves the already-correct UPDATE
--     path completely untouched — a strictly smaller behavior change
--     than altering a constraint that governs every future write to
--     this table, not just this trigger's own insert.
--   - (b) is the standard, textbook-recommended shape for this exact
--       situation: BEFORE triggers validate/mutate the row being
--       written; AFTER triggers record consequential facts about a
--       row that now definitely exists (an audit-trail write is
--       exactly that). No functional behavior changes for callers:
--       raising an exception in an AFTER trigger still aborts the
--       entire INSERT statement (including the just-written `orders`
--       row) exactly as a BEFORE trigger would — Postgres statement
--       atomicity does not depend on trigger timing. The permission
--       check (auth_can_set_order_status()) still runs before the
--       client ever sees success either way.
--
-- enforce_order_status_change() itself is NOT modified — its body
-- already branches on TG_OP and works correctly regardless of
-- whether the INSERT branch is invoked BEFORE or AFTER the row is
-- written; only the trigger *declarations* change.
drop trigger if exists orders_status_transition_guard on orders;

create trigger orders_status_transition_guard_insert
  after insert on orders
  for each row execute function enforce_order_status_change();

create trigger orders_status_transition_guard_update
  before update on orders
  for each row execute function enforce_order_status_change();

-- Two additional, necessary-but-distinct blockers found while
-- verifying the trigger fix — without these, "Order creation works
-- in production" would still be false even after the fix above.
-- Both are the same defect FAMILY already fixed for other tables
-- this session (20260713000043/44/46/47): every table in this
-- project was created by the `postgres` role, which never receives
-- the baseline SELECT/INSERT/UPDATE grants `authenticated` needs —
-- `orders`/`order_status_history` were simply not among the tables
-- reached yet. Scoped to exactly what each table's own existing RLS
-- policies already declare — no policy is changed.
grant select, insert, update, delete on orders to authenticated;
grant select, insert on order_status_history to authenticated;

-- `order_status_role_permissions` (20260713000015's own seed) never
-- included the `owner` role — it predates the multi-tenant `owner`
-- role (added later, 20260713000037) and was never updated for it.
-- Every other real role that can act on orders (director, manager,
-- measurer, designer, workshop_manager) has explicit rows; `owner`
-- has none, so `auth_can_set_order_status()` returns false for an
-- owner attempting ANY status, including the initial 'measurement'
-- status of a brand-new order — meaning the one account type every
-- company's creator actually holds could never create an order.
-- `owner` is designed throughout this schema as director's superset
-- (see 20260713000037's own header comment: "owner ... full access,
-- same permission set as director plus company-settings/subscription/
-- billing management"), so it gets exactly director's existing rows,
-- not a new permission model — a data-completeness fix, not a new
-- authorization decision.
insert into order_status_role_permissions (status, role_key)
select status, 'owner'::role_key
from order_status_role_permissions
where role_key = 'director'
on conflict do nothing;
