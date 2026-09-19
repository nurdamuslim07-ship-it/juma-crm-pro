/// Pure period/comparison math (requirement: "Күн, апта, ай, жыл
/// бойынша фильтр" + "Салыстыру: алдыңғы кезеңмен") — kept out of
/// widgets/providers so the date-boundary and percent-change rules are
/// directly unit-testable, same convention as
/// features/orders/domain (computeAllowedOrderStatuses) and
/// features/payments/domain (payment_rules.dart).
library;

enum AnalyticsPeriodType { day, week, month, year }

typedef DateRange = ({DateTime start, DateTime end});

/// The period containing [reference], inclusive on both ends
/// (both dates at midnight — callers compare against `date` columns,
/// which have no time component).
DateRange computePeriodRange(AnalyticsPeriodType type, DateTime reference) {
  final today = DateTime(reference.year, reference.month, reference.day);
  switch (type) {
    case AnalyticsPeriodType.day:
      return (start: today, end: today);
    case AnalyticsPeriodType.week:
      // ISO week: Monday..Sunday.
      final start = today.subtract(Duration(days: today.weekday - 1));
      return (start: start, end: start.add(const Duration(days: 6)));
    case AnalyticsPeriodType.month:
      final start = DateTime(reference.year, reference.month, 1);
      final end = DateTime(reference.year, reference.month + 1, 0);
      return (start: start, end: end);
    case AnalyticsPeriodType.year:
      return (
        start: DateTime(reference.year, 1, 1),
        end: DateTime(reference.year, 12, 31),
      );
  }
}

/// The immediately preceding period of the same length/type — e.g.
/// for [AnalyticsPeriodType.month] with [reference] in July, this is
/// all of June, not a rolling 30-day window.
DateRange computePreviousPeriodRange(
  AnalyticsPeriodType type,
  DateTime reference,
) {
  switch (type) {
    case AnalyticsPeriodType.day:
      return computePeriodRange(
        type,
        reference.subtract(const Duration(days: 1)),
      );
    case AnalyticsPeriodType.week:
      return computePeriodRange(
        type,
        reference.subtract(const Duration(days: 7)),
      );
    case AnalyticsPeriodType.month:
      return computePeriodRange(
        type,
        DateTime(reference.year, reference.month - 1, 1),
      );
    case AnalyticsPeriodType.year:
      return computePeriodRange(type, DateTime(reference.year - 1, 1, 1));
  }
}

/// Moves [reference] by one period of [type] in the given direction
/// (+1 = later, -1 = earlier) — backs the ‹ › controls on the
/// Analytics screen. Month/year steps move by calendar month/year
/// (not a fixed day count), so e.g. stepping from Jan 31 by a month
/// lands in February, not "31 days later".
DateTime shiftReferenceDate(
  AnalyticsPeriodType type,
  DateTime reference,
  int direction,
) {
  switch (type) {
    case AnalyticsPeriodType.day:
      return reference.add(Duration(days: direction));
    case AnalyticsPeriodType.week:
      return reference.add(Duration(days: 7 * direction));
    case AnalyticsPeriodType.month:
      return DateTime(reference.year, reference.month + direction, 1);
    case AnalyticsPeriodType.year:
      return DateTime(reference.year + direction, 1, 1);
  }
}

/// Percent change of [current] vs [previous] ("Салыстыру: алдыңғы
/// кезеңмен"). Returns null when either side is unknown (redacted —
/// see AnalyticsSummary's tier-nullability doc) or when [previous] is
/// zero (a percent change from zero is undefined, not infinite/zero —
/// the UI shows "жаңа" ("new") for that case instead of a number).
double? computePeriodChangePercent(int? current, int? previous) {
  if (current == null || previous == null) return null;
  if (previous == 0) return null;
  return (current - previous) / previous * 100;
}
