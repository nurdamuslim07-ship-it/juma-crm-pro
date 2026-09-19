import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/analytics_summary.dart';
import '../entities/employee_kpi.dart';
import '../entities/top_client.dart';

abstract class AnalyticsRepository {
  /// Routed through `get_analytics_summary()` — see that RPC's doc
  /// comment for exactly which fields come back null depending on the
  /// caller's `analytics.read_sales`/`analytics.read_financial`
  /// permissions.
  Future<Either<Failure, AnalyticsSummary>> getSummary({
    required DateTime start,
    required DateTime end,
  });

  /// Self-only unless the caller holds `analytics.read_all_kpi` (see
  /// `get_employee_kpis()`) — [employeeId] is silently ignored server-side
  /// for callers without that permission.
  Future<Either<Failure, List<EmployeeKpi>>> getEmployeeKpis({
    required DateTime start,
    required DateTime end,
    String? employeeId,
  });

  /// director/manager only (`analytics.read_sales`) — see
  /// `get_top_clients()`; an empty list for anyone else.
  Future<Either<Failure, List<TopClient>>> getTopClients({
    required DateTime start,
    required DateTime end,
    int limit = 10,
  });
}
