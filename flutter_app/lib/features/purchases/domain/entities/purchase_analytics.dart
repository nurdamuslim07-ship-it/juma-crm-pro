import 'package:flutter/foundation.dart';

/// Requirement: "Ең көп сатып алынған материалдар" — one row of
/// `get_purchase_analytics()`'s `top_materials` jsonb array.
@immutable
class TopPurchasedMaterial {
  const TopPurchasedMaterial({
    required this.materialName,
    required this.totalQuantity,
    required this.totalSpentTiyn,
  });

  final String materialName;
  final num totalQuantity;
  final int totalSpentTiyn;
}

/// Requirement: "Жеткізуші рейтингі" — one row of
/// `get_purchase_analytics()`'s `supplier_ratings` jsonb array.
/// [onTimeRate] is null when no order has been received yet (nothing
/// to measure punctuality against).
@immutable
class SupplierRating {
  const SupplierRating({
    required this.partnerId,
    required this.displayName,
    this.trustRating,
    required this.totalOrders,
    this.onTimeRate,
  });

  final String partnerId;
  final String displayName;
  final int? trustRating;
  final int totalOrders;
  final double? onTimeRate;
}

/// See `get_purchase_analytics()`.
@immutable
class PurchaseAnalytics {
  const PurchaseAnalytics({
    required this.monthlyPurchasesTiyn,
    required this.totalDebtTiyn,
    required this.totalAdvanceTiyn,
    required this.avgUnitPriceTiyn,
    required this.topMaterials,
    required this.supplierRatings,
  });

  final int monthlyPurchasesTiyn;
  final int totalDebtTiyn;
  final int totalAdvanceTiyn;
  final double avgUnitPriceTiyn;
  final List<TopPurchasedMaterial> topMaterials;
  final List<SupplierRating> supplierRatings;
}
