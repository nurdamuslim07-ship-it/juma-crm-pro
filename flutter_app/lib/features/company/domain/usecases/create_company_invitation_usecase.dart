import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/company_invitation.dart';
import '../repositories/company_repository.dart';
import '../value_objects/company_role.dart';

class CreateCompanyInvitationUseCase {
  const CreateCompanyInvitationUseCase(this._repository);
  final CompanyRepository _repository;

  Future<Either<Failure, CompanyInvitation>> call({
    required CompanyRole role,
    int maxUses = 1,
    int expiresInHours = 168,
  }) {
    return _repository.createCompanyInvitation(
      role: role,
      maxUses: maxUses,
      expiresInHours: expiresInHours,
    );
  }
}
