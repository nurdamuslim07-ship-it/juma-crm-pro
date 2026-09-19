/// Mirrors the `partner_category` Postgres enum
/// (supabase/migrations/20260713000001_extensions_and_enums.sql)
/// exactly — the Partners module's fixed 7-category list (plus
/// "Барлығы" for the "all" filter option, which is `null` here, not a
/// value of this enum).
enum PartnerCategory {
  gazelleDriver,
  taxiDriver,
  ldsp,
  mdfCnc,
  fittings,
  canteen,
  other;

  static PartnerCategory fromDbKey(String key) {
    return PartnerCategory.values.firstWhere(
      (c) => c.dbKey == key,
      orElse: () => throw ArgumentError('Unknown partner_category: $key'),
    );
  }

  String get dbKey {
    switch (this) {
      case PartnerCategory.gazelleDriver:
        return 'gazelle_driver';
      case PartnerCategory.taxiDriver:
        return 'taxi_driver';
      case PartnerCategory.ldsp:
        return 'ldsp';
      case PartnerCategory.mdfCnc:
        return 'mdf_cnc';
      case PartnerCategory.fittings:
        return 'fittings';
      case PartnerCategory.canteen:
        return 'canteen';
      case PartnerCategory.other:
        return 'other';
    }
  }
}
