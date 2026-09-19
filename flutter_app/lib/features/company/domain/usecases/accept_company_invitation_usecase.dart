import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/company_repository.dart';

class AcceptCompanyInvitationUseCase {
  const AcceptCompanyInvitationUseCase(this._repository);
  final CompanyRepository _repository;

  Future<Either<Failure, String>> call({
    required String code,
    String? message,
  }) {
    return _repository.acceptCompanyInvitation(code: code, message: message);
  }
}
