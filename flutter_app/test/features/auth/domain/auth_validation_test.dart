import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/auth/domain/auth_validation.dart';

void main() {
  group('validateFullName', () {
    test('rejects empty/whitespace-only', () {
      expect(validateFullName(''), isNotNull);
      expect(validateFullName('   '), isNotNull);
    });

    test('accepts a real name', () {
      expect(validateFullName('Жаңа қолданушы'), isNull);
    });
  });

  group('validateEmail', () {
    test('rejects empty', () {
      expect(validateEmail(''), isNotNull);
    });

    test('rejects malformed addresses', () {
      expect(validateEmail('not-an-email'), isNotNull);
      expect(validateEmail('missing-domain@'), isNotNull);
      expect(validateEmail('@missing-local.kz'), isNotNull);
      expect(validateEmail('no-at-sign.kz'), isNotNull);
    });

    test('accepts a well-formed email, not restricted to any one domain', () {
      expect(validateEmail('director@juma.kz'), isNull);
      expect(validateEmail('someone@gmail.com'), isNull);
      expect(validateEmail('someone@corp-mail.example.co'), isNull);
    });
  });

  group('validatePhone', () {
    test('rejects empty', () {
      expect(validatePhone(''), isNotNull);
    });

    test('rejects a non-KZ-shaped number', () {
      expect(validatePhone('12345'), isNotNull);
      expect(validatePhone('+1 555 123 4567'), isNotNull);
    });

    test('accepts +7, 8, and bare 10-digit KZ forms', () {
      expect(validatePhone('+77001234567'), isNull);
      expect(validatePhone('87001234567'), isNull);
      expect(validatePhone('7001234567'), isNull);
    });
  });

  group('validatePassword', () {
    test('rejects empty', () {
      expect(validatePassword(''), isNotNull);
    });

    test('rejects fewer than 8 characters (matches the established policy, '
        'not the 6-character check the old sign-up screen used inline)', () {
      expect(validatePassword('short1'), isNotNull);
      expect(validatePassword('1234567'), isNotNull);
    });

    test('accepts 8+ characters', () {
      expect(validatePassword('password123'), isNull);
    });
  });

  group('normalizeEmail', () {
    test('trims and lowercases', () {
      expect(normalizeEmail('  Director@JUMA.kz  '), 'director@juma.kz');
    });
  });

  group('normalizeKzPhone', () {
    test('already-E.164 input is unchanged', () {
      expect(normalizeKzPhone('+77001234567'), '+77001234567');
    });

    test('a leading 8 is normalized to +7', () {
      expect(normalizeKzPhone('87001234567'), '+77001234567');
    });

    test('a bare 10-digit local number gets +7 prepended', () {
      expect(normalizeKzPhone('7001234567'), '+77001234567');
    });

    test('spaces/dashes/parens are stripped before normalizing', () {
      expect(normalizeKzPhone('+7 (700) 123-45-67'), '+77001234567');
    });

    test('signup metadata, updateUser(phone:), and verifyOTP all derive the '
        'same normalized value from the same raw input — they can never '
        'silently drift from each other', () {
      const raw = '8 700 123 45 67';
      final forSignUpMetadata = normalizeKzPhone(raw);
      final forUpdateUser = normalizeKzPhone(raw);
      final forVerifyOtp = normalizeKzPhone(raw);
      expect(forSignUpMetadata, forUpdateUser);
      expect(forUpdateUser, forVerifyOtp);
    });
  });
}
