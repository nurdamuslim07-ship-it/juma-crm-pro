import '../../domain/entities/purchase_order_detail.dart';
import '../../domain/entities/purchase_order_status.dart';
import 'purchase_order_item_model.dart';

class PurchaseOrderDetailModel extends PurchaseOrderDetail {
  const PurchaseOrderDetailModel({
    required super.id,
    required super.orderNumber,
    required super.supplierPartnerId,
    required super.supplierName,
    super.supplierPhone,
    required super.status,
    super.responsibleEmployeeId,
    super.responsibleEmployeeName,
    super.expectedDeliveryDate,
    required super.deliveryCostTiyn,
    required super.vatTiyn,
    required super.discountTiyn,
    required super.subtotalTiyn,
    required super.totalAmountTiyn,
    super.comment,
    super.rejectionReason,
    required super.createdAt,
    super.approvedAt,
    super.receivedAt,
    required super.items,
  });

  factory PurchaseOrderDetailModel.fromRow(Map<String, dynamic> row) {
    final items = (row['items'] as List? ?? [])
        .map((e) => PurchaseOrderItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return PurchaseOrderDetailModel(
      id: row['id'] as String,
      orderNumber: (row['order_number'] as String?) ?? '',
      supplierPartnerId: row['supplier_partner_id'] as String,
      supplierName: (row['supplier_name'] as String?) ?? '',
      supplierPhone: row['supplier_phone'] as String?,
      status: PurchaseOrderStatusX.fromKey(row['status'] as String),
      responsibleEmployeeId: row['responsible_employee_id'] as String?,
      responsibleEmployeeName: row['responsible_employee_name'] as String?,
      expectedDeliveryDate: row['expected_delivery_date'] == null
          ? null
          : DateTime.parse(row['expected_delivery_date'] as String),
      deliveryCostTiyn: (row['delivery_cost_tiyn'] as num?)?.toInt() ?? 0,
      vatTiyn: (row['vat_tiyn'] as num?)?.toInt() ?? 0,
      discountTiyn: (row['discount_tiyn'] as num?)?.toInt() ?? 0,
      subtotalTiyn: (row['subtotal_tiyn'] as num?)?.toInt() ?? 0,
      totalAmountTiyn: (row['total_amount_tiyn'] as num?)?.toInt() ?? 0,
      comment: row['comment'] as String?,
      rejectionReason: row['rejection_reason'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      approvedAt: row['approved_at'] == null
          ? null
          : DateTime.parse(row['approved_at'] as String),
      receivedAt: row['received_at'] == null
          ? null
          : DateTime.parse(row['received_at'] as String),
      items: items,
    );
  }
}
