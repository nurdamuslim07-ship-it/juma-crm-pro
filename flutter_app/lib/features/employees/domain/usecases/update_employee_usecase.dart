import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../repositories/employee_repository.dart';
import '../value_objects/employee_role.dart';
import '../value_objects/salary_type.dart';

class UpdateEmployeeUseCase {
  const UpdateEmployeeUseCase(this._repository);
  final EmployeeRepository _repository;

  Future<Either<Failure, Unit>> call({
    required String userId,
    required String fullName,
    String? phone,
    required EmployeeRole role,
    DateTime? hireDate,
    required SalaryType salaryType,
    required int baseSalaryTiyn,
    required double bonusPercent,
    String? notes,
  }) {
    return _repository.updateEmployee(
      userId: userId,
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
