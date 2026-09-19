import 'package:flutter/foundation.dart';

/// See `get_top_clients()` in
/// supabase/migrations/20260713000019_analytics_module.sql —
/// director/manager only (`analytics.read_sales`); the RPC returns an
/// empty set, not redacted rows, for anyone else.
@immutable
class TopClient {
  const TopClient({
    required this.clientId,
    required this.clientName,
    required this.ordersCount,
    required this.totalAmountTiyn,
  });

  final String clientId;
  final String clientName;
  final int ordersCount;
  final int totalAmountTiyn;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TopClient &&
          runtimeType == other.runtimeType &&
          clientId == other.clientId;

  @override
  int get hashCode => clientId.hashCode;
}
