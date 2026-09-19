import '../../domain/entities/company_settings.dart';

class CompanySettingsModel extends CompanySettings {
  const CompanySettingsModel({
    required super.id,
    required super.name,
    super.logo,
    super.phone,
    super.email,
    super.address,
    super.iinBin,
    super.website,
    required super.timezone,
    required super.currency,
    super.workingHours,
    super.description,
  });

  /// Parses a raw `companies` row (direct `.select()` — the table has
  /// no write policy at all, so RLS alone already keeps this read-only
  /// from the client's perspective; see `companies_select_own`).
  factory CompanySettingsModel.fromRow(Map<String, dynamic> row) {
    return CompanySettingsModel(
      id: row['id'] as String,
      name: row['name'] as String,
      logo: row['logo'] as String?,
      phone: row['phone'] as String?,
      email: row['email'] as String?,
      address: row['address'] as String?,
      iinBin: row['iin_bin'] as String?,
      website: row['website'] as String?,
      timezone: (row['timezone'] as String?) ?? 'Asia/Almaty',
      currency: (row['currency'] as String?) ?? 'KZT',
      workingHours: row['working_hours'] as String?,
      description: row['description'] as String?,
    );
  }
}
