import '../../domain/entities/inventory_batch.dart';

class InventoryBatchModel extends InventoryBatch {
  const InventoryBatchModel({
    required super.id,
    required super.materialId,
    required super.locationId,
    super.locationName,
    super.batchNumber,
    required super.quantityReceived,
    required super.quantityRemaining,
    required super.costPerUnitTiyn,
    super.supplierPartnerId,
    required super.receivedAt,
  });

  factory InventoryBatchModel.fromRow(Map<String, dynamic> row) {
    final location = row['warehouse_locations'] as Map<String, dynamic>?;
    return InventoryBatchModel(
      id: row['id'] as String,
      materialId: row['material_id'] as String,
      locationId: row['location_id'] as String,
      locationName: location?['name'] as String?,
      batchNumber: row['batch_number'] as String?,
      quantityReceived: (row['quantity_received'] as num?) ?? 0,
      quantityRemaining: (row['quantity_remaining'] as num?) ?? 0,
      costPerUnitTiyn: (row['cost_per_unit_tiyn'] as num?)?.toInt() ?? 0,
      supplierPartnerId: row['supplier_partner_id'] as String?,
      receivedAt: DateTime.parse(row['received_at'] as String),
    );
  }
}
