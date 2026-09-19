import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/company_repository.dart';
import '../value_objects/company_role.dart';

class ApproveCompanyJoinRequestUseCase {
  const ApproveCompanyJoinRequestUseCase(this._repository);
  final CompanyRepository _repository;

  Future<Either<Failure, Unit>> call(
    String requestId, {
    CompanyRole? overrideRole,
  }) {
    return _repository.approveCompanyJoinRequest(
      requestId,
      overrideRole: overrideRole,
    );
  }
}
