import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/analytics/domain/entities/analytics_summary.dart';

void main() {
  group('AnalyticsSummary.hasSalesAccess / hasFinancialAccess — reflect '
      'whether the RPC redacted a whole section, not whether that '
      'section simply has no data for the period', () {
    test('hasSalesAccess is false when turnoverTiyn is null (redacted '
        'for a role without analytics.read_sales)', () {
      const summary = AnalyticsSummary();
      expect(summary.hasSalesAccess, isFalse);
    });

    test('hasSalesAccess is true even when turnoverTiyn is zero — a '
        'granted section always comes back as a concrete number '
        '(coalesced to 0), never null', () {
      const summary = AnalyticsSummary(turnoverTiyn: 0);
      expect(summary.hasSalesAccess, isTrue);
    });

    test('hasFinancialAccess is false when paymentsReceivedTiyn is null', () {
      const summary = AnalyticsSummary();
      expect(summary.hasFinancialAccess, isFalse);
    });

    test('hasFinancialAccess is true even with a zero payments-received '
        'figure, as long as the section was granted', () {
      const summary = AnalyticsSummary(paymentsReceivedTiyn: 0);
      expect(summary.hasFinancialAccess, isTrue);
    });

    test('both tiers can be granted independently of each other', () {
      const salesOnly = AnalyticsSummary(turnoverTiyn: 500);
      expect(salesOnly.hasSalesAccess, isTrue);
      expect(salesOnly.hasFinancialAccess, isFalse);

      const financialOnly = AnalyticsSummary(paymentsReceivedTiyn: 500);
      expect(financialOnly.hasSalesAccess, isFalse);
      expect(financialOnly.hasFinancialAccess, isTrue);
    });
  });

  test('ordersByStatus/paymentMethodStats default to empty maps', () {
    const summary = AnalyticsSummary();
    expect(summary.ordersByStatus, isEmpty);
    expect(summary.paymentMethodStats, isEmpty);
  });
}
