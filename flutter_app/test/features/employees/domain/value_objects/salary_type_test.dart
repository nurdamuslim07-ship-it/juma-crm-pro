import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/employees/domain/value_objects/salary_type.dart';

void main() {
  group('SalaryType.dbKey / fromDbKey', () {
    test(
      'round-trips every value through its salary_type Postgres enum value',
      () {
        for (final type in SalaryType.values) {
          expect(SalaryType.fromDbKey(type.dbKey), type);
        }
      },
    );

    test('matches "Жалақы түрі": Тұрақты / Пайыздық', () {
      expect(SalaryType.fixed.dbKey, 'fixed');
      expect(SalaryType.percentage.dbKey, 'percentage');
    });

    test('throws on an unknown key instead of silently returning null', () {
      expect(() => SalaryType.fromDbKey('hourly'), throwsArgumentError);
    });
  });
}
