/// Mirrors `company_join_requests.status`
/// (supabase/migrations/20260713000036_company_registration_module.sql).
enum JoinRequestStatus {
  pending,
  approved,
  rejected,
  withdrawn;

  static JoinRequestStatus fromDbKey(String key) {
    return JoinRequestStatus.values.firstWhere(
      (s) => s.dbKey == key,
      orElse: () => throw ArgumentError('Unknown join request status: $key'),
    );
  }

  String get dbKey => name;
}
