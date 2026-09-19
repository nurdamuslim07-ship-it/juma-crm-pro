import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/error/failures.dart';
import '../../domain/entities/analytics_summary.dart';
import '../../domain/entities/employee_kpi.dart';
import '../../domain/entities/top_client.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../datasources/analytics_remote_datasource.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  AnalyticsRepositoryImpl(this._remote);
  final AnalyticsRemoteDataSource _remote;

  @override
  Future<Either<Failure, AnalyticsSummary>> getSummary({
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final summary = await _remote.getSummary(start: start, end: end);
      return right(summary);
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, List<EmployeeKpi>>> getEmployeeKpis({
    required DateTime start,
    required DateTime end,
    String? employeeId,
  }) async {
    try {
      final kpis = await _remote.getEmployeeKpis(
        start: start,
        end: end,
        employeeId: employeeId,
      );
      return right(kpis);
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, List<TopClient>>> getTopClients({
    required DateTime start,
    required DateTime end,
    int limit = 10,
  }) async {
    try {
      final clients = await _remote.getTopClients(
        start: start,
        end: end,
        limit: limit,
      );
      return right(clients);
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  Failure _mapPostgrestError(PostgrestException e) {
    if (e.code == '42501') return PermissionFailure(e.message);
    return ServerFailure(e.message);
  }
}
