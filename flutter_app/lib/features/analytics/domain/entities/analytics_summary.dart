import 'package:flutter/foundation.dart';

import '../../../orders/domain/value_objects/order_status.dart';
import '../../../payments/domain/value_objects/payment_method.dart';
import 'payment_method_stat.dart';

/// See `get_analytics_summary()` in
/// supabase/migrations/20260713000019_analytics_module.sql. Unlike
/// Partner's tiered fields (which need explicit server-sent access
/// flags — see that class's doc comment), nullability alone IS a
/// reliable tier signal here: every sales/financial field the RPC
/// returns is wrapped in `coalesce(..., 0)` before the permission-gated
/// `case when ... then ... end`, so a granted field is always a
/// concrete number (0 if there's simply no data for the period) and only comes
/// back null when the whole section was redacted for the caller's
/// role. [hasSalesAccess]/[hasFinancialAccess] read that directly off
/// [turnoverTiyn]/[paymentsReceivedTiyn].
@immutable
class AnalyticsSummary {
  const AnalyticsSummary({
    this.turnoverTiyn,
    this.ordersCount,
    this.ordersByStatus = const {},
    this.installedCount,
    this.newClientsCount,
    this.avgOrderAmountTiyn,
    this.paymentsReceivedTiyn,
    this.remainingDebtTiyn,
    this.paymentMethodStats = const {},
  });

  final int? turnoverTiyn;
  final int? ordersCount;
  final Map<OrderStatus, int> ordersByStatus;
  final int? installedCount;
  final int? newClientsCount;
  final int? avgOrderAmountTiyn;
  final int? paymentsReceivedTiyn;
  final int? remainingDebtTiyn;
  final Map<PaymentMethod, PaymentMethodStat> paymentMethodStats;

  bool get hasSalesAccess => turnoverTiyn != null;
  bool get hasFinancialAccess => paymentsReceivedTiyn != null;
}
