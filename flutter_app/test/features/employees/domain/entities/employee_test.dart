import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/employees/domain/entities/employee.dart';
import 'package:juma_ui_crm/features/employees/domain/value_objects/employee_role.dart';
import 'package:juma_ui_crm/features/employees/domain/value_objects/salary_type.dart';

Employee _employee({
  String userId = 'u1',
  SalaryType? salaryType,
  int? baseSalaryTiyn,
  double? bonusPercent,
}) {
  return Employee(
    id: 'e1',
    userId: userId,
    fullName: 'Асқар',
    email: 'askar@jumaui.kz',
    isActive: true,
    role: EmployeeRole.master,
    salaryType: salaryType,
    baseSalaryTiyn: baseSalaryTiyn,
    bonusPercent: bonusPercent,
    createdAt: DateTime(2026, 7, 13),
  );
}

void main() {
  group('Employee.hasFinancialAccess — requirement: "Жалақы және бонус ақпаратын '
      'тек директор көре алады"', () {
    test(
      'is false when get_employees() redacted salary fields (non-director caller)',
      () {
        final employee = _employee();
        expect(employee.hasFinancialAccess, isFalse);
      },
    );

    test(
      'is true only when the server actually sent salary data (director caller)',
      () {
        final employee = _employee(
          salaryType: SalaryType.fixed,
          baseSalaryTiyn: 50000000,
          bonusPercent: 5,
        );
        expect(employee.hasFinancialAccess, isTrue);
      },
    );
  });

  test(
    'equality is based on userId, matching the persisted profile identity',
    () {
      final a = _employee(userId: 'u1');
      final b = _employee(userId: 'u1', salaryType: SalaryType.percentage);
      expect(a, equals(b));
    },
  );

  test('different userIds are not equal', () {
    expect(_employee(userId: 'u1'), isNot(equals(_employee(userId: 'u2'))));
  });
}
