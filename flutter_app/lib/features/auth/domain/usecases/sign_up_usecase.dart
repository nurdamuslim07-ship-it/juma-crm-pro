import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/sign_up_outcome.dart';
import '../repositories/auth_repository.dart';

class SignUpUseCase {
  const SignUpUseCase(this._repository);
  final AuthRepository _repository;

  Future<Either<Failure, SignUpOutcome>> call({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) {
    return _repository.signUp(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
    );
  }
}
