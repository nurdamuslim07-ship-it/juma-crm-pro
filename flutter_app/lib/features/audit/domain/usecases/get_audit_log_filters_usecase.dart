import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/audit_log_filters.dart';
import '../repositories/audit_log_repository.dart';

class GetAuditLogFiltersUseCase {
  const GetAuditLogFiltersUseCase(this._repository);
  final AuditLogRepository _repository;

  Future<Either<Failure, AuditLogFilters>> call() {
    return _repository.getFilters();
  }
}
