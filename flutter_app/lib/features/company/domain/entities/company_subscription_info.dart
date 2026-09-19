import 'package:flutter/foundation.dart';

/// Backs `get_company_subscription_info()` — always the CALLER's own
/// company (derived server-side from `auth_company_id()`, never a
/// parameter here or anywhere else in this module).
@immutable
class CompanySubscriptionInfo {
  const CompanySubscriptionInfo({
    required this.planKey,
    required this.planNameKk,
    this.planNameRu,
    this.maxEmployees,
    this.maxStorageMb,
    this.priceTiyn,
    required this.status,
    required this.startedAt,
    this.expiresAt,
    this.remainingDays,
    required this.isTrial,
    this.trialEndsAt,
    required this.companyIsActive,
    required this.activeUsers,
  });

  final String planKey;
  final String planNameKk;
  final String? planNameRu;
  final int? maxEmployees;
  final int? maxStorageMb;
  final int? priceTiyn;
  final String status;
  final DateTime startedAt;
  final DateTime? expiresAt;
  final int? remainingDays;
  final bool isTrial;
  final DateTime? trialEndsAt;
  final bool companyIsActive;
  final int activeUsers;

  /// Mirrors the same "expired but the company itself isn't
  /// deactivated" distinction `SubscriptionGuard` acts on — see that
  /// widget's own doc comment.
  bool get isExpired =>
      status != 'active' || (remainingDays != null && remainingDays! <= 0);
}
