import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/employees/domain/value_objects/employee_role.dart';

void main() {
  group('EmployeeRole.dbKey / fromDbKey', () {
    test('round-trips every role through its role_key Postgres enum value', () {
      for (final role in EmployeeRole.values) {
        expect(EmployeeRole.fromDbKey(role.dbKey), role);
      }
    });

    test('matches the exact keys defined in the role_key Postgres enum '
        '(supabase/migrations/20260713000001_extensions_and_enums.sql)', () {
      expect(EmployeeRole.director.dbKey, 'director');
      expect(EmployeeRole.manager.dbKey, 'manager');
      expect(EmployeeRole.measurer.dbKey, 'measurer');
      expect(EmployeeRole.designer.dbKey, 'designer');
      expect(EmployeeRole.workshopManager.dbKey, 'workshop_manager');
      expect(EmployeeRole.master.dbKey, 'master');
      expect(EmployeeRole.assistant.dbKey, 'assistant');
      expect(EmployeeRole.installer.dbKey, 'installer');
      expect(EmployeeRole.accountant.dbKey, 'accountant');
      expect(EmployeeRole.warehouse.dbKey, 'warehouse');
      expect(EmployeeRole.admin.dbKey, 'admin');
      expect(EmployeeRole.purchaser.dbKey, 'purchaser');
    });

    test('throws on an unknown key instead of silently returning null', () {
      expect(() => EmployeeRole.fromDbKey('ceo'), throwsArgumentError);
    });
  });
}
