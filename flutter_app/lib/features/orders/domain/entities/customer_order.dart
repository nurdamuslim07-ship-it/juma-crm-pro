import 'package:flutter/foundation.dart';

import '../value_objects/order_status.dart';

/// See DATABASE_SCHEMA.md "Orders domain" and ORDER_WORKFLOW.md.
///
/// Critical rule carried over from both docs and CLAUDE.md: [paidTiyn]
/// (and everything derived from it — [remainingTiyn],
/// [paymentPercent]) is a SUM over the `payments` ledger, computed by
/// the datasource, never a mutable column the order form edits
/// directly. This is the fix for the exact flaw audited in the legacy
/// web app (`Order.paidAmount` as a single hand-edited running total).
/// The Orders module only ever *displays* these; only the future
/// Payments module records the transactions that make up the sum.
@immutable
class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.orderNumber,
    required this.clientId,
    required this.clientName,
    required this.clientPhone,
    required this.productType,
    this.description,
    required this.status,
    this.responsibleEmployeeId,
    this.responsibleEmployeeName,
    this.measurementDate,
    this.plannedCompletionDate,
    required this.totalAmountTiyn,
    required this.paidTiyn,
    required this.createdAt,
  });

  final String id;
  final String orderNumber;
  final String clientId;
  final String clientName;
  final String clientPhone;
  final String productType;
  final String? description;
  final OrderStatus status;
  final String? responsibleEmployeeId;
  final String? responsibleEmployeeName;
  final DateTime? measurementDate;
  final DateTime? plannedCompletionDate;
  final int totalAmountTiyn;
  final int paidTiyn;
  final DateTime createdAt;

  int get remainingTiyn => (totalAmountTiyn - paidTiyn).clamp(0, 1 << 62);

  double get paymentPercent => totalAmountTiyn == 0
      ? 0
      : (paidTiyn / totalAmountTiyn * 100).clamp(0, 100);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerOrder &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
