import '../../domain/entities/purchase_analytics.dart';

class TopPurchasedMaterialModel extends TopPurchasedMaterial {
  const TopPurchasedMaterialModel({
    required super.materialName,
    required super.totalQuantity,
    required super.totalSpentTiyn,
  });

  factory TopPurchasedMaterialModel.fromJson(Map<String, dynamic> json) {
    return TopPurchasedMaterialModel(
      materialName: (json['material_name'] as String?) ?? '',
      totalQuantity: (json['total_quantity'] as num?) ?? 0,
      totalSpentTiyn: (json['total_spent_tiyn'] as num?)?.toInt() ?? 0,
    );
  }
}

class SupplierRatingModel extends SupplierRating {
  const SupplierRatingModel({
    required super.partnerId,
    required super.displayName,
    super.trustRating,
    required super.totalOrders,
    super.onTimeRate,
  });

  factory SupplierRatingModel.fromJson(Map<String, dynamic> json) {
    return SupplierRatingModel(
      partnerId: json['partner_id'] as String,
      displayName: (json['display_name'] as String?) ?? '',
      trustRating: (json['trust_rating'] as num?)?.toInt(),
      totalOrders: (json['total_orders'] as num?)?.toInt() ?? 0,
      onTimeRate: (json['on_time_rate'] as num?)?.toDouble(),
    );
  }
}

class PurchaseAnalyticsModel extends PurchaseAnalytics {
  const PurchaseAnalyticsModel({
    required super.monthlyPurchasesTiyn,
    required super.totalDebtTiyn,
    required super.totalAdvanceTiyn,
    required super.avgUnitPriceTiyn,
    required super.topMaterials,
    required super.supplierRatings,
  });

  factory PurchaseAnalyticsModel.fromRow(Map<String, dynamic> row) {
    final topMaterials = (row['top_materials'] as List? ?? [])
        .map(
          (e) => TopPurchasedMaterialModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
    final supplierRatings = (row['supplier_ratings'] as List? ?? [])
        .map((e) => SupplierRatingModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return PurchaseAnalyticsModel(
      monthlyPurchasesTiyn:
          (row['monthly_purchases_tiyn'] as num?)?.toInt() ?? 0,
      totalDebtTiyn: (row['total_debt_tiyn'] as num?)?.toInt() ?? 0,
      totalAdvanceTiyn: (row['total_advance_tiyn'] as num?)?.toInt() ?? 0,
      avgUnitPriceTiyn: (row['avg_unit_price_tiyn'] as num?)?.toDouble() ?? 0,
      topMaterials: topMaterials,
      supplierRatings: supplierRatings,
    );
  }
}
