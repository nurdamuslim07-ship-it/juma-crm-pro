import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/pending_company_request.dart';
import '../repositories/company_repository.dart';

class GetPendingCompanyRequestsUseCase {
  const GetPendingCompanyRequestsUseCase(this._repository);
  final CompanyRepository _repository;

  Future<Either<Failure, List<PendingCompanyRequest>>> call() {
    return _repository.getPendingCompanyRequests();
  }
}
