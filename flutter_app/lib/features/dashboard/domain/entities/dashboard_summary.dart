import 'package:flutter/foundation.dart';

/// Aggregate KPI numbers backing every role's dashboard tiles (see
/// master spec's Director/Manager/Workshop/Employee/Accountant
/// dashboard sections). One shape for all roles — the presentation
/// layer decides which tiles to render based on the current user's
/// roles (see ROLES_AND_PERMISSIONS.md); the numbers themselves are
/// already scoped server-side by RLS regardless of what the UI shows
/// (`dashboard_summary()` is SECURITY INVOKER, not DEFINER).
@immutable
class DashboardSummary {
  const DashboardSummary({
    required this.activeOrdersCount,
    required this.delayedOrdersCount,
    required this.completedThisMonthCount,
    required this.totalContractAmountTiyn,
    required this.paymentsReceivedTiyn,
    required this.expensesTiyn,
    required this.lowStockMaterialsCount,
    required this.upcomingDeliveriesCount,
    required this.myOpenTasksCount,
    required this.myTodayTasksCount,
  });

  final int activeOrdersCount;
  final int delayedOrdersCount;
  final int completedThisMonthCount;
  final int totalContractAmountTiyn;
  final int paymentsReceivedTiyn;
  final int expensesTiyn;
  final int lowStockMaterialsCount;
  final int upcomingDeliveriesCount;
  final int myOpenTasksCount;
  final int myTodayTasksCount;

  /// Remaining client debt across all visible orders — derived, not
  /// stored, per DATABASE_SCHEMA.md ("payment percentage is a
  /// query/view, not a stored column").
  int get remainingDebtTiyn =>
      (totalContractAmountTiyn - paymentsReceivedTiyn).clamp(0, 1 << 62);

  double get paymentProgressPercent => totalContractAmountTiyn == 0
      ? 0
      : (paymentsReceivedTiyn / totalContractAmountTiyn * 100).clamp(0, 100);
}
