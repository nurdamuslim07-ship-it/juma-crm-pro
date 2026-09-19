import '../../../employees/domain/value_objects/employee_role.dart';
import '../../domain/entities/employee_kpi.dart';

class EmployeeKpiModel extends EmployeeKpi {
  const EmployeeKpiModel({
    required super.employeeId,
    required super.fullName,
    super.role,
    required super.ordersAssignedCount,
    required super.ordersCompletedCount,
    super.paymentsRecordedCount,
    super.paymentsRecordedAmountTiyn,
  });

  factory EmployeeKpiModel.fromRow(Map<String, dynamic> row) {
    return EmployeeKpiModel(
      employeeId: row['employee_id'] as String,
      fullName: (row['full_name'] as String?) ?? '',
      role: row['role_key'] != null
          ? EmployeeRole.fromDbKey(row['role_key'] as String)
          : null,
      ordersAssignedCount: (row['orders_assigned_count'] as num?)?.toInt() ?? 0,
      ordersCompletedCount:
          (row['orders_completed_count'] as num?)?.toInt() ?? 0,
      paymentsRecordedCount: (row['payments_recorded_count'] as num?)?.toInt(),
      paymentsRecordedAmountTiyn: (row['payments_recorded_amount_tiyn'] as num?)
          ?.toInt(),
    );
  }
}
