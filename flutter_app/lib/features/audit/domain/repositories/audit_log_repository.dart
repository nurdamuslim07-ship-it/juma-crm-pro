import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/audit_log_filters.dart';
import '../entities/audit_log_page.dart';
import '../entities/audit_log_query.dart';

/// Director-only (see `audit_logs_select_director` RLS policy,
/// 20260713000025) and company-scoped by that same policy — never a
/// client-supplied `company_id` parameter here, same rule as
/// everywhere else in this schema.
abstract class AuditLogRepository {
  Future<Either<Failure, AuditLogPage>> getAuditLogs(AuditLogQuery query);

  /// Populates the Module/Action filter dropdowns.
  Future<Either<Failure, AuditLogFilters>> getFilters();
}
