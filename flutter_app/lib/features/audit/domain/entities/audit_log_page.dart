import 'package:flutter/foundation.dart';

import 'audit_log_entry.dart';

/// One page of audit log results plus the total row count matching
/// the current filters (`totalCount` ignores `offset`/`limit` but
/// respects every other filter — see AuditLogRemoteDataSource, which
/// uses PostgREST's `.count(CountOption.exact)` for this).
@immutable
class AuditLogPage {
  const AuditLogPage({required this.entries, required this.totalCount});

  final List<AuditLogEntry> entries;
  final int totalCount;
}
