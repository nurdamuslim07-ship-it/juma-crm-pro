import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/audit_log_query.dart';
import '../models/audit_log_entry_model.dart';

/// Direct table reads under the existing `audit_logs_select_director`
/// RLS policy (20260713000025) — no RPC needed for the list itself
/// (see `get_audit_log_filters()`'s own migration header comment for
/// why one small RPC exists anyway, just for the filter dropdowns).
class AuditLogRemoteDataSource {
  AuditLogRemoteDataSource(this._client);
  final SupabaseClient _client;

  Future<(List<AuditLogEntryModel>, int)> getAuditLogs(
    AuditLogQuery query,
  ) async {
    var builder = _client.from('audit_logs').select('*, profiles(full_name)');

    if (query.from != null) {
      builder = builder.gte('created_at', query.from!.toIso8601String());
    }
    if (query.to != null) {
      builder = builder.lte('created_at', query.to!.toIso8601String());
    }
    if (query.actorId != null) {
      builder = builder.eq('actor_id', query.actorId!);
    }
    if (query.entityType != null) {
      builder = builder.eq('entity_type', query.entityType!);
    }
    if (query.action != null) {
      builder = builder.eq('action', query.action!);
    }
    if (query.search != null && query.search!.trim().isNotEmpty) {
      // PostgREST's `.or()` takes a raw filter string — strip
      // characters that would otherwise break its own `,()` syntax
      // rather than trusting free-typed search text inside it.
      final term = query.search!.replaceAll(RegExp(r'[,()]'), '').trim();
      if (term.isNotEmpty) {
        builder = builder.or('action.ilike.%$term%,entity_type.ilike.%$term%');
      }
    }

    final response = await builder
        .order('created_at', ascending: false)
        .range(query.offset, query.offset + query.limit - 1)
        .count(CountOption.exact);

    final entries = (response.data as List)
        .map((row) => AuditLogEntryModel.fromRow(row as Map<String, dynamic>))
        .toList();
    return (entries, response.count);
  }

  Future<(List<String>, List<String>)> getFilters() async {
    final rows = await _client.rpc('get_audit_log_filters');
    final row = (rows as List).first as Map<String, dynamic>;
    return (
      (row['modules'] as List).cast<String>(),
      (row['actions'] as List).cast<String>(),
    );
  }
}
