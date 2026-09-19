import 'package:flutter/foundation.dart';

import '../../../employees/domain/value_objects/employee_role.dart';

/// See `get_employee_kpis()` in
/// supabase/migrations/20260713000019_analytics_module.sql. The
/// payments-recorded figures are wrapped in `coalesce(..., 0)` before
/// their per-row financial-or-own-row gated `case when ... then ... end`,
/// so — same reasoning as AnalyticsSummary — nullability alone
/// reliably signals whether the caller could see this row's
/// recorded-payments figures, not whether that employee simply
/// recorded nothing.
@immutable
class EmployeeKpi {
  const EmployeeKpi({
    required this.employeeId,
    required this.fullName,
    this.role,
    required this.ordersAssignedCount,
    required this.ordersCompletedCount,
    this.paymentsRecordedCount,
    this.paymentsRecordedAmountTiyn,
  });

  final String employeeId;
  final String fullName;
  final EmployeeRole? role;
  final int ordersAssignedCount;
  final int ordersCompletedCount;
  final int? paymentsRecordedCount;
  final int? paymentsRecordedAmountTiyn;

  bool get hasPaymentsFigures => paymentsRecordedCount != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployeeKpi &&
          runtimeType == other.runtimeType &&
          employeeId == other.employeeId;

  @override
  int get hashCode => employeeId.hashCode;
}
