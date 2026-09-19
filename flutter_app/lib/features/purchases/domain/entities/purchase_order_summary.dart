import 'package:flutter/foundation.dart';

import 'purchase_order_status.dart';

/// One row of `get_purchase_orders()` — the Purchase Orders list/table.
@immutable
class PurchaseOrderSummary {
  const PurchaseOrderSummary({
    required this.id,
    required this.orderNumber,
    required this.supplierPartnerId,
    required this.supplierName,
    required this.status,
    this.responsibleEmployeeId,
    this.responsibleEmployeeName,
    this.expectedDeliveryDate,
    required this.itemsCount,
    required this.totalAmountTiyn,
    required this.createdAt,
  });

  final String id;
  final String orderNumber;
  final String supplierPartnerId;
  final String supplierName;
  final PurchaseOrderStatus status;
  final String? responsibleEmployeeId;
  final String? responsibleEmployeeName;
  final DateTime? expectedDeliveryDate;
  final int itemsCount;
  final int totalAmountTiyn;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseOrderSummary &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
