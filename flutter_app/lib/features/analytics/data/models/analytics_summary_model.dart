import '../../../orders/domain/value_objects/order_status.dart';
import '../../../payments/domain/value_objects/payment_method.dart';
import '../../domain/entities/analytics_summary.dart';
import '../../domain/entities/payment_method_stat.dart';

class AnalyticsSummaryModel extends AnalyticsSummary {
  const AnalyticsSummaryModel({
    super.turnoverTiyn,
    super.ordersCount,
    super.ordersByStatus,
    super.installedCount,
    super.newClientsCount,
    super.avgOrderAmountTiyn,
    super.paymentsReceivedTiyn,
    super.remainingDebtTiyn,
    super.paymentMethodStats,
  });

  /// Parses `get_analytics_summary()`'s single-row result — see that
  /// RPC's doc comment for which columns arrive null and why.
  factory AnalyticsSummaryModel.fromRow(Map<String, dynamic> row) {
    return AnalyticsSummaryModel(
      turnoverTiyn: (row['turnover_tiyn'] as num?)?.toInt(),
      ordersCount: (row['orders_count'] as num?)?.toInt(),
      ordersByStatus: _parseOrdersByStatus(row['orders_by_status']),
      installedCount: (row['installed_count'] as num?)?.toInt(),
      newClientsCount: (row['new_clients_count'] as num?)?.toInt(),
      avgOrderAmountTiyn: (row['avg_order_amount_tiyn'] as num?)?.toInt(),
      paymentsReceivedTiyn: (row['payments_received_tiyn'] as num?)?.toInt(),
      remainingDebtTiyn: (row['remaining_debt_tiyn'] as num?)?.toInt(),
      paymentMethodStats: _parsePaymentMethodStats(row['payment_method_stats']),
    );
  }

  static Map<OrderStatus, int> _parseOrdersByStatus(dynamic value) {
    if (value is! Map) return const {};
    final result = <OrderStatus, int>{};
    for (final entry in value.entries) {
      try {
        result[OrderStatus.fromDbValue(entry.key as String)] =
            (entry.value as num).toInt();
      } on ArgumentError {
        // Ignore any future status key the app doesn't model yet.
      }
    }
    return result;
  }

  static Map<PaymentMethod, PaymentMethodStat> _parsePaymentMethodStats(
    dynamic value,
  ) {
    if (value is! Map) return const {};
    final result = <PaymentMethod, PaymentMethodStat>{};
    for (final entry in value.entries) {
      try {
        final stat = entry.value as Map;
        result[PaymentMethod.fromDbKey(
          entry.key as String,
        )] = PaymentMethodStat(
          count: (stat['count'] as num).toInt(),
          amountTiyn: (stat['amount_tiyn'] as num).toInt(),
        );
      } on ArgumentError {
        // Ignore any future method key the app doesn't model yet.
      }
    }
    return result;
  }
}
