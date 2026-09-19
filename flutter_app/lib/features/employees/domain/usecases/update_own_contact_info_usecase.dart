import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/employee_repository.dart';

class UpdateOwnContactInfoUseCase {
  const UpdateOwnContactInfoUseCase(this._repository);
  final EmployeeRepository _repository;

  Future<Either<Failure, Unit>> call({String? phone, String? avatarUrl}) {
    return _repository.updateOwnContactInfo(phone: phone, avatarUrl: avatarUrl);
  }
}
