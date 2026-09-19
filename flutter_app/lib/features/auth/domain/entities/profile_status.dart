/// Mirrors the `profile_status` Postgres enum
/// (supabase/migrations/20260713000023_multi_tenant_companies_core.sql).
/// This is membership/onboarding state — distinct from the legacy
/// `profiles.is_active` boolean (see [AuthUser.isActive]'s own doc
/// comment), which is no longer the access gate anywhere server-side.
enum ProfileStatus {
  pending,
  active,
  rejected,
  suspended;

  static ProfileStatus fromDbKey(String key) {
    return ProfileStatus.values.firstWhere(
      (s) => s.dbKey == key,
      orElse: () => throw ArgumentError('Unknown profile_status: $key'),
    );
  }

  String get dbKey => name;
}
