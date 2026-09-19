import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/audit_log_page.dart';
import '../entities/audit_log_query.dart';
import '../repositories/audit_log_repository.dart';

class GetAuditLogsUseCase {
  const GetAuditLogsUseCase(this._repository);
  final AuditLogRepository _repository;

  Future<Either<Failure, AuditLogPage>> call(AuditLogQuery query) {
    return _repository.getAuditLogs(query);
  }
}
