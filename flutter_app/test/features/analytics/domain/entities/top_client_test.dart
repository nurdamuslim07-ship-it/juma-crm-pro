import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/analytics/domain/entities/top_client.dart';

void main() {
  test('equality is based on clientId only', () {
    const a = TopClient(
      clientId: 'c1',
      clientName: 'Асқар',
      ordersCount: 3,
      totalAmountTiyn: 100000000,
    );
    const b = TopClient(
      clientId: 'c1',
      clientName: 'Асқар',
      ordersCount: 99,
      totalAmountTiyn: 1,
    );
    expect(a, equals(b));
  });

  test('different clientIds are not equal', () {
    const a = TopClient(
      clientId: 'c1',
      clientName: 'Асқар',
      ordersCount: 1,
      totalAmountTiyn: 1,
    );
    const b = TopClient(
      clientId: 'c2',
      clientName: 'Асқар',
      ordersCount: 1,
      totalAmountTiyn: 1,
    );
    expect(a, isNot(equals(b)));
  });
}
