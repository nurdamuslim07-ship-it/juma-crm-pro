import 'package:fpdart/fpdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/error/failures.dart';
import '../../domain/entities/audit_log_filters.dart';
import '../../domain/entities/audit_log_page.dart';
import '../../domain/entities/audit_log_query.dart';
import '../../domain/repositories/audit_log_repository.dart';
import '../datasources/audit_log_remote_datasource.dart';

class AuditLogRepositoryImpl implements AuditLogRepository {
  AuditLogRepositoryImpl(this._remote);
  final AuditLogRemoteDataSource _remote;

  @override
  Future<Either<Failure, AuditLogPage>> getAuditLogs(
    AuditLogQuery query,
  ) async {
    try {
      final (entries, total) = await _remote.getAuditLogs(query);
      return right(AuditLogPage(entries: entries, totalCount: total));
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  @override
  Future<Either<Failure, AuditLogFilters>> getFilters() async {
    try {
      final (modules, actions) = await _remote.getFilters();
      return right(AuditLogFilters(modules: modules, actions: actions));
    } on PostgrestException catch (e) {
      return left(_mapPostgrestError(e));
    } catch (e) {
      return left(mapUnexpectedError(e));
    }
  }

  Failure _mapPostgrestError(PostgrestException e) {
    if (e.code == '42501') return PermissionFailure(e.message);
    if (e.code == 'P0002' || e.code == 'PGRST116') {
      return NotFoundFailure(e.message);
    }
    if (e.code == '23514') return ValidationFailure(e.message);
    return ServerFailure(e.message);
  }
}
