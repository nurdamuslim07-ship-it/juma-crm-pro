import 'package:flutter/foundation.dart';

/// Backs the Module/Action filter dropdowns — see
/// `get_audit_log_filters()` in
/// supabase/migrations/20260713000040_audit_log_filters_rpc.sql.
@immutable
class AuditLogFilters {
  const AuditLogFilters({required this.modules, required this.actions});

  final List<String> modules;
  final List<String> actions;
}
