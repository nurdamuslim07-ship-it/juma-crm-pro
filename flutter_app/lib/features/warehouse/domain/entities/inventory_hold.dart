import 'package:flutter/foundation.dart';

/// Requirement: "Резерв" — a generic, non-order hold (e.g. quality
/// inspection, damaged-goods set-aside), distinct from
/// "Production резерві" (order-tied reservations, see
/// [MaterialReservationSummary] — reused directly from the Production
/// module for that concept rather than duplicated here).
@immutable
class InventoryHold {
  const InventoryHold({
    required this.id,
    required this.materialId,
    required this.locationId,
    this.locationName,
    required this.quantity,
    this.reason,
    this.createdByName,
    required this.createdAt,
    this.releasedAt,
  });

  final String id;
  final String materialId;
  final String locationId;
  final String? locationName;
  final num quantity;
  final String? reason;
  final String? createdByName;
  final DateTime createdAt;
  final DateTime? releasedAt;

  bool get isActive => releasedAt == null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InventoryHold &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
