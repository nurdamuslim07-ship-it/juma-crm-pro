import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/exceptions.dart';
import '../models/client_model.dart';

/// See DATABASE_SCHEMA.md "Clients & measurements". RLS on the
/// `clients` table (see supabase/migrations/20260713000012_rls_policies.sql)
/// already filters to `deleted_at is null` and gates read/write behind
/// the `clients.read`/`clients.write` permissions — this datasource
/// does not duplicate that logic, it just issues the query.
class ClientRemoteDataSource {
  ClientRemoteDataSource(this._client);
  final SupabaseClient _client;

  static const _selectWithManager =
      '*, responsible_manager:profiles!clients_responsible_manager_id_fkey(full_name)';

  Future<List<ClientModel>> getClients({String? searchQuery}) async {
    var query = _client.from('clients').select(_selectWithManager);

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim();
      query = query.or('name.ilike.%$q%,phone.ilike.%$q%');
    }

    final rows = await query.order('created_at', ascending: false);
    return (rows as List)
        .map((row) => ClientModel.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  Future<ClientModel> getClient(String id) async {
    final row = await _client
        .from('clients')
        .select(_selectWithManager)
        .eq('id', id)
        .single();
    return ClientModel.fromRow(row);
  }

  /// `companyId` is required (never optional/hardcoded) — the caller
  /// must resolve it from the authenticated user's own active company
  /// (see ClientFormSheet), never a literal. `clients_insert`'s RLS
  /// `with_check` compares this against `auth_company_id()` and
  /// rejects a forged value, but that only guards correctness, not
  /// completeness — the NOT NULL column has no default, so an omitted
  /// value fails the insert outright rather than silently scoping to
  /// the wrong company.
  Future<ClientModel> createClient(
    ClientModel client, {
    required String companyId,
  }) async {
    final userId = _client.auth.currentUser?.id;
    final payload = client.toWriteMap()
      ..['created_by'] = userId
      ..['company_id'] = companyId;

    final row = await _client
        .from('clients')
        .insert(payload)
        .select(_selectWithManager)
        .single();
    return ClientModel.fromRow(row);
  }

  Future<ClientModel> updateClient(ClientModel client) async {
    final row = await _client
        .from('clients')
        .update(client.toWriteMap())
        .eq('id', client.id)
        .select(_selectWithManager)
        .single();
    return ClientModel.fromRow(row);
  }

  /// Soft delete only — see DATABASE_SCHEMA.md's soft-delete rule and
  /// SECURITY_PLAN.md's "soft delete for important records". Goes
  /// through `soft_delete_client()` (SECURITY DEFINER RPC), not a raw
  /// `.update()` — a raw update fails RLS unconditionally, because
  /// `clients_select`'s policy requires `deleted_at is null` and
  /// Postgres's row-security engine requires the resulting row to
  /// still satisfy a SELECT policy for any UPDATE, regardless of the
  /// UPDATE policy's own WITH CHECK. The RPC bypasses this by running
  /// as the table owner and enforcing the same director-only gate
  /// that `clients_soft_delete_director`'s RLS policy already declares.
  Future<void> deleteClient(String id) async {
    try {
      await _client.rpc('soft_delete_client', params: {'p_client_id': id});
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    }
  }
}
