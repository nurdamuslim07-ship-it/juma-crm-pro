/// Mirrors the `role_key` Postgres enum
/// (supabase/migrations/20260713000001_extensions_and_enums.sql)
/// exactly. The Employees module's role picker (requirement's 9-role
/// list) shows every value here — `warehouse`/`admin`/`purchaser`
/// aren't in that explicit list but already exist as real roles
/// elsewhere in the system (see ROLES_AND_PERMISSIONS.md and the
/// Partners module's "Purchaser/закупщик" role), so excluding them
/// from this picker would make it impossible to hire into those roles
/// at all.
enum EmployeeRole {
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
  purchaser;

  static EmployeeRole fromDbKey(String key) {
    return EmployeeRole.values.firstWhere(
      (r) => r.dbKey == key,
      orElse: () => throw ArgumentError('Unknown role_key: $key'),
    );
  }

  String get dbKey {
    switch (this) {
      case EmployeeRole.director:
        return 'director';
      case EmployeeRole.manager:
        return 'manager';
      case EmployeeRole.measurer:
        return 'measurer';
      case EmployeeRole.designer:
        return 'designer';
      case EmployeeRole.workshopManager:
        return 'workshop_manager';
      case EmployeeRole.master:
        return 'master';
      case EmployeeRole.assistant:
        return 'assistant';
      case EmployeeRole.installer:
        return 'installer';
      case EmployeeRole.accountant:
        return 'accountant';
      case EmployeeRole.warehouse:
        return 'warehouse';
      case EmployeeRole.admin:
        return 'admin';
      case EmployeeRole.purchaser:
        return 'purchaser';
    }
  }
}
