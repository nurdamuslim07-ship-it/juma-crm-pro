import 'package:flutter/foundation.dart';

/// Filter/pagination parameters for `AuditLogRepository.getAuditLogs()`
/// — bundled into one object since there are 7 independent knobs
/// (date range, employee, module, action, search, offset, limit).
@immutable
class AuditLogQuery {
  const AuditLogQuery({
    this.from,
    this.to,
    this.actorId,
    this.entityType,
    this.action,
    this.search,
    this.offset = 0,
    this.limit = 20,
  });

  final DateTime? from;
  final DateTime? to;
  final String? actorId;
  final String? entityType;
  final String? action;
  final String? search;
  final int offset;
  final int limit;

  AuditLogQuery copyWith({
    DateTime? from,
    bool clearFrom = false,
    DateTime? to,
    bool clearTo = false,
    String? actorId,
    bool clearActorId = false,
    String? entityType,
    bool clearEntityType = false,
    String? action,
    bool clearAction = false,
    String? search,
    bool clearSearch = false,
    int? offset,
  }) {
    return AuditLogQuery(
      from: clearFrom ? null : (from ?? this.from),
      to: clearTo ? null : (to ?? this.to),
      actorId: clearActorId ? null : (actorId ?? this.actorId),
      entityType: clearEntityType ? null : (entityType ?? this.entityType),
      action: clearAction ? null : (action ?? this.action),
      search: clearSearch ? null : (search ?? this.search),
      offset: offset ?? this.offset,
      limit: limit,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditLogQuery &&
          runtimeType == other.runtimeType &&
          from == other.from &&
          to == other.to &&
          actorId == other.actorId &&
          entityType == other.entityType &&
          action == other.action &&
          search == other.search &&
          offset == other.offset &&
          limit == other.limit;

  @override
  int get hashCode =>
      Object.hash(from, to, actorId, entityType, action, search, offset, limit);
}
