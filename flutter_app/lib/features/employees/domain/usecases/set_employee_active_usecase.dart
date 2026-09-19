import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/employee_repository.dart';

class SetEmployeeActiveUseCase {
  const SetEmployeeActiveUseCase(this._repository);
  final EmployeeRepository _repository;

  Future<Either<Failure, Unit>> call(String userId, bool isActive) {
    return _repository.setEmployeeActive(userId, isActive);
  }
}
