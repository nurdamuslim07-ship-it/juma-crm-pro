import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class SignInUseCase {
  const SignInUseCase(this._repository);
  final AuthRepository _repository;

  Future<Either<Failure, AuthUser>> call({
    required String email,
    required String password,
  }) {
    return _repository.signInWithPassword(email: email, password: password);
  }
}
