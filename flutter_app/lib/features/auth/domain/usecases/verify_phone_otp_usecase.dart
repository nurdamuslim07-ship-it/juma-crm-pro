import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class VerifyPhoneOtpUseCase {
  const VerifyPhoneOtpUseCase(this._repository);
  final AuthRepository _repository;

  Future<Either<Failure, AuthUser>> call({
    required String phone,
    required String token,
  }) {
    return _repository.verifyPhoneOtp(phone: phone, token: token);
  }
}
