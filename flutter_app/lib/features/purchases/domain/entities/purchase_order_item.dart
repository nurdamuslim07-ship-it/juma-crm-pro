import 'package:flutter/foundation.dart';

/// One line of a purchase order — see `purchase_order_items` in
/// supabase/migrations/20260713000022_purchases_module.sql. Doubles as
/// both the draft form's local line (itemId/batchId/materialName/
/// locationName null until the order is created and re-fetched) and
/// the read model from `get_purchase_order_detail()`'s `items` jsonb.
@immutable
class PurchaseOrderItem {
  const PurchaseOrderItem({
    this.itemId,
    required this.materialId,
    this.materialName,
    required this.quantity,
    required this.unit,
    required this.unitPriceTiyn,
    this.totalPriceTiyn,
    this.locationId,
    this.locationName,
    this.batchId,
  });

  final String? itemId;
  final String materialId;
  final String? materialName;
  final num quantity;
  final String unit;
  final int unitPriceTiyn;
  final int? totalPriceTiyn;
  final String? locationId;
  final String? locationName;
  final String? batchId;

  PurchaseOrderItem copyWith({
    num? quantity,
    int? unitPriceTiyn,
    String? locationId,
    String? locationName,
  }) => PurchaseOrderItem(
    itemId: itemId,
    materialId: materialId,
    materialName: materialName,
    quantity: quantity ?? this.quantity,
    unit: unit,
    unitPriceTiyn: unitPriceTiyn ?? this.unitPriceTiyn,
    totalPriceTiyn: totalPriceTiyn,
    locationId: locationId ?? this.locationId,
    locationName: locationName ?? this.locationName,
    batchId: batchId,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PurchaseOrderItem &&
          runtimeType == other.runtimeType &&
          materialId == other.materialId &&
          locationId == other.locationId;

  @override
  int get hashCode => Object.hash(materialId, locationId);
}
