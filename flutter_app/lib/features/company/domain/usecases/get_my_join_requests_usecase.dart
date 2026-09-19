import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/company_join_request.dart';
import '../repositories/company_repository.dart';

class GetMyJoinRequestsUseCase {
  const GetMyJoinRequestsUseCase(this._repository);
  final CompanyRepository _repository;

  Future<Either<Failure, List<CompanyJoinRequest>>> call() {
    return _repository.getMyJoinRequests();
  }
}
