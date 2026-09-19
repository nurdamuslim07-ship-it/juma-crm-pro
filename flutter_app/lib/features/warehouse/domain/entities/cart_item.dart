import 'package:flutter/foundation.dart';

/// Requirement: "Себетке шығару" — one pending line in the issue cart,
/// held only in local widget state (see `issue_cart_provider.dart`)
/// until submitted atomically via `issue_materials()`.
@immutable
class CartItem {
  const CartItem({
    required this.materialId,
    required this.materialName,
    required this.locationId,
    required this.locationName,
    required this.unit,
    required this.quantity,
  });

  final String materialId;
  final String materialName;
  final String locationId;
  final String locationName;
  final String unit;
  final num quantity;

  CartItem copyWith({num? quantity}) => CartItem(
    materialId: materialId,
    materialName: materialName,
    locationId: locationId,
    locationName: locationName,
    unit: unit,
    quantity: quantity ?? this.quantity,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartItem &&
          runtimeType == other.runtimeType &&
          materialId == other.materialId &&
          locationId == other.locationId;

  @override
  int get hashCode => Object.hash(materialId, locationId);
}
