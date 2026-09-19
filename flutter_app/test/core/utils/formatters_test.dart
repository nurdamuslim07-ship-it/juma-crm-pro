import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/core/utils/formatters.dart';

// NumberFormat.decimalPattern('kk') groups thousands with a non-breaking
// space (U+00A0), not a plain space — intentional (avoids an amount
// wrapping mid-number in the UI), so expectations use it explicitly.
const _nbsp = ' ';

void main() {
  group('AppFormatters.tenge', () {
    test('converts tiyn (minor units) to a ₸-suffixed major-unit string', () {
      // 1,400,000 ₸ stored as 140,000,000 tiyn — DATABASE_SCHEMA.md's
      // "never floating point" rule: this must be exact integer math,
      // not a division that could introduce rounding error.
      expect(AppFormatters.tenge(140000000), '1${_nbsp}400${_nbsp}000 ₸');
    });

    test('truncates partial tiyn toward zero rather than rounding', () {
      expect(AppFormatters.tenge(150), '1 ₸');
    });

    test('handles zero', () {
      expect(AppFormatters.tenge(0), '0 ₸');
    });
  });

  group('AppFormatters.percent', () {
    test('rounds to the nearest whole percent', () {
      expect(AppFormatters.percent(69.6), '70%');
      expect(AppFormatters.percent(30), '30%');
    });
  });

  group('AppFormatters.phone', () {
    test('formats a raw KZ mobile number progressively', () {
      expect(AppFormatters.phone('87071234567'), '+7 (707) 123-45-67');
      expect(AppFormatters.phone('+77071234567'), '+7 (707) 123-45-67');
    });
  });
}
