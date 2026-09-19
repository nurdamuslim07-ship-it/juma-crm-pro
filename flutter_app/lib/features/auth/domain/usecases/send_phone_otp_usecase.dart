import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class SendPhoneOtpUseCase {
  const SendPhoneOtpUseCase(this._repository);
  final AuthRepository _repository;

  Future<Either<Failure, Unit>> call(String phone) {
    return _repository.sendPhoneVerificationOtp(phone);
  }
}
