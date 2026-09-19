import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/purchases/domain/entities/purchase_analytics.dart';
import 'package:juma_ui_crm/features/purchases/presentation/providers/purchases_providers.dart';
import 'package:juma_ui_crm/features/purchases/presentation/screens/purchase_analytics_screen.dart';

/// Responsive KPI cards — a 2-column grid on phone, 4-column on
/// tablet/desktop/web (see purchase_analytics_screen.dart's
/// `GridView.count(crossAxisCount: context.isMobile ? 2 : 4, ...)`).
const _analytics = PurchaseAnalytics(
  monthlyPurchasesTiyn: 1000000,
  totalDebtTiyn: 200000,
  totalAdvanceTiyn: 50000,
  avgUnitPriceTiyn: 85000,
  topMaterials: [],
  supplierRatings: [],
);

Future<void> _pump(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        purchaseAnalyticsProvider.overrideWith(
          (ref) => Future.value(_analytics),
        ),
      ],
      child: const MaterialApp(home: PurchaseAnalyticsScreen()),
    ),
  );
}

int _crossAxisCount(WidgetTester tester) {
  final grid = tester.widget<GridView>(find.byType(GridView));
  final delegate =
      grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
  return delegate.crossAxisCount;
}

void main() {
  testWidgets('phone width uses a 2-column KPI grid', (tester) async {
    await _pump(tester, const Size(400, 900));
    await tester.pumpAndSettle();

    expect(_crossAxisCount(tester), 2);
  });

  testWidgets('desktop width uses a 4-column KPI grid', (tester) async {
    await _pump(tester, const Size(1200, 900));
    await tester.pumpAndSettle();

    expect(_crossAxisCount(tester), 4);
  });
}
