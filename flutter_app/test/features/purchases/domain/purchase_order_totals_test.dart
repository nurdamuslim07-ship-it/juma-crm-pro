import 'package:flutter_test/flutter_test.dart';
import 'package:juma_ui_crm/features/purchases/domain/purchase_order_totals.dart';

void main() {
  group('computeItemTotalTiyn', () {
    test('rounds quantity * unit price to the nearest tiyn', () {
      expect(
        computeItemTotalTiyn(quantity: 20, unitPriceTiyn: 850000),
        17000000,
      );
    });

    test('rounds a fractional quantity correctly', () {
      expect(computeItemTotalTiyn(quantity: 2.5, unitPriceTiyn: 100), 250);
    });

    test('rounds .5 up, matching Postgres round(numeric)', () {
      expect(computeItemTotalTiyn(quantity: 1, unitPriceTiyn: 1), 1);
      expect(computeItemTotalTiyn(quantity: 0.005, unitPriceTiyn: 100), 1);
    });
  });

  group('computeSubtotalTiyn', () {
    test('sums a list of item totals', () {
      expect(computeSubtotalTiyn([17000000, 5000000, 0]), 22000000);
    });

    test('an empty list sums to zero', () {
      expect(computeSubtotalTiyn(const []), 0);
    });
  });

  group('computeOrderTotalTiyn', () {
    test('adds delivery + vat and subtracts discount from the subtotal', () {
      final total = computeOrderTotalTiyn(
        subtotalTiyn: 17000000,
        deliveryCostTiyn: 500000,
        vatTiyn: 300000,
        discountTiyn: 200000,
      );
      expect(total, 17600000);
    });

    test('matches purchase_orders_sync_total() exactly with all zeros', () {
      final total = computeOrderTotalTiyn(
        subtotalTiyn: 0,
        deliveryCostTiyn: 0,
        vatTiyn: 0,
        discountTiyn: 0,
      );
      expect(total, 0);
    });
  });
}
