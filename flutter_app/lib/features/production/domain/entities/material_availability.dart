import 'package:flutter/foundation.dart';

@immutable
class MaterialAvailability {
  const MaterialAvailability({
    this.materialId,
    required this.materialName,
    required this.unit,
    required this.reservedQuantity,
    required this.availableQuantity,
    required this.isSufficient,
  });

  /// Added by the Purchases module's supersede of
  /// get_order_production_detail() (see
  /// supabase/migrations/20260713000022_purchases_module.sql) so this
  /// row can be looked up in get_pending_purchase_quantities() —
  /// nullable only so older cached data never crashes deserialization.
  final String? materialId;
  final String materialName;
  final String unit;
  final double reservedQuantity;
  final double availableQuantity;
  final bool isSufficient;
}
