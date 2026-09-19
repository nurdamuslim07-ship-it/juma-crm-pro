import 'package:flutter/foundation.dart';

/// Mirrors one row of `audit_logs` (see
/// supabase/migrations/20260713000011_system.sql), joined with the
/// actor's `full_name`. `before`/`after` are whatever JSON the writing
/// RPC recorded — no fixed shape, since different mutations audit
/// different fields (see AuditLogDetailScreen, which just pretty-
/// prints whatever is there).
@immutable
class AuditLogEntry {
  const AuditLogEntry({
    required this.id,
    this.actorId,
    this.actorName,
    required this.action,
    required this.entityType,
    this.entityId,
    this.before,
    this.after,
    required this.createdAt,
  });

  final String id;
  final String? actorId;
  final String? actorName;
  final String action;
  final String entityType;
  final String? entityId;
  final Map<String, dynamic>? before;
  final Map<String, dynamic>? after;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditLogEntry &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
