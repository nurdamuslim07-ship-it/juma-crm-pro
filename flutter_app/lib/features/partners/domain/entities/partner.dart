import 'package:flutter/foundation.dart';

import '../value_objects/partner_category.dart';

/// See Partners module requirements. Field visibility is three-tiered
/// server-side (get_partners() in
/// supabase/migrations/20260713000018_partners_module.sql): basic
/// contact fields are always present; [taxId]/[serviceDescription]/
/// [priceNote]/[trustRating]/[lastWorkedAt]/[notes] ("extended" tier)
/// and [bankDetails]/[balanceTiyn] ("financial" tier) come back null
/// when the server redacted them for the caller's role. [hasExtendedAccess]/
/// [hasFinancialAccess] are the server's own `has_extended_access`/
/// `has_financial_access` flags, not inferred from field nullability —
/// several extended/financial fields (trust_rating, notes, balance)
/// are legitimately null even when the caller does have access, so
/// nullability alone can't distinguish "redacted" from "empty".
@immutable
class Partner {
  const Partner({
    required this.id,
    required this.displayName,
    required this.category,
    this.companyName,
    this.phone,
    this.phoneSecondary,
    this.whatsappPhone,
    this.address,
    this.city,
    this.contactPerson,
    this.taxId,
    this.serviceDescription,
    this.priceNote,
    this.trustRating,
    this.lastWorkedAt,
    this.notes,
    this.bankDetails,
    this.balanceTiyn,
    required this.isActive,
    required this.createdAt,
    this.updatedAt,
    this.deletedAt,
    required this.hasExtendedAccess,
    required this.hasFinancialAccess,
  });

  final String id;
  final String displayName;
  final PartnerCategory category;
  final String? companyName;
  final String? phone;
  final String? phoneSecondary;
  final String? whatsappPhone;
  final String? address;
  final String? city;
  final String? contactPerson;
  final String? taxId;
  final String? serviceDescription;
  final String? priceNote;
  final int? trustRating;
  final DateTime? lastWorkedAt;
  final String? notes;
  final String? bankDetails;
  final int? balanceTiyn;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final bool hasExtendedAccess;
  final bool hasFinancialAccess;

  bool get isDeleted => deletedAt != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Partner && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
