import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/employees/domain/employee_validation.dart';

void main() {
  group('validateFullName', () {
    test('rejects empty and whitespace-only input', () {
      expect(validateFullName(''), isNotNull);
      expect(validateFullName('   '), isNotNull);
    });

    test('rejects a single character', () {
      expect(validateFullName('А'), isNotNull);
    });

    test('accepts a real Kazakh name', () {
      expect(validateFullName('Асқар Жұмабеков'), isNull);
    });
  });

  group('validateEmail', () {
    test('rejects empty input', () {
      expect(validateEmail(''), isNotNull);
    });

    test('rejects a string with no @ or domain', () {
      expect(validateEmail('not-an-email'), isNotNull);
      expect(validateEmail('missing@domain'), isNotNull);
    });

    test('accepts a well-formed email', () {
      expect(validateEmail('employee@jumaui.kz'), isNull);
    });
  });

  group('validatePhone', () {
    test('is optional by default — empty is valid', () {
      expect(validatePhone(''), isNull);
    });

    test('is rejected when explicitly required and empty', () {
      expect(validatePhone('', required: true), isNotNull);
    });

    test('rejects a malformed number', () {
      expect(validatePhone('123'), isNotNull);
    });

    test('accepts a well-formed KZ mobile number', () {
      expect(validatePhone('+77011234567'), isNull);
      expect(validatePhone('77011234567'), isNull);
    });
  });

  group(
    'validatePassword — requirement: "Құпиясөзді ашық мәтінде еш жерде жазылмасын" '
    '(this validates strength client-side; Supabase Auth is what actually hashes it)',
    () {
      test('rejects empty input', () {
        expect(validatePassword(''), isNotNull);
      });

      test('rejects fewer than 8 characters', () {
        expect(validatePassword('short1'), isNotNull);
      });

      test('accepts 8+ characters', () {
        expect(validatePassword('12345678'), isNull);
      });
    },
  );

  group('validateBonusPercent', () {
    test('rejects negative values', () {
      expect(validateBonusPercent(-1), isNotNull);
    });

    test('rejects values over 100', () {
      expect(validateBonusPercent(101), isNotNull);
    });

    test('accepts the full 0-100 range inclusive', () {
      expect(validateBonusPercent(0), isNull);
      expect(validateBonusPercent(100), isNull);
      expect(validateBonusPercent(50), isNull);
    });
  });

  group('validateBaseSalary', () {
    test('rejects a negative salary', () {
      expect(validateBaseSalary(-1), isNotNull);
    });

    test('accepts zero and positive amounts', () {
      expect(validateBaseSalary(0), isNull);
      expect(validateBaseSalary(50000000), isNull);
    });
  });
}
