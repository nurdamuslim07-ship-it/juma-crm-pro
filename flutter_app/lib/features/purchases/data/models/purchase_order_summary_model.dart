import '../../domain/entities/purchase_order_status.dart';
import '../../domain/entities/purchase_order_summary.dart';

class PurchaseOrderSummaryModel extends PurchaseOrderSummary {
  const PurchaseOrderSummaryModel({
    required super.id,
    required super.orderNumber,
    required super.supplierPartnerId,
    required super.supplierName,
    required super.status,
    super.responsibleEmployeeId,
    super.responsibleEmployeeName,
    super.expectedDeliveryDate,
    required super.itemsCount,
    required super.totalAmountTiyn,
    required super.createdAt,
  });

  factory PurchaseOrderSummaryModel.fromRow(Map<String, dynamic> row) {
    return PurchaseOrderSummaryModel(
      id: row['id'] as String,
      orderNumber: (row['order_number'] as String?) ?? '',
      supplierPartnerId: row['supplier_partner_id'] as String,
      supplierName: (row['supplier_name'] as String?) ?? '',
      status: PurchaseOrderStatusX.fromKey(row['status'] as String),
      responsibleEmployeeId: row['responsible_employee_id'] as String?,
      responsibleEmployeeName: row['responsible_employee_name'] as String?,
      expectedDeliveryDate: row['expected_delivery_date'] == null
          ? null
          : DateTime.parse(row['expected_delivery_date'] as String),
      itemsCount: (row['items_count'] as num?)?.toInt() ?? 0,
      totalAmountTiyn: (row['total_amount_tiyn'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
