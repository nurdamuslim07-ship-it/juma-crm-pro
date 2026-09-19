import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/supabase_provider.dart';

/// Builds a `Provider.autoDispose<void>` that subscribes to Postgres
/// Changes for [table] and calls [onChange] on every insert/update/
/// delete — the shared building block behind every "realtime instead
/// of polling" provider from Stage 4 Part 1 (see
/// supabase/migrations/20260713000039_realtime_publication.sql for
/// exactly which tables are actually subscribable — Realtime enforces
/// the same RLS/grants a normal query would, so tables with all direct
/// grants revoked, like `employees`/`company_join_requests`, are
/// proxied through `profiles` instead, never subscribed to directly).
///
/// Deliberately hands back no row data — every consumer already has a
/// working `FutureProvider`-based fetch; this only decides WHEN to
/// call `ref.invalidate` on it, so existing list/detail providers
/// don't need to change shape at all. A screen activates the
/// subscription simply by `ref.watch()`-ing the concrete provider
/// built from this helper — `autoDispose` means it tears down the
/// moment nothing is watching it anymore, the same lifecycle every
/// other list provider in this app already has.
ProviderBase<void> tableRealtimeProvider(
  String table,
  void Function(Ref ref) onChange,
) {
  return Provider.autoDispose<void>((ref) {
    final client = ref.watch(supabaseClientProvider);
    final channel = client.channel('public:$table');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: table,
      callback: (payload) => onChange(ref),
    );
    channel.subscribe();
    ref.onDispose(() {
      client.removeChannel(channel);
    });
  });
}
