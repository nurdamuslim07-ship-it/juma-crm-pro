import '../../domain/entities/subscription_plan.dart';

class SubscriptionPlanModel extends SubscriptionPlan {
  const SubscriptionPlanModel({
    required super.key,
    required super.nameKk,
    super.nameRu,
    super.maxEmployees,
    super.maxStorageMb,
    super.priceTiyn,
    required super.features,
  });

  /// Parses one row of `get_subscription_plans()`'s result set.
  factory SubscriptionPlanModel.fromRow(Map<String, dynamic> row) {
    return SubscriptionPlanModel(
      key: row['key'] as String,
      nameKk: row['name_kk'] as String,
      nameRu: row['name_ru'] as String?,
      maxEmployees: (row['max_employees'] as num?)?.toInt(),
      maxStorageMb: (row['max_storage_mb'] as num?)?.toInt(),
      priceTiyn: (row['price_tiyn'] as num?)?.toInt(),
      features: (row['features'] as Map<String, dynamic>?) ?? const {},
    );
  }
}
