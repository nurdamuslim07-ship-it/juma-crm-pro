# Order workflow, contracts and WhatsApp

## Current state

Migration 61 was applied and all three Edge Functions deployed after the user authorized startup. The rollback integration test passed. No WhatsApp message has been sent. A WhatsApp Business Platform account is not connected; dispatcher remains inactive without its credentials and worker secret.

## App flow

Order detail → «Кезеңдер және клиентпен байланыс».
- Stages: measurement, design agreement, contract, advance, cutting, edge banding, assembly, quality, delivery, installation, completed.
- Uses the existing production-stage RPC for corresponding workshop stages; workshop history updates the order journey. No payment ledger amounts are changed by choosing a stage.
- Client opt-in is recorded with its source/date/operator. Revocation cancels queued messages. Changes without opt-in are recorded as skipped, never retrospectively sent.
- Contract editor prefills company, client, product and amount. Payment, deadline and warranty terms must be supplied. PDF is a draft, not a signed document. Immutable snapshots/files preserve each saved version. Review the PDF then approve that version for the WhatsApp queue; repeated approval does not duplicate the message.
- Private client link shows only order number, product, stage, planned date and approved contract links. Token expires after 90 days; regenerating revokes the previous token. Possession of this link grants access, so share it only with the intended client. Files use 5-minute signed URLs. Internal notes, phone numbers and the broader customer database are not exposed.

## Deployment after approval

1. Apply only `supabase/migrations/20260919000061_order_workflow_communications.sql` to the intended project, then run `supabase/tests/order_workflow_communications_test.sql` (rollback-only, dedicated development account). Existing remote migration history is empty; do not blindly push all migrations.
2. Deploy `order-tracking --no-verify-jwt` (bearer token validation inside handler).
3. Configure and deploy `whatsapp-dispatch --no-verify-jwt` (dedicated worker secret), `whatsapp-webhook --no-verify-jwt` (Meta HMAC verification). Never put secrets in Flutter or git.
4. Dispatcher environment: `WHATSAPP_WORKER_SECRET`, `WHATSAPP_COMPANY_ID`, `WHATSAPP_PHONE_NUMBER_ID`, `WHATSAPP_ACCESS_TOKEN`, `META_GRAPH_VERSION`, `WHATSAPP_STAGE_TEMPLATE`, `WHATSAPP_CONTRACT_TEMPLATE`, `WHATSAPP_TEMPLATE_LANGUAGE`. One deployment currently serves ONE explicitly configured company; additional tenants need isolated credentials/routing before enabling sending.
5. Webhook environment: `META_APP_SECRET`, `WHATSAPP_VERIFY_TOKEN`, same company/phone IDs. Configure Meta message-status subscription.
6. Approve utility templates in Meta. Stage template body has three text parameters: client name, order number, localized current stage. Contract template has a document header plus one body parameter (order number). Text describes the **current** stage, not completion of a stage. Match the configured language exactly.
7. Configure a scheduler to POST to the dispatcher using the worker secret. Each call claims one message atomically. Run only after account/template/consent configuration has been tested with the intended recipient.

## Delivery semantics and limits

- API acceptance is shown as sent; delivered/read arrive through verified webhooks.
- No automatic retries of ambiguous network POSTs: `unknown` requires provider reconciliation, preventing blind duplicate sends. Workers interrupted for ten minutes become unknown. Old queued messages expire after 48 hours, preventing a backlog blast on first connection.
- Definite provider failures remain failed for operator investigation. UI currently displays statuses; retry/reconciliation tooling is not implemented.
- Status callback arriving before the send response stores the provider ID may require reconciliation; do not interpret sent as delivered.
- Consent is checked when queued/claimed and immediately before the provider request. Already submitted requests cannot be recalled by subsequently revoking consent.
- Saved PDF uploads can remain orphaned if metadata save fails; do not delete on an ambiguous response as the server may have committed.
- Client link has no production photo feed yet; production photos remain in the internal workshop screen.

## Local checks

`flutter analyze --no-pub`
`flutter test --no-pub test/order_workflow_test.dart`
`node --test supabase/functions/tests/communications.test.mjs`

Node tests execute handlers with mocked environment/client and verify authorization, unconfigured integration behavior, webhook signature/verification and malformed tracking-token rejection. They do not replace Deno/deployed-provider integration tests.
