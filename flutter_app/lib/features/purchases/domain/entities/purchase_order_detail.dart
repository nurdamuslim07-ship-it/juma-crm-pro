import 'package:flutter/foundation.dart';

import 'purchase_order_item.dart';
import 'purchase_order_status.dart';

/// See `get_purchase_order_detail()` in
/// supabase/migrations/20260713000022_purchases_module.sql.
@immutable
class PurchaseOrderDetail {
  const PurchaseOrderDetail({
    required this.id,
    required this.orderNumber,
    required this.supplierPartnerId,
    required this.supplierName,
    this.supplierPhone,
    required this.status,
    this.responsibleEmployeeId,
    this.responsibleEmployeeName,
    this.expectedDeliveryDate,
    required this.deliveryCostTiyn,
    required this.vatTiyn,
    required this.discountTiyn,
    required this.subtotalTiyn,
    required this.totalAmountTiyn,
    this.comment,
    this.rejectionReason,
    required this.createdAt,
    this.approvedAt,
    this.receivedAt,
    required this.items,
  });

  final String id;
  final String orderNumber;
  final String supplierPartnerId;
  final String supplierName;
  final String? supplierPhone;
  final PurchaseOrderStatus status;
  final String? responsibleEmployeeId;
  final String? responsibleEmployeeName;
  final DateTime? expectedDeliveryDate;
  final int deliveryCostTiyn;
  final int vatTiyn;
  final int discountTiyn;
  final int subtotalTiyn;
  final int totalAmountTiyn;
  final String? comment;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final DateTime? receivedAt;
  final List<PurchaseOrderItem> items;

  bool get isDraft => status == PurchaseOrderStatus.draft;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseOrderDetail &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
