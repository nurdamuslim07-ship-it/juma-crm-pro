import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/company_repository.dart';
import '../value_objects/company_role.dart';

class RequestToJoinCompanyUseCase {
  const RequestToJoinCompanyUseCase(this._repository);
  final CompanyRepository _repository;

  Future<Either<Failure, String>> call({
    required String companyCode,
    required CompanyRole requestedRole,
    String? message,
  }) {
    return _repository.requestToJoinCompany(
      companyCode: companyCode,
      requestedRole: requestedRole,
      message: message,
    );
  }
}
