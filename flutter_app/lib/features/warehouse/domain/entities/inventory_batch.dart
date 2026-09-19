import 'package:flutter/foundation.dart';

/// Requirement: "Партиялар" — one lot received into `inventory_batches`,
/// consumed FIFO by `issue_materials()` (oldest `received_at` first).
@immutable
class InventoryBatch {
  const InventoryBatch({
    required this.id,
    required this.materialId,
    required this.locationId,
    this.locationName,
    this.batchNumber,
    required this.quantityReceived,
    required this.quantityRemaining,
    required this.costPerUnitTiyn,
    this.supplierPartnerId,
    required this.receivedAt,
  });

  final String id;
  final String materialId;
  final String locationId;
  final String? locationName;
  final String? batchNumber;
  final num quantityReceived;
  final num quantityRemaining;
  final int costPerUnitTiyn;
  final String? supplierPartnerId;
  final DateTime receivedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryBatch &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
