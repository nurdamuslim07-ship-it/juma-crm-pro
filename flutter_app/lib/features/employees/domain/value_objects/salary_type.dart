/// Mirrors the `salary_type` Postgres enum in
/// supabase/migrations/20260713000017_employees_module.sql exactly —
/// [dbKey]/[fromDbKey] are the only place that mapping is spelled out.
enum SalaryType {
  fixed,
  percentage;

  static SalaryType fromDbKey(String key) {
    return SalaryType.values.firstWhere(
      (s) => s.dbKey == key,
      orElse: () => throw ArgumentError('Unknown salary_type: $key'),
    );
  }

  String get dbKey {
    switch (this) {
      case SalaryType.fixed:
        return 'fixed';
      case SalaryType.percentage:
        return 'percentage';
    }
  }
}
