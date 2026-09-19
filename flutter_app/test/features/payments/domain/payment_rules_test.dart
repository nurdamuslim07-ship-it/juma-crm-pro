import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/payments/domain/payment_rules.dart';

void main() {
  group('wouldOverpay — requirement #12 "Артық төлемге жол бермеу"', () {
    test('is false when the new payment fits within the remaining balance', () {
      expect(
        wouldOverpay(
          orderTotalTiyn: 1000000,
          alreadyPaidTiyn: 300000,
          newAmountTiyn: 700000,
        ),
        isFalse,
      );
    });

    test('is false for a payment that exactly completes the order', () {
      expect(
        wouldOverpay(
          orderTotalTiyn: 1000000,
          alreadyPaidTiyn: 400000,
          newAmountTiyn: 600000,
        ),
        isFalse,
      );
    });

    test(
      'is true the moment the new payment pushes past the total by even 1 tiyn',
      () {
        expect(
          wouldOverpay(
            orderTotalTiyn: 1000000,
            alreadyPaidTiyn: 400000,
            newAmountTiyn: 600001,
          ),
          isTrue,
        );
      },
    );

    test('is true when the order is already fully paid', () {
      expect(
        wouldOverpay(
          orderTotalTiyn: 1000000,
          alreadyPaidTiyn: 1000000,
          newAmountTiyn: 1,
        ),
        isTrue,
      );
    });
  });

  group('maxPayableTiyn', () {
    test('is the remaining balance when positive', () {
      expect(
        maxPayableTiyn(orderTotalTiyn: 1000000, alreadyPaidTiyn: 300000),
        700000,
      );
    });

    test('is zero, never negative, once the order is fully paid', () {
      expect(
        maxPayableTiyn(orderTotalTiyn: 1000000, alreadyPaidTiyn: 1000000),
        0,
      );
    });

    test('is zero, not negative, even if somehow overpaid already', () {
      expect(
        maxPayableTiyn(orderTotalTiyn: 1000000, alreadyPaidTiyn: 1500000),
        0,
      );
    });
  });
}
