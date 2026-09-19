/// Mirrors the `role_key` Postgres enum, same source of truth as
/// `features/employees/domain/value_objects/employee_role.dart` — kept
/// as a separate, smaller value object here rather than reusing that
/// one because this list is deliberately narrower: `owner` is excluded
/// on purpose (see supabase/migrations/20260713000036's header comment
/// — nothing in this app offers `owner` as a requestable/invitable
/// role, so a company can only ever gain a second owner via
/// update_employee(), a director-only action, never via self-service
/// join/invite). Employees module code is untouched by this feature.
enum CompanyRole {
  director,
  manager,
  measurer,
  designer,
  workshopManager,
  master,
  assistant,
  installer,
  accountant,
  warehouse,
  admin,
  purchaser,
  viewer;

  static CompanyRole fromDbKey(String key) {
    return CompanyRole.values.firstWhere(
      (r) => r.dbKey == key,
      orElse: () => throw ArgumentError('Unknown role_key: $key'),
    );
  }

  String get dbKey {
    switch (this) {
      case CompanyRole.director:
        return 'director';
      case CompanyRole.manager:
        return 'manager';
      case CompanyRole.measurer:
        return 'measurer';
      case CompanyRole.designer:
        return 'designer';
      case CompanyRole.workshopManager:
        return 'workshop_manager';
      case CompanyRole.master:
        return 'master';
      case CompanyRole.assistant:
        return 'assistant';
      case CompanyRole.installer:
        return 'installer';
      case CompanyRole.accountant:
        return 'accountant';
      case CompanyRole.warehouse:
        return 'warehouse';
      case CompanyRole.admin:
        return 'admin';
      case CompanyRole.purchaser:
        return 'purchaser';
      case CompanyRole.viewer:
        return 'viewer';
    }
  }
}
