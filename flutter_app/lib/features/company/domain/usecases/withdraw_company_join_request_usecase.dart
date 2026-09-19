import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/company_repository.dart';

class WithdrawCompanyJoinRequestUseCase {
  const WithdrawCompanyJoinRequestUseCase(this._repository);
  final CompanyRepository _repository;

  Future<Either<Failure, Unit>> call(String requestId) {
    return _repository.withdrawCompanyJoinRequest(requestId);
  }
}
