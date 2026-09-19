import '../../domain/entities/dashboard_summary.dart';

class DashboardSummaryModel extends DashboardSummary {
  const DashboardSummaryModel({
    required super.activeOrdersCount,
    required super.delayedOrdersCount,
    required super.completedThisMonthCount,
    required super.totalContractAmountTiyn,
    required super.paymentsReceivedTiyn,
    required super.expensesTiyn,
    required super.lowStockMaterialsCount,
    required super.upcomingDeliveriesCount,
    required super.myOpenTasksCount,
    required super.myTodayTasksCount,
  });

  /// Parses the single row returned by the `dashboard_summary()`
  /// Postgres RPC (see supabase/migrations/20260713000014_dashboard_summary.sql).
  factory DashboardSummaryModel.fromRow(Map<String, dynamic> row) {
    int asInt(String key) => (row[key] as num?)?.toInt() ?? 0;
    return DashboardSummaryModel(
      activeOrdersCount: asInt('active_orders_count'),
      delayedOrdersCount: asInt('delayed_orders_count'),
      completedThisMonthCount: asInt('completed_this_month_count'),
      totalContractAmountTiyn: asInt('total_contract_amount_tiyn'),
      paymentsReceivedTiyn: asInt('payments_received_tiyn'),
      expensesTiyn: asInt('expenses_tiyn'),
      lowStockMaterialsCount: asInt('low_stock_materials_count'),
      upcomingDeliveriesCount: asInt('upcoming_deliveries_count'),
      myOpenTasksCount: asInt('my_open_tasks_count'),
      myTodayTasksCount: asInt('my_today_tasks_count'),
    );
  }

  static const empty = DashboardSummaryModel(
    activeOrdersCount: 0,
    delayedOrdersCount: 0,
    completedThisMonthCount: 0,
    totalContractAmountTiyn: 0,
    paymentsReceivedTiyn: 0,
    expensesTiyn: 0,
    lowStockMaterialsCount: 0,
    upcomingDeliveriesCount: 0,
    myOpenTasksCount: 0,
    myTodayTasksCount: 0,
  );
}
