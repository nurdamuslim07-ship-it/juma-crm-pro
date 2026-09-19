import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/core/router/route_paths.dart';

void main() {
  test('static Purchases routes', () {
    expect(RoutePaths.purchases, '/purchases');
    expect(RoutePaths.purchaseOrderNew, '/purchases/new');
    expect(RoutePaths.purchasesAnalytics, '/purchases/analytics');
  });

  test('purchaseOrderDetail builds an id-scoped path', () {
    expect(RoutePaths.purchaseOrderDetail('po1'), '/purchases/po1');
  });

  test('purchaseOrderEdit builds an id-scoped edit path', () {
    expect(RoutePaths.purchaseOrderEdit('po1'), '/purchases/po1/edit');
  });

  test('purchaseOrderReceive builds an id-scoped receive path', () {
    expect(RoutePaths.purchaseOrderReceive('po1'), '/purchases/po1/receive');
  });

  test('supplierPayments builds a partner-scoped path', () {
    expect(
      RoutePaths.supplierPayments('partner1'),
      '/purchases/suppliers/partner1/payments',
    );
  });
}
