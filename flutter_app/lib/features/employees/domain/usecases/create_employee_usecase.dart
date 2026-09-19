import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/employee_repository.dart';
import '../value_objects/employee_role.dart';
import '../value_objects/salary_type.dart';

class CreateEmployeeUseCase {
  const CreateEmployeeUseCase(this._repository);
  final EmployeeRepository _repository;

  Future<Either<Failure, String>> call({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    required EmployeeRole role,
    DateTime? hireDate,
    SalaryType salaryType = SalaryType.fixed,
    int baseSalaryTiyn = 0,
    double bonusPercent = 0,
    String? notes,
  }) {
    return _repository.createEmployee(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
      role: role,
      hireDate: hireDate,
      salaryType: salaryType,
      baseSalaryTiyn: baseSalaryTiyn,
      bonusPercent: bonusPercent,
      notes: notes,
    );
  }
}
