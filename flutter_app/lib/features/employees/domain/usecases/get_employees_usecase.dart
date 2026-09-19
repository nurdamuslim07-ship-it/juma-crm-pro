import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../entities/employee.dart';
import '../repositories/employee_repository.dart';
import '../value_objects/employee_role.dart';

class GetEmployeesUseCase {
  const GetEmployeesUseCase(this._repository);
  final EmployeeRepository _repository;

  Future<Either<Failure, List<Employee>>> call({
    String? searchQuery,
    EmployeeRole? roleFilter,
    bool? activeFilter,
  }) {
    return _repository.getEmployees(
      searchQuery: searchQuery,
      roleFilter: roleFilter,
      activeFilter: activeFilter,
    );
  }
}
