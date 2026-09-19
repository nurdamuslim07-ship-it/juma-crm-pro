import '../../domain/entities/employee.dart';
import '../../domain/value_objects/employee_role.dart';
import '../../domain/value_objects/salary_type.dart';

class EmployeeModel extends Employee {
  const EmployeeModel({
    required super.id,
    required super.userId,
    required super.fullName,
    super.phone,
    required super.email,
    super.avatarUrl,
    required super.isActive,
    super.hireDate,
    super.salaryType,
    super.baseSalaryTiyn,
    super.bonusPercent,
    super.notes,
    super.role,
    required super.createdAt,
  });

  /// Parses one row of `get_employees()`'s result set — see that
  /// RPC's definition for exactly which columns arrive `null` and why
  /// ([Employee.hasFinancialAccess]'s doc comment explains the same
  /// thing from the Dart side).
  factory EmployeeModel.fromRow(Map<String, dynamic> row) {
    return EmployeeModel(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      fullName: (row['full_name'] as String?) ?? '',
      phone: row['phone'] as String?,
      email: (row['email'] as String?) ?? '',
      avatarUrl: row['avatar_url'] as String?,
      isActive: (row['is_active'] as bool?) ?? true,
      hireDate: row['hire_date'] != null
          ? DateTime.parse(row['hire_date'] as String)
          : null,
      salaryType: row['salary_type'] != null
          ? SalaryType.fromDbKey(row['salary_type'] as String)
          : null,
      baseSalaryTiyn: (row['base_salary_tiyn'] as num?)?.toInt(),
      bonusPercent: (row['bonus_percent'] as num?)?.toDouble(),
      notes: row['notes'] as String?,
      role: row['role_key'] != null
          ? EmployeeRole.fromDbKey(row['role_key'] as String)
          : null,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
