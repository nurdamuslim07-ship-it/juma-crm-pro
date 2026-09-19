import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/payments/domain/entities/payment.dart';
import 'package:juma_ui_crm/features/payments/domain/value_objects/payment_method.dart';

Payment _payment({String id = '1', PaymentMethod method = PaymentMethod.cash}) {
  return Payment(
    id: id,
    orderId: 'o1',
    orderNumber: 'JU-260713-0001',
    clientId: 'c1',
    clientName: 'Асқар',
    amountTiyn: 100000,
    method: method,
    paidAt: DateTime(2026, 7, 13),
    createdAt: DateTime(2026, 7, 13),
  );
}

void main() {
  test('equality is based on id only, matching the persisted-row identity', () {
    final a = _payment(id: '1', method: PaymentMethod.cash);
    final b = _payment(id: '1', method: PaymentMethod.kaspi);
    expect(a, equals(b));
  });

  test('different ids are not equal', () {
    expect(_payment(id: '1'), isNot(equals(_payment(id: '2'))));
  });
}
