import 'package:flutter/foundation.dart';

/// One row of `get_materials()` — see
/// supabase/migrations/20260713000021_warehouse_module.sql. Balances
/// are summed across every `warehouse_locations` row for this
/// material; [availableQuantity] already subtracts both
/// "Production резерві" (`material_reservations`) and generic "Резерв"
/// (`inventory_holds`), since both write to the same
/// `inventory_balances.reserved_quantity` column.
@immutable
class MaterialStock {
  const MaterialStock({
    required this.materialId,
    required this.name,
    this.categoryId,
    this.categoryKey,
    this.categoryNameKk,
    required this.unit,
    required this.minQuantity,
    required this.costPerUnitTiyn,
    this.barcode,
    required this.totalQuantity,
    required this.totalReserved,
    required this.availableQuantity,
    required this.isLowStock,
    this.preferredPartnerId,
    this.preferredPartnerName,
    this.preferredPartnerPhone,
    this.preferredPartnerWhatsapp,
  });

  final String materialId;
  final String name;
  final String? categoryId;
  final String? categoryKey;
  final String? categoryNameKk;
  final String unit;
  final num minQuantity;
  final int costPerUnitTiyn;
  final String? barcode;
  final num totalQuantity;
  final num totalReserved;
  final num availableQuantity;
  final bool isLowStock;
  final String? preferredPartnerId;
  final String? preferredPartnerName;
  final String? preferredPartnerPhone;
  final String? preferredPartnerWhatsapp;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialStock &&
          runtimeType == other.runtimeType &&
          materialId == other.materialId;

  @override
  int get hashCode => materialId.hashCode;
}
