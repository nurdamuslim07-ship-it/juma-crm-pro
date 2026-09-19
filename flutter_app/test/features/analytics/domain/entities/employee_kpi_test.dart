import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/analytics/domain/entities/employee_kpi.dart';
import 'package:juma_ui_crm/features/employees/domain/value_objects/employee_role.dart';

EmployeeKpi _kpi({
  String employeeId = 'e1',
  int? paymentsRecordedCount,
  int? paymentsRecordedAmountTiyn,
}) {
  return EmployeeKpi(
    employeeId: employeeId,
    fullName: 'Асқар Жұмабеков',
    role: EmployeeRole.master,
    ordersAssignedCount: 3,
    ordersCompletedCount: 2,
    paymentsRecordedCount: paymentsRecordedCount,
    paymentsRecordedAmountTiyn: paymentsRecordedAmountTiyn,
  );
}

void main() {
  group('EmployeeKpi.hasPaymentsFigures — reflects the per-row financial '
      'redaction ("analytics.read_financial OR own row"), not whether '
      'that employee simply recorded zero payments', () {
    test('is false when the row was redacted (both fields null)', () {
      expect(_kpi().hasPaymentsFigures, isFalse);
    });

    test("is true even with a zero recorded amount, as long as the "
        "caller could see this row's financial figures", () {
      final kpi = _kpi(paymentsRecordedCount: 0, paymentsRecordedAmountTiyn: 0);
      expect(kpi.hasPaymentsFigures, isTrue);
    });
  });

  test('equality is based on employeeId only', () {
    final a = _kpi(employeeId: 'e1');
    final b = _kpi(employeeId: 'e1', paymentsRecordedCount: 5);
    expect(a, equals(b));
  });

  test('different employeeIds are not equal', () {
    expect(_kpi(employeeId: 'e1'), isNot(equals(_kpi(employeeId: 'e2'))));
  });
}
