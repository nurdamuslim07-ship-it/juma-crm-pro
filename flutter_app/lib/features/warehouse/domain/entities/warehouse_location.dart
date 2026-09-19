import 'package:flutter/foundation.dart';

/// A row of `warehouse_locations` (e.g. "Сөре 1") — readable by any
/// active user (see `warehouse_locations_read_all_active`), used to
/// pick where a receive/reserve/hold action applies.
@immutable
class WarehouseLocation {
  const WarehouseLocation({
    required this.id,
    required this.warehouseId,
    required this.name,
  });

  final String id;
  final String warehouseId;
  final String name;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WarehouseLocation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
