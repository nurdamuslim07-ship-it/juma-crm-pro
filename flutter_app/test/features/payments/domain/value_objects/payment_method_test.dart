import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/payments/domain/value_objects/payment_method.dart';

void main() {
  group('PaymentMethod.dbKey / fromDbKey', () {
    test('round-trips every method through its payment_methods.key value', () {
      for (final method in PaymentMethod.values) {
        expect(PaymentMethod.fromDbKey(method.dbKey), method);
      }
    });

    test(
      'matches the exact keys seeded in supabase/seed/seed.sql — requirement #5 '
      '(Қолма-қол/Kaspi/Банк аударымы/Карта/Басқа)',
      () {
        expect(PaymentMethod.cash.dbKey, 'cash');
        expect(PaymentMethod.kaspi.dbKey, 'kaspi');
        expect(PaymentMethod.bankTransfer.dbKey, 'bank_transfer');
        expect(PaymentMethod.card.dbKey, 'card');
        expect(PaymentMethod.other.dbKey, 'other');
      },
    );

    test('throws on an unknown key instead of silently returning null', () {
      expect(() => PaymentMethod.fromDbKey('crypto'), throwsArgumentError);
    });
  });
}
