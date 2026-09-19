import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/orders/domain/entities/customer_order.dart';
import 'package:juma_ui_crm/features/orders/domain/value_objects/order_status.dart';

CustomerOrder _order({required int totalAmountTiyn, required int paidTiyn}) {
  return CustomerOrder(
    id: '1',
    orderNumber: 'JU-260713-0001',
    clientId: 'c1',
    clientName: 'Асқар',
    clientPhone: '+7...',
    productType: 'Диван',
    status: OrderStatus.inProgress,
    totalAmountTiyn: totalAmountTiyn,
    paidTiyn: paidTiyn,
    createdAt: DateTime(2026, 7, 13),
  );
}

void main() {
  group('CustomerOrder.remainingTiyn', () {
    test('is total minus paid — requirement #11 ("Қалған сома автоматты '
        'есептелсін")', () {
      final order = _order(totalAmountTiyn: 140000000, paidTiyn: 42000000);
      expect(order.remainingTiyn, 98000000);
    });

    test('clamps to zero on overpayment rather than going negative', () {
      final order = _order(totalAmountTiyn: 100000, paidTiyn: 150000);
      expect(order.remainingTiyn, 0);
    });
  });

  group('CustomerOrder.paymentPercent', () {
    test('is paid / total * 100 — requirement #12 ("Төлем пайызы автоматты '
        'есептелсін")', () {
      final order = _order(totalAmountTiyn: 1000000, paidTiyn: 300000);
      expect(order.paymentPercent, 30);
    });

    test('is zero, not NaN, when total is zero', () {
      final order = _order(totalAmountTiyn: 0, paidTiyn: 0);
      expect(order.paymentPercent, 0);
    });

    test('never exceeds 100 even on overpayment', () {
      final order = _order(totalAmountTiyn: 100000, paidTiyn: 150000);
      expect(order.paymentPercent, 100);
    });
  });

  test('equality is based on id only, matching the persisted-row identity', () {
    final a = _order(totalAmountTiyn: 100, paidTiyn: 0);
    final b = CustomerOrder(
      id: '1',
      orderNumber: 'different-number',
      clientId: 'c2',
      clientName: 'Басқа',
      clientPhone: '+7...',
      productType: 'Үстел',
      status: OrderStatus.ready,
      totalAmountTiyn: 999,
      paidTiyn: 999,
      createdAt: DateTime(2020),
    );
    expect(a, equals(b));
  });
}
