import '../../domain/entities/material_stock.dart';

class MaterialStockModel extends MaterialStock {
  const MaterialStockModel({
    required super.materialId,
    required super.name,
    super.categoryId,
    super.categoryKey,
    super.categoryNameKk,
    required super.unit,
    required super.minQuantity,
    required super.costPerUnitTiyn,
    super.barcode,
    required super.totalQuantity,
    required super.totalReserved,
    required super.availableQuantity,
    required super.isLowStock,
    super.preferredPartnerId,
    super.preferredPartnerName,
    super.preferredPartnerPhone,
    super.preferredPartnerWhatsapp,
  });

  factory MaterialStockModel.fromRow(Map<String, dynamic> row) {
    return MaterialStockModel(
      materialId: row['material_id'] as String,
      name: (row['name'] as String?) ?? '',
      categoryId: row['category_id'] as String?,
      categoryKey: row['category_key'] as String?,
      categoryNameKk: row['category_name_kk'] as String?,
      unit: (row['unit'] as String?) ?? '',
      minQuantity: (row['min_quantity'] as num?) ?? 0,
      costPerUnitTiyn: (row['cost_per_unit_tiyn'] as num?)?.toInt() ?? 0,
      barcode: row['barcode'] as String?,
      totalQuantity: (row['total_quantity'] as num?) ?? 0,
      totalReserved: (row['total_reserved'] as num?) ?? 0,
      availableQuantity: (row['available_quantity'] as num?) ?? 0,
      isLowStock: (row['is_low_stock'] as bool?) ?? false,
      preferredPartnerId: row['preferred_partner_id'] as String?,
      preferredPartnerName: row['preferred_partner_name'] as String?,
      preferredPartnerPhone: row['preferred_partner_phone'] as String?,
      preferredPartnerWhatsapp: row['preferred_partner_whatsapp'] as String?,
    );
  }
}
