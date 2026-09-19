import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/company_repository.dart';

class RejectCompanyJoinRequestUseCase {
  const RejectCompanyJoinRequestUseCase(this._repository);
  final CompanyRepository _repository;

  Future<Either<Failure, Unit>> call(String requestId, {String? reason}) {
    return _repository.rejectCompanyJoinRequest(requestId, reason: reason);
  }
}
