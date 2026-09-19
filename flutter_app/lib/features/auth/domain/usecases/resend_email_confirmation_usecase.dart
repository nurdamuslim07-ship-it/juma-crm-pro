import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class ResendEmailConfirmationUseCase {
  const ResendEmailConfirmationUseCase(this._repository);
  final AuthRepository _repository;

  Future<Either<Failure, Unit>> call(String email) {
    return _repository.resendEmailConfirmation(email);
  }
}
