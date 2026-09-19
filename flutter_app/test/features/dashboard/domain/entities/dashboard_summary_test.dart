import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/dashboard/domain/entities/dashboard_summary.dart';

DashboardSummary _summary({
  int totalContractAmountTiyn = 0,
  int paymentsReceivedTiyn = 0,
}) {
  return DashboardSummary(
    activeOrdersCount: 0,
    delayedOrdersCount: 0,
    completedThisMonthCount: 0,
    totalContractAmountTiyn: totalContractAmountTiyn,
    paymentsReceivedTiyn: paymentsReceivedTiyn,
    expensesTiyn: 0,
    lowStockMaterialsCount: 0,
    upcomingDeliveriesCount: 0,
    myOpenTasksCount: 0,
    myTodayTasksCount: 0,
  );
}

void main() {
  group('DashboardSummary.remainingDebtTiyn', () {
    test('is the difference between contract total and payments received', () {
      final summary = _summary(
        totalContractAmountTiyn: 140000000, // 1,400,000 ₸
        paymentsReceivedTiyn: 42000000, // 420,000 ₸
      );
      expect(summary.remainingDebtTiyn, 98000000);
    });

    test('clamps to zero rather than going negative on overpayment', () {
      final summary = _summary(
        totalContractAmountTiyn: 100000,
        paymentsReceivedTiyn: 150000,
      );
      expect(summary.remainingDebtTiyn, 0);
    });
  });

  group('DashboardSummary.paymentProgressPercent', () {
    test(
      'is independent of production progress — this entity has no '
      'production percent field at all, by design (see ORDER_WORKFLOW.md)',
      () {
        final summary = _summary(
          totalContractAmountTiyn: 1000000,
          paymentsReceivedTiyn: 300000,
        );
        expect(summary.paymentProgressPercent, 30);
      },
    );

    test('is zero when there is no contract amount yet, not NaN/Infinity', () {
      final summary = _summary(
        totalContractAmountTiyn: 0,
        paymentsReceivedTiyn: 0,
      );
      expect(summary.paymentProgressPercent, 0);
    });

    test('clamps at 100 on overpayment', () {
      final summary = _summary(
        totalContractAmountTiyn: 100000,
        paymentsReceivedTiyn: 150000,
      );
      expect(summary.paymentProgressPercent, 100);
    });
  });
}
