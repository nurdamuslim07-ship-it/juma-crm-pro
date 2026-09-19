import '../../domain/entities/purchase_order_item.dart';

class PurchaseOrderItemModel extends PurchaseOrderItem {
  const PurchaseOrderItemModel({
    super.itemId,
    required super.materialId,
    super.materialName,
    required super.quantity,
    required super.unit,
    required super.unitPriceTiyn,
    super.totalPriceTiyn,
    super.locationId,
    super.locationName,
    super.batchId,
  });

  /// From `get_purchase_order_detail()`'s `items` jsonb array.
  factory PurchaseOrderItemModel.fromJson(Map<String, dynamic> json) {
    return PurchaseOrderItemModel(
      itemId: json['item_id'] as String?,
      materialId: json['material_id'] as String,
      materialName: json['material_name'] as String?,
      quantity: (json['quantity'] as num?) ?? 0,
      unit: (json['unit'] as String?) ?? '',
      unitPriceTiyn: (json['unit_price_tiyn'] as num?)?.toInt() ?? 0,
      totalPriceTiyn: (json['total_price_tiyn'] as num?)?.toInt(),
      locationId: json['location_id'] as String?,
      locationName: json['location_name'] as String?,
      batchId: json['batch_id'] as String?,
    );
  }
}
