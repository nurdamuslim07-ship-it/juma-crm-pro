import '../../domain/entities/partner.dart';
import '../../domain/value_objects/partner_category.dart';

class PartnerModel extends Partner {
  const PartnerModel({
    required super.id,
    required super.displayName,
    required super.category,
    super.companyName,
    super.phone,
    super.phoneSecondary,
    super.whatsappPhone,
    super.address,
    super.city,
    super.contactPerson,
    super.taxId,
    super.serviceDescription,
    super.priceNote,
    super.trustRating,
    super.lastWorkedAt,
    super.notes,
    super.bankDetails,
    super.balanceTiyn,
    required super.isActive,
    required super.createdAt,
    super.updatedAt,
    super.deletedAt,
    required super.hasExtendedAccess,
    required super.hasFinancialAccess,
  });

  /// Parses one row of `get_partners()`'s result set — see that RPC's
  /// definition for exactly which columns arrive `null` and why
  /// ([Partner]'s doc comment explains the same thing from the Dart
  /// side). `has_extended_access`/`has_financial_access` are the
  /// server's own tier flags, not inferred here.
  factory PartnerModel.fromRow(Map<String, dynamic> row) {
    return PartnerModel(
      id: row['id'] as String,
      displayName: (row['display_name'] as String?) ?? '',
      category: PartnerCategory.fromDbKey(row['category'] as String),
      companyName: row['company_name'] as String?,
      phone: row['phone'] as String?,
      phoneSecondary: row['phone_secondary'] as String?,
      whatsappPhone: row['whatsapp_phone'] as String?,
      address: row['address'] as String?,
      city: row['city'] as String?,
      contactPerson: row['contact_person'] as String?,
      taxId: row['tax_id'] as String?,
      serviceDescription: row['service_description'] as String?,
      priceNote: row['price_note'] as String?,
      trustRating: (row['trust_rating'] as num?)?.toInt(),
      lastWorkedAt: row['last_worked_at'] != null
          ? DateTime.parse(row['last_worked_at'] as String)
          : null,
      notes: row['notes'] as String?,
      bankDetails: row['bank_details'] as String?,
      balanceTiyn: (row['balance_tiyn'] as num?)?.toInt(),
      isActive: (row['is_active'] as bool?) ?? true,
      createdAt: DateTime.parse(row['created_at'] as String),
      updatedAt: row['updated_at'] != null
          ? DateTime.parse(row['updated_at'] as String)
          : null,
      deletedAt: row['deleted_at'] != null
          ? DateTime.parse(row['deleted_at'] as String)
          : null,
      hasExtendedAccess: (row['has_extended_access'] as bool?) ?? false,
      hasFinancialAccess: (row['has_financial_access'] as bool?) ?? false,
    );
  }
}
