import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/partners/domain/partner_validation.dart';

void main() {
  group('validateDisplayName', () {
    test('rejects empty and whitespace-only input', () {
      expect(validateDisplayName(''), isNotNull);
      expect(validateDisplayName('   '), isNotNull);
    });

    test('rejects a single character', () {
      expect(validateDisplayName('Е'), isNotNull);
    });

    test('accepts a real name or company name', () {
      expect(validateDisplayName('Ерлан ЛДСП жеткізуші'), isNull);
    });
  });

  group('validatePartnerPhone', () {
    test('is optional by default — empty is valid', () {
      expect(validatePartnerPhone(''), isNull);
    });

    test('is rejected when explicitly required and empty', () {
      expect(validatePartnerPhone('', required: true), isNotNull);
    });

    test('rejects a malformed number', () {
      expect(validatePartnerPhone('123'), isNotNull);
    });

    test('accepts a well-formed KZ mobile number', () {
      expect(validatePartnerPhone('+77011234567'), isNull);
      expect(validatePartnerPhone('77011234567'), isNull);
    });
  });

  group('validateTrustRating', () {
    test('is optional — null is valid ("белгіленбеген")', () {
      expect(validateTrustRating(null), isNull);
    });

    test('rejects values outside 1-5', () {
      expect(validateTrustRating(0), isNotNull);
      expect(validateTrustRating(6), isNotNull);
    });

    test('accepts the full 1-5 range inclusive', () {
      expect(validateTrustRating(1), isNull);
      expect(validateTrustRating(5), isNull);
    });
  });
}
