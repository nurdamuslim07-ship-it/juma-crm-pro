import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class SignOutUseCase {
  const SignOutUseCase(this._repository);
  final AuthRepository _repository;

  Future<Either<Failure, Unit>> call({bool allDevices = false}) {
    return allDevices ? _repository.signOutAllDevices() : _repository.signOut();
  }
}
