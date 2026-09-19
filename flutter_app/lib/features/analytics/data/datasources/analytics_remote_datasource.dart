import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/analytics_summary_model.dart';
import '../models/employee_kpi_model.dart';
import '../models/top_client_model.dart';

/// See supabase/migrations/20260713000019_analytics_module.sql —
/// every method here is a read-only RPC call; none of them ever
/// throws for a missing `analytics.*` permission (the RPCs redact
/// instead — see this module's README section), so there is no
/// permission-error translation to do here, unlike Employees/Partners.
class AnalyticsRemoteDataSource {
  AnalyticsRemoteDataSource(this._client);
  final SupabaseClient _client;

  String _dateParam(DateTime date) => date.toIso8601String().substring(0, 10);

  Future<AnalyticsSummaryModel> getSummary({
    required DateTime start,
    required DateTime end,
  }) async {
    final rows = await _client.rpc(
      'get_analytics_summary',
      params: {'p_start': _dateParam(start), 'p_end': _dateParam(end)},
    );
    final list = rows as List;
    if (list.isEmpty) return const AnalyticsSummaryModel();
    return AnalyticsSummaryModel.fromRow(list.first as Map<String, dynamic>);
  }

  Future<List<EmployeeKpiModel>> getEmployeeKpis({
    required DateTime start,
    required DateTime end,
    String? employeeId,
  }) async {
    final rows = await _client.rpc(
      'get_employee_kpis',
      params: {
        'p_start': _dateParam(start),
        'p_end': _dateParam(end),
        'p_employee_id': employeeId,
      },
    );
    return (rows as List)
        .map((row) => EmployeeKpiModel.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<TopClientModel>> getTopClients({
    required DateTime start,
    required DateTime end,
    int limit = 10,
  }) async {
    final rows = await _client.rpc(
      'get_top_clients',
      params: {
        'p_start': _dateParam(start),
        'p_end': _dateParam(end),
        'p_limit': limit,
      },
    );
    return (rows as List)
        .map((row) => TopClientModel.fromRow(row as Map<String, dynamic>))
        .toList();
  }
}
