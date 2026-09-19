import 'package:flutter/foundation.dart';

/// Backs `get_subscription_plans()` — the public plan catalog (see
/// supabase/migrations/20260713000038_company_settings_subscription.sql).
/// `priceTiyn == null` means "custom pricing / contact sales"
/// (`enterprise`), distinct from `free`'s genuine 0.
@immutable
class SubscriptionPlan {
  const SubscriptionPlan({
    required this.key,
    required this.nameKk,
    this.nameRu,
    this.maxEmployees,
    this.maxStorageMb,
    this.priceTiyn,
    required this.features,
  });

  final String key;
  final String nameKk;
  final String? nameRu;
  final int? maxEmployees;
  final int? maxStorageMb;
  final int? priceTiyn;
  final Map<String, dynamic> features;

  bool hasFeature(String key) => features[key] == true;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubscriptionPlan &&
          runtimeType == other.runtimeType &&
          key == other.key;

  @override
  int get hashCode => key.hashCode;
}
