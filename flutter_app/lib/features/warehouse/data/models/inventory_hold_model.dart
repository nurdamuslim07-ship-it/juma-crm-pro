import '../../domain/entities/inventory_hold.dart';

class InventoryHoldModel extends InventoryHold {
  const InventoryHoldModel({
    required super.id,
    required super.materialId,
    required super.locationId,
    super.locationName,
    required super.quantity,
    super.reason,
    super.createdByName,
    required super.createdAt,
    super.releasedAt,
  });

  factory InventoryHoldModel.fromRow(Map<String, dynamic> row) {
    final location = row['warehouse_locations'] as Map<String, dynamic>?;
    final createdBy = row['profiles'] as Map<String, dynamic>?;
    return InventoryHoldModel(
      id: row['id'] as String,
      materialId: row['material_id'] as String,
      locationId: row['location_id'] as String,
      locationName: location?['name'] as String?,
      quantity: (row['quantity'] as num?) ?? 0,
      reason: row['reason'] as String?,
      createdByName: createdBy?['full_name'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      releasedAt: row['released_at'] == null
          ? null
          : DateTime.parse(row['released_at'] as String),
    );
  }
}
