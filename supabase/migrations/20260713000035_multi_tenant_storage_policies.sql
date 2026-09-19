-- Multi-tenant SaaS conversion — Stage 1d, part 9: Storage bucket
-- policies.
--
-- No Flutter changes are needed for this: every one of the 4 buckets
-- already uploads to a `{entity_id}/{timestamp}-{filename}` path
-- (confirmed directly against the Flutter datasources) —
-- `avatars`/`receipts` use the uploader's own `auth.uid()` as the
-- first folder segment, `partner-documents`/`order-photos` use
-- `partner_id`/`order_id` respectively. Every policy below joins that
-- existing first segment back to the owning row's `company_id`,
-- compared via text (not cast to uuid) so a malformed path segment
-- fails the check rather than raising a cast error — same defensive
-- style as the pre-existing `(storage.foldername(name))[1] = auth.uid()::text`
-- comparison in `avatars_upload_own`/`avatars_update_own` (both of
-- which were already correctly scoped to the caller's own uid and
-- need no change here).

-- ---------- avatars ----------
-- Read stays public by design (see 20260713000017's own comment —
-- avatars are shown throughout the UI, not sensitive). Self-upload/
-- update are already scoped to the caller's own uid folder, which is
-- inherently company-safe (a user can never write to another user's
-- folder regardless of tenant). Only the director bypass needs a
-- company check — today it lets ANY director manage ANY company's
-- avatar.
drop policy if exists "avatars_director_manage" on storage.objects;
create policy "avatars_director_manage"
  on storage.objects for all
  using (
    bucket_id = 'avatars' and auth_is_director()
    and (
      select company_id from profiles where id::text = (storage.foldername(name))[1]
    ) = auth_company_id()
  )
  with check (
    bucket_id = 'avatars' and auth_is_director()
    and (
      select company_id from profiles where id::text = (storage.foldername(name))[1]
    ) = auth_company_id()
  );

-- ---------- receipts ----------
-- Previously permission-only with NO path check at all — any user
-- holding payments.read/.write in their OWN company could read/upload
-- to any OTHER company's receipts, since nothing tied the object to a
-- tenant. Read/delete now also require the uploader (folder segment)
-- to belong to the caller's own company; upload is additionally
-- scoped to the caller's own uid folder (same pattern as avatars),
-- which no existing Flutter call site violates (it already uploads to
-- its own auth.uid()'s folder).
drop policy if exists "receipts_read_with_payments_permission" on storage.objects;
create policy "receipts_read_with_payments_permission"
  on storage.objects for select
  using (
    bucket_id = 'receipts' and auth_has_permission('payments.read')
    and (
      select company_id from profiles where id::text = (storage.foldername(name))[1]
    ) = auth_company_id()
  );

drop policy if exists "receipts_upload_with_payments_permission" on storage.objects;
create policy "receipts_upload_with_payments_permission"
  on storage.objects for insert
  with check (
    bucket_id = 'receipts' and auth_has_permission('payments.write')
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "receipts_delete_director" on storage.objects;
create policy "receipts_delete_director"
  on storage.objects for delete
  using (
    bucket_id = 'receipts' and auth_is_director()
    and (
      select company_id from profiles where id::text = (storage.foldername(name))[1]
    ) = auth_company_id()
  );

-- ---------- partner-documents ----------
-- Previously permission-only with no path check — any user holding
-- partners.read_extended/.read_financial/.write in their own company
-- could read/upload/delete another company's supplier documents.
drop policy if exists "partner_documents_bucket_read" on storage.objects;
create policy "partner_documents_bucket_read"
  on storage.objects for select
  using (
    bucket_id = 'partner-documents'
    and (
      auth_has_permission('partners.read_extended')
      or auth_has_permission('partners.read_financial')
    )
    and (
      select company_id from partners where id::text = (storage.foldername(name))[1]
    ) = auth_company_id()
  );

drop policy if exists "partner_documents_bucket_upload" on storage.objects;
create policy "partner_documents_bucket_upload"
  on storage.objects for insert
  with check (
    bucket_id = 'partner-documents' and auth_has_permission('partners.write')
    and (
      select company_id from partners where id::text = (storage.foldername(name))[1]
    ) = auth_company_id()
  );

drop policy if exists "partner_documents_bucket_delete" on storage.objects;
create policy "partner_documents_bucket_delete"
  on storage.objects for delete
  using (
    bucket_id = 'partner-documents' and auth_has_permission('partners.write')
    and (
      select company_id from partners where id::text = (storage.foldername(name))[1]
    ) = auth_company_id()
  );

-- ---------- order-photos ----------
-- Previously permission-only with no path check — any user holding
-- orders.read/.write/production.write in their own company could
-- read/upload/delete another company's order photos.
drop policy if exists "order_photos_bucket_read" on storage.objects;
create policy "order_photos_bucket_read"
  on storage.objects for select
  using (
    bucket_id = 'order-photos' and auth_has_permission('orders.read')
    and (
      select company_id from orders where id::text = (storage.foldername(name))[1]
    ) = auth_company_id()
  );

drop policy if exists "order_photos_bucket_write" on storage.objects;
create policy "order_photos_bucket_write"
  on storage.objects for insert
  with check (
    bucket_id = 'order-photos'
    and (auth_has_permission('orders.write') or auth_has_permission('production.write'))
    and (
      select company_id from orders where id::text = (storage.foldername(name))[1]
    ) = auth_company_id()
  );

drop policy if exists "order_photos_bucket_delete" on storage.objects;
create policy "order_photos_bucket_delete"
  on storage.objects for delete
  using (
    bucket_id = 'order-photos'
    and (auth_has_permission('orders.write') or auth_has_permission('production.write'))
    and (
      select company_id from orders where id::text = (storage.foldername(name))[1]
    ) = auth_company_id()
  );
