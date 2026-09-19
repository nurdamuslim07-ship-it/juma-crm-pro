import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/analytics/domain/analytics_period.dart';

void main() {
  group('computePeriodRange', () {
    test('day — is just that single day, start == end', () {
      final range = computePeriodRange(
        AnalyticsPeriodType.day,
        DateTime(2026, 7, 13, 15, 30),
      );
      expect(range.start, DateTime(2026, 7, 13));
      expect(range.end, DateTime(2026, 7, 13));
    });

    test('week — Monday..Sunday containing the reference date', () {
      // 2026-07-13 is a Monday.
      final range = computePeriodRange(
        AnalyticsPeriodType.week,
        DateTime(2026, 7, 16), // Thursday of that same week
      );
      expect(range.start, DateTime(2026, 7, 13));
      expect(range.end, DateTime(2026, 7, 19));
    });

    test('month — first..last day of the reference month', () {
      final range = computePeriodRange(
        AnalyticsPeriodType.month,
        DateTime(2026, 2, 10),
      );
      expect(range.start, DateTime(2026, 2, 1));
      expect(range.end, DateTime(2026, 2, 28));
    });

    test('year — Jan 1..Dec 31 of the reference year', () {
      final range = computePeriodRange(
        AnalyticsPeriodType.year,
        DateTime(2026, 6, 1),
      );
      expect(range.start, DateTime(2026, 1, 1));
      expect(range.end, DateTime(2026, 12, 31));
    });
  });

  group('computePreviousPeriodRange', () {
    test('month — the preceding calendar month, not a rolling 30 days', () {
      final range = computePreviousPeriodRange(
        AnalyticsPeriodType.month,
        DateTime(2026, 3, 15),
      );
      expect(range.start, DateTime(2026, 2, 1));
      expect(range.end, DateTime(2026, 2, 28));
    });

    test('month — crosses a year boundary correctly (Jan -> prior Dec)', () {
      final range = computePreviousPeriodRange(
        AnalyticsPeriodType.month,
        DateTime(2026, 1, 5),
      );
      expect(range.start, DateTime(2025, 12, 1));
      expect(range.end, DateTime(2025, 12, 31));
    });

    test('year — the preceding calendar year', () {
      final range = computePreviousPeriodRange(
        AnalyticsPeriodType.year,
        DateTime(2026, 6, 1),
      );
      expect(range.start, DateTime(2025, 1, 1));
      expect(range.end, DateTime(2025, 12, 31));
    });

    test('week — the preceding 7-day week', () {
      final range = computePreviousPeriodRange(
        AnalyticsPeriodType.week,
        DateTime(2026, 7, 16),
      );
      expect(range.start, DateTime(2026, 7, 6));
      expect(range.end, DateTime(2026, 7, 12));
    });

    test('day — the preceding single day', () {
      final range = computePreviousPeriodRange(
        AnalyticsPeriodType.day,
        DateTime(2026, 7, 13),
      );
      expect(range.start, DateTime(2026, 7, 12));
      expect(range.end, DateTime(2026, 7, 12));
    });
  });

  group('shiftReferenceDate', () {
    test('month step lands in the next calendar month, not +30 days', () {
      final shifted = shiftReferenceDate(
        AnalyticsPeriodType.month,
        DateTime(2026, 1, 31),
        1,
      );
      expect(shifted.year, 2026);
      expect(shifted.month, 2);
    });

    test('negative direction moves earlier', () {
      final shifted = shiftReferenceDate(
        AnalyticsPeriodType.year,
        DateTime(2026, 6, 1),
        -1,
      );
      expect(shifted, DateTime(2025, 1, 1));
    });

    test('day step moves by exactly one day', () {
      final shifted = shiftReferenceDate(
        AnalyticsPeriodType.day,
        DateTime(2026, 7, 13),
        1,
      );
      expect(shifted, DateTime(2026, 7, 14));
    });
  });

  group('computePeriodChangePercent', () {
    test('is null when either side is unavailable (redacted section)', () {
      expect(computePeriodChangePercent(null, 100), isNull);
      expect(computePeriodChangePercent(100, null), isNull);
    });

    test('is null when previous is zero — undefined, not infinite/zero '
        '("жаңа" is shown instead, not a percentage)', () {
      expect(computePeriodChangePercent(500, 0), isNull);
      expect(computePeriodChangePercent(0, 0), isNull);
    });

    test('is a positive percentage when current > previous', () {
      expect(computePeriodChangePercent(150, 100), 50.0);
    });

    test('is a negative percentage when current < previous', () {
      expect(computePeriodChangePercent(50, 100), -50.0);
    });

    test('is zero when current == previous', () {
      expect(computePeriodChangePercent(100, 100), 0.0);
    });
  });
}
