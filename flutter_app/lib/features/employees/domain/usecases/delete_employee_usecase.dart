import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/employee_repository.dart';

class DeleteEmployeeUseCase {
  const DeleteEmployeeUseCase(this._repository);
  final EmployeeRepository _repository;

  Future<Either<Failure, Unit>> call(String userId) =>
      _repository.deleteEmployee(userId);
}
