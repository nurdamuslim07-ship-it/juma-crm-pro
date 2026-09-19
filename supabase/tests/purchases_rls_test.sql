-- pgTAP tests proving the Purchases module's core security/behavior
-- claims: the role split (manager creates/edits only; purchaser
-- approves/receives but not pays; accountant pays but never creates;
-- warehouse only receives), the draft-only edit/approve guard, the
-- item-total/order-total triggers, and — the key cross-module
-- assertion — that receive_purchase_order() writes through to
-- inventory_batches/inventory_balances/partners.balance_tiyn and that
-- Production's own get_production_queue() (unchanged) reflects the
-- new stock immediately afterward. Run with `supabase test db` —
-- like the rest of this schema, this has NOT been executed against a
-- live database in this environment (no Postgres/Supabase CLI
-- available — see supabase/README.md).

begin;
select plan(32);

-- ---------- fixtures ----------
insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'director@test.local'),
  ('33333333-3333-3333-3333-333333333333', 'manager@test.local'),
  ('22222222-2222-2222-2222-222222222222', 'purchaser@test.local'),
  ('55555555-5555-5555-5555-555555555555', 'accountant@test.local'),
  ('66666666-6666-6666-6666-666666666666', 'warehouse@test.local');
-- profiles rows are created automatically by handle_new_auth_user().

insert into user_roles (profile_id, role_id) values
  ('11111111-1111-1111-1111-111111111111', (select id from roles where key = 'director')),
  ('33333333-3333-3333-3333-333333333333', (select id from roles where key = 'manager')),
  ('22222222-2222-2222-2222-222222222222', (select id from roles where key = 'purchaser')),
  ('55555555-5555-5555-5555-555555555555', (select id from roles where key = 'accountant')),
  ('66666666-6666-6666-6666-666666666666', (select id from roles where key = 'warehouse'));

set local role authenticated;
set local "request.jwt.claims" to '{"sub": "11111111-1111-1111-1111-111111111111", "role": "authenticated"}';

insert into partners (id, display_name, category)
values ('dddddddd-dddd-dddd-dddd-dddddddddddd', 'ЛДСП жеткізуші ЖШС', 'ldsp');

insert into materials (id, name, unit, min_quantity) values
  ('99999999-9999-9999-9999-999999999999', 'ЛДСП 16мм ақ', 'парақ', 5);
insert into warehouses (id, name) values
  ('11111111-2222-3333-4444-555555555555', 'Негізгі қойма');
insert into warehouse_locations (id, warehouse_id, name) values
  ('22222222-3333-4444-5555-666666666666', '11111111-2222-3333-4444-555555555555', 'Сөре 1');

insert into clients (id, name, phone)
values ('cccccccc-cccc-cccc-cccc-cccccccccccc', 'Тест клиент', '+77011112233');
insert into orders (id, order_number, client_id, product_type, status, total_amount_tiyn)
values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'JU-PU-0001', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'Шкаф', 'in_progress', 100000000);
-- Order needs 10 units, but nothing is in stock yet — deliberately insufficient.
insert into material_reservations (order_id, material_id, quantity)
values ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '99999999-9999-9999-9999-999999999999', 10);

select is(
  (select materials_sufficient from get_production_queue() where order_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  false,
  'fixture: order starts material-insufficient (10 needed, 0 in stock)'
);

select is(
  (select (materials -> 0 ->> 'material_id')::uuid from get_order_production_detail('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa')),
  '99999999-9999-9999-9999-999999999999'::uuid,
  'requirement: Production integration — the superseded get_order_production_detail() now includes material_id in its materials array (needed so the UI can key get_pending_purchase_quantities() lookups), with every other field/security check unchanged'
);

-- ---------- as manager (purchases.read + .write only) ----------
set local "request.jwt.claims" to '{"sub": "33333333-3333-3333-3333-333333333333", "role": "authenticated"}';

select lives_ok(
  $$select create_purchase_order(
    'PO-0001', 'dddddddd-dddd-dddd-dddd-dddddddddddd',
    jsonb_build_array(jsonb_build_object(
      'material_id', '99999999-9999-9999-9999-999999999999',
      'quantity', 20, 'unit', 'парақ', 'unit_price_tiyn', 850000,
      'location_id', '22222222-3333-4444-5555-666666666666'
    ))
  )$$,
  'requirement: "Manager: Құру" — manager can create a draft PO'
);

select is(
  (select total_price_tiyn from purchase_order_items where purchase_order_id = (select id from purchase_orders where order_number = 'PO-0001')),
  17000000::bigint,
  'trigger: purchase_order_items.total_price_tiyn = quantity * unit_price_tiyn (20 * 850000)'
);

select is(
  (select total_amount_tiyn from purchase_orders where order_number = 'PO-0001'),
  17000000::bigint,
  'trigger: purchase_orders.total_amount_tiyn rolls up from its items (no delivery/vat/discount set)'
);

select throws_ok(
  $$select approve_purchase_order((select id from purchase_orders where order_number = 'PO-0001'))$$,
  '42501',
  'Бұл әрекетке рұқсатыңыз жоқ',
  'requirement: manager cannot approve (Бекіту) — purchases.approve only'
);

select throws_ok(
  $$select receive_purchase_order((select id from purchase_orders where order_number = 'PO-0001'))$$,
  '42501',
  'Бұл әрекетке рұқсатыңыз жоқ',
  'requirement: manager cannot receive (Қабылдау) — purchases.receive only'
);

-- ---------- as purchaser (read+write+approve+receive, no pay) ----------
set local "request.jwt.claims" to '{"sub": "22222222-2222-2222-2222-222222222222", "role": "authenticated"}';

select throws_ok(
  $$select receive_purchase_order((select id from purchase_orders where order_number = 'PO-0001'))$$,
  '23514',
  null,
  'requirement: a draft PO cannot be received directly — must be approved then delivered first'
);

select lives_ok(
  $$select approve_purchase_order((select id from purchase_orders where order_number = 'PO-0001'))$$,
  'requirement: "Purchaser: Толық сатып алу" — purchaser can approve (Бекіту)'
);

select throws_ok(
  $$select update_purchase_order(
    (select id from purchase_orders where order_number = 'PO-0001'),
    'dddddddd-dddd-dddd-dddd-dddddddddddd', '[]'::jsonb
  )$$,
  '42501',
  null,
  'requirement: an approved (non-draft) PO can no longer be edited (Өңдеу is draft-only)'
);

select is(
  (select pending_quantity from get_pending_purchase_quantities() where material_id = '99999999-9999-9999-9999-999999999999'),
  20::numeric,
  'requirement: Production integration — an approved PO''s quantity counts as "pending" stock'
);

select throws_ok(
  $$select receive_purchase_order((select id from purchase_orders where order_number = 'PO-0001'))$$,
  '23514',
  null,
  'requirement: an approved (not yet delivered) PO cannot be received directly'
);

select lives_ok(
  $$select mark_purchase_order_delivered((select id from purchase_orders where order_number = 'PO-0001'))$$,
  'requirement: "Жеткізілді" — purchaser can mark a PO as delivered by the supplier'
);

-- ---------- as warehouse (read + receive only) ----------
set local "request.jwt.claims" to '{"sub": "66666666-6666-6666-6666-666666666666", "role": "authenticated"}';

select throws_ok(
  $$select create_purchase_order('PO-0002', 'dddddddd-dddd-dddd-dddd-dddddddddddd', '[]'::jsonb)$$,
  '42501',
  'Бұл әрекетке рұқсатыңыз жоқ',
  'requirement: warehouse cannot create a PO (Қабылдау only)'
);

select lives_ok(
  $$select receive_purchase_order((select id from purchase_orders where order_number = 'PO-0001'))$$,
  'requirement: "Warehouse: Қабылдау" — warehouse can accept a delivered PO into stock'
);

select is(
  (select status from purchase_orders where order_number = 'PO-0001'),
  'received'::purchase_order_status,
  'the PO is now marked received'
);

select is(
  (select quantity from inventory_balances where material_id = '99999999-9999-9999-9999-999999999999' and location_id = '22222222-3333-4444-5555-666666666666'),
  20::numeric,
  'requirement: "Қойма қалдығын көбейту" — receiving increased the warehouse balance via the reused receive_materials() RPC'
);

select is(
  (select count(*)::int from inventory_batches where material_id = '99999999-9999-9999-9999-999999999999'),
  1,
  'requirement: "inventory_batches жасау" — a batch was created for traceability'
);

select is(
  (select batch_id is not null from purchase_order_items where purchase_order_id = (select id from purchase_orders where order_number = 'PO-0001')),
  true,
  'the purchase_order_item was linked back to the batch it became'
);

select is(
  (select materials_sufficient from get_production_queue() where order_id = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
  true,
  'requirement: "materials_sufficient автоматты жаңарсын" — Production''s own get_production_queue() (unchanged) now reports the order as sufficient, with zero edits to the Production migration'
);

select is(
  (select count(*)::int from supplier_invoices where purchase_order_id = (select id from purchase_orders where order_number = 'PO-0001')),
  1,
  'requirement: "Supplier Invoices" — receiving auto-created an invoice for the PO total'
);

select is(
  (select balance_tiyn from partners where id = 'dddddddd-dddd-dddd-dddd-dddddddddddd'),
  17000000::bigint,
  'requirement: "Қалған қарыз" — the supplier''s balance increased by the PO total (positive = we owe them)'
);

-- ---------- as accountant (read + pay only) ----------
set local "request.jwt.claims" to '{"sub": "55555555-5555-5555-5555-555555555555", "role": "authenticated"}';

select throws_ok(
  $$select approve_purchase_order((select id from purchase_orders where order_number = 'PO-0001'))$$,
  '42501',
  'Бұл әрекетке рұқсатыңыз жоқ',
  'requirement: accountant cannot approve a PO (Төлемдер only)'
);

select lives_ok(
  $$select record_supplier_payment(
    'test-key-0001', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 10000000,
    (select id from payment_methods where key = 'bank_transfer'),
    (select id from supplier_invoices where purchase_order_id = (select id from purchase_orders where order_number = 'PO-0001'))
  )$$,
  'requirement: "Жеткізушіге төлем" — accountant can record a partial supplier payment'
);

select is(
  (select balance_tiyn from partners where id = 'dddddddd-dddd-dddd-dddd-dddddddddddd'),
  7000000::bigint,
  'requirement: "Қалған қарыз" — the payment reduced the outstanding debt (17,000,000 - 10,000,000)'
);

select is(
  (select status from supplier_invoices where purchase_order_id = (select id from purchase_orders where order_number = 'PO-0001')),
  'partial'::supplier_invoice_status,
  'the invoice status updated to partial after a part-payment'
);

select is(
  (select count(*)::int from get_supplier_payments('dddddddd-dddd-dddd-dddd-dddddddddddd')),
  1,
  'requirement: Partners integration — "Payments көру" surfaces the payment on the supplier card'
);

select throws_ok(
  $$select record_supplier_payment(
    'test-key-0002', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 5000000,
    (select id from payment_methods where key = 'cash')
  )$$,
  null,
  null,
  'a repeated call with a new idempotency key for a fresh advance payment still succeeds'
);

select lives_ok(
  $$select reverse_supplier_payment(
    (select id from supplier_payments where idempotency_key = 'test-key-0002'), 'Қате енгізілді'
  )$$,
  'requirement: "Төлем тарихы" — a payment can be reversed (insert-only, not deleted)'
);

select is(
  (select balance_tiyn from partners where id = 'dddddddd-dddd-dddd-dddd-dddddddddddd'),
  7000000::bigint,
  'reversing the advance payment restores the balance to what it was before it'
);

-- ---------- as manager again (no purchases.pay) ----------
set local "request.jwt.claims" to '{"sub": "33333333-3333-3333-3333-333333333333", "role": "authenticated"}';

select throws_ok(
  $$select record_supplier_payment(
    'test-key-0003', 'dddddddd-dddd-dddd-dddd-dddddddddddd', 1000000,
    (select id from payment_methods where key = 'cash')
  )$$,
  '42501',
  'Бұл әрекетке рұқсатыңыз жоқ',
  'requirement: manager cannot record a supplier payment (Accountant-only)'
);

select is(
  (select count(*)::int from get_purchase_orders()),
  1,
  'requirement: manager (purchases.read) sees the purchase order list'
);

select * from finish();
rollback;
