import '../../domain/entities/company_subscription_info.dart';

class CompanySubscriptionInfoModel extends CompanySubscriptionInfo {
  const CompanySubscriptionInfoModel({
    required super.planKey,
    required super.planNameKk,
    super.planNameRu,
    super.maxEmployees,
    super.maxStorageMb,
    super.priceTiyn,
    required super.status,
    required super.startedAt,
    super.expiresAt,
    super.remainingDays,
    required super.isTrial,
    super.trialEndsAt,
    required super.companyIsActive,
    required super.activeUsers,
  });

  /// Parses `get_company_subscription_info()`'s single-row result set.
  factory CompanySubscriptionInfoModel.fromRow(Map<String, dynamic> row) {
    return CompanySubscriptionInfoModel(
      planKey: row['plan_key'] as String,
      planNameKk: row['plan_name_kk'] as String,
      planNameRu: row['plan_name_ru'] as String?,
      maxEmployees: (row['max_employees'] as num?)?.toInt(),
      maxStorageMb: (row['max_storage_mb'] as num?)?.toInt(),
      priceTiyn: (row['price_tiyn'] as num?)?.toInt(),
      status: row['subscription_status'] as String,
      startedAt: DateTime.parse(row['started_at'] as String),
      expiresAt: row['expires_at'] != null
          ? DateTime.parse(row['expires_at'] as String)
          : null,
      remainingDays: (row['remaining_days'] as num?)?.toInt(),
      isTrial: row['is_trial'] as bool? ?? false,
      trialEndsAt: row['trial_ends_at'] != null
          ? DateTime.parse(row['trial_ends_at'] as String)
          : null,
      companyIsActive: row['company_is_active'] as bool? ?? true,
      activeUsers: (row['active_users'] as num?)?.toInt() ?? 0,
    );
  }
}
